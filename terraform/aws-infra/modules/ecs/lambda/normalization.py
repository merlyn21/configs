"""AWS Lambda handler — follows Delta-Exporter lambda_function.py pattern exactly.

Event flow:
  SQS message -> parse S3 event -> Redis dedup -> ECS Fargate launch
"""
import json
import logging
import os
from typing import Any

import boto3
import redis

ecs = boto3.client("ecs", region_name=os.environ.get("AWS_DEFAULT_REGION", "us-east-1"))

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger()


def get_secrets(secret_name: str) -> dict:
    """Retrieve and parse a Secrets Manager secret. Raises on failure."""
    secrets_client = boto3.client("secretsmanager")
    try:
        response = secrets_client.get_secret_value(SecretId=secret_name)
        return json.loads(response["SecretString"])
    except secrets_client.exceptions.ResourceNotFoundException:
        logger.error(f"Configuration not found for secret: {secret_name}")
        raise Exception("Configuration not found.") from None
    except Exception as exc:
        logger.error(f"Error getting secret {secret_name}: {exc}")
        raise


def set_env_vars(overrides: dict, env_vars: dict[str, str]) -> None:
    """Inject/update env vars into an ECS container overrides dict (in-place)."""
    env_list = overrides["containerOverrides"][0]["environment"]
    env_dict = {env["name"]: env for env in env_list}
    for k, v in env_vars.items():
        if k in env_dict:
            env_dict[k]["value"] = v
        else:
            env_list.append({"name": k, "value": v})


def detect_data_type(key: str) -> str:
    """Detect data_type from S3 object key — duplicated here for Lambda deployment isolation.

    Priority order — more specific patterns checked first to avoid prefix collisions.
    """
    key_lower = key.lower()

    if "oem_rv_type_products_data" in key_lower:
        return "oem_rv_type_products_data"
    if "oem_rv_type_vin_data" in key_lower:
        return "oem_rv_type_vin_data"
    if "oem_rv_type_data" in key_lower:
        return "oem_rv_type_data"
    if "oem" in key_lower or "rv_type" in key_lower:
        return "oem_rv_type_data"

    if "mapping_company_price" in key_lower:
        return "mapping_company_prices"
    if "company_price" in key_lower:
        return "company_prices"

    if "org_distributor_preferences" in key_lower:
        return "org_distributor_preferences"
    if "distributor_preferences" in key_lower:
        return "distributor_preferences"

    if "company_administrators" in key_lower:
        return "company_administrators"
    if "company_markups_data" in key_lower:
        return "company_markups_data"
    if "companies" in key_lower:
        return "companies"

    if "superseding_parts" in key_lower:
        return "superseding_parts"
    if "user_part_notes" in key_lower:
        return "user_part_notes"
    if "users" in key_lower:
        return "users"

    if "subscriptions" in key_lower:
        return "subscriptions"
    if "manufacturers" in key_lower:
        return "manufacturers"
    if "documents" in key_lower:
        return "documents"

    if "inventory" in key_lower:
        return "inventory"
    if "products" in key_lower:
        return "products"
    if "offers" in key_lower or "distributors" in key_lower:
        return "offers"

    raise ValueError(f"Cannot detect data_type from key: {key}")


def trigger_fargate_task(
    config: dict,
    cluster: str,
    subnets: list[str],
    security_groups: list[str],
) -> None:
    """Launch an ECS Fargate task. Raises on failure."""
    try:
        response = ecs.run_task(
            cluster=cluster,
            taskDefinition=config["task_definition_arn"],
            launchType="FARGATE",
            networkConfiguration={
                "awsvpcConfiguration": {
                    "subnets": subnets,
                    "securityGroups": security_groups,
                    "assignPublicIp": "DISABLED",
                }
            },
            overrides=config["overrides"],
        )
        if response.get("failures"):
            logger.error(f"Task failed to start: {response['failures']}")
            raise Exception(f"Failed to start task: {response['failures']}")
        task_arn = response["tasks"][0]["taskArn"]
        logger.info(f"Successfully started task: {task_arn}")
    except Exception as exc:
        logger.error(f"Error triggering Fargate task: {exc}")
        raise


def lambda_handler(event: dict, context: Any) -> None:
    """SQS event handler — parse S3 events, dedup via Redis, launch Fargate."""
    try:
        logger.info(f"Received event: {json.dumps(event)}")
        environment = os.getenv("ENVIRONMENT")

        secret_name = f"acmeparts/{environment}/exporter-overrides/exporter-normalization"
        normalization_cfg = get_secrets(secret_name)
        redis_cfg = get_secrets("acmeparts-redis")

        cluster = os.getenv("ECS_CLUSTER")
        subnets = os.getenv("ECS_SUBNETS", "").split(",")
        security_groups = os.getenv("ECS_SECURITY_GROUPS", "").split(",")
        ttl = int(os.getenv("REDIS_TTL", "86400"))

        r = redis.Redis(
            host=redis_cfg["host"],
            port=redis_cfg.get('port', 6379),
            username=redis_cfg["username"],
            password=redis_cfg["password"],
            ssl=True,
            socket_connect_timeout=30,
            socket_timeout=30,
        )

        for sqs_record in event["Records"]:
            try:
                s3_event_body = json.loads(sqs_record["body"])
                for s3_record in s3_event_body.get("Records", []):
                    bucket = s3_record["s3"]["bucket"]["name"]
                    key = s3_record["s3"]["object"]["key"]
                    etag = s3_record["s3"]["object"]["eTag"]

                    data_type = detect_data_type(key)
                    dedup_key = f"normalization-exporter:processed:{bucket}:{key}:{etag}"

                    if r.set(dedup_key, "1", nx=True, ex=ttl):
                        logger.info(f"New file detected: {key}. Triggering Fargate.")
                        set_env_vars(
                            normalization_cfg["overrides"],
                            {
                                "S3_SOURCE_BUCKET": bucket,
                                "FILE_PATH": key,
                                "DATA_TYPE": data_type,
                            },
                        )
                        trigger_fargate_task(normalization_cfg, cluster, subnets, security_groups)
                    else:
                        logger.info(f"Duplicate skipped: {key}")
            except Exception as exc:
                logger.error(f"Error processing SQS record: {exc}")

    except Exception as exc:
        logger.error(f"Lambda handler error: {exc}")
        raise