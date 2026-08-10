import json
import logging
import os

import boto3
import redis

ecs = boto3.client('ecs')

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger()


def get_secrets(secret_name):
    secrets_client = boto3.client('secretsmanager')
    try:
        response = secrets_client.get_secret_value(SecretId=secret_name)
        config = json.loads(response['SecretString'])
        return config
    except secrets_client.exceptions.ResourceNotFoundException:
        logger.error(f"Configuration not found for secret: {secret_name}")
        raise Exception("Configuration not found.") from None
    except Exception as e:
        logger.error(f"Error getting secret {secret_name}: {e}")
        raise

def set_env_vars(overrides, env_vars):
    env_list = overrides['containerOverrides'][0]['environment']
    env_dict = {env['name']: env for env in env_list}
    for k, v in env_vars.items():
        if k in env_dict:
            env_dict[k]['value'] = v
        else:
            env_list.append({'name': k, 'value': v})


def lambda_handler(event, context):
    try:
        logger.info(f"Received event: {json.dumps(event)}")
        environment = os.getenv('ENVIRONMENT')
        secret_name_delta = f"acmeparts/{environment}/exporter-overrides/exporter-delta"
        delta_cfg = get_secrets(secret_name_delta)

        secret_name_redis = 'acmeparts-redis'
        redis_cfg = get_secrets(secret_name_redis)

        cluster = os.getenv('ECS_CLUSTER')
        subnets = os.getenv('ECS_SUBNETS').split(',')
        security_groups = os.getenv('ECS_SECURITY_GROUPS').split(',')
        ttl = int(os.getenv('REDIS_TTL', '86400'))

        r = redis.Redis(
            host=redis_cfg['host'],
            port=redis_cfg.get('port', 6379),
            username=redis_cfg['username'],
            password=redis_cfg['password'],
            ssl=True,
            socket_connect_timeout=30,
            socket_timeout=30
        )

        for sqs_record in event['Records']:
            try:
                s3_event_body = json.loads(sqs_record['body'])
                for s3_record in s3_event_body.get('Records', []):
                    bucket = s3_record['s3']['bucket']['name']
                    key = s3_record['s3']['object']['key']
                    etag = s3_record['s3']['object']['eTag']

                    dedup_key = f"delta-exporter:processed:{bucket}:{key}:{etag}"

                    if r.set(dedup_key, "1", nx=True, ex=ttl):
                        logger.info(f"New file detected: {key}. Triggering Fargate.")
                        set_env_vars(delta_cfg['overrides'], {'S3_SOURCE_BUCKET': bucket, 'FILE_PATH': key})
                        trigger_fargate_task(delta_cfg, cluster, subnets, security_groups)
                    else:
                        logger.info(f"Duplicate skipped: {key}")
            except Exception as e:
                logger.error(f"Error processing SQS record: {e}")
    except Exception as e:
        logger.error(f"Lambda handler error: {e}")
        raise

def trigger_fargate_task(config, cluster, subnets, security_groups):
    try:
        response = ecs.run_task(
            cluster=cluster,
            taskDefinition=config['task_definition_arn'],
            launchType='FARGATE',
            networkConfiguration={
                'awsvpcConfiguration': {
                    'subnets': subnets,
                    'securityGroups': security_groups,
                    'assignPublicIp': 'DISABLED'
                }
            },
            overrides=config['overrides']
        )

        if response.get('failures'):
            logger.error(f"Task failed to start: {response['failures']}")
            raise Exception(f"Failed to start task: {response['failures']}")

        task_arn = response['tasks'][0]['taskArn']
        logger.info(f"✓ Successfully started task: {task_arn}")
    except Exception as e:
        logger.error(f"Error triggering Fargate task: {e}")
        raise