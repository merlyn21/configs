# Infrastructure & DevOps Configs

A curated collection of infrastructure-as-code, container, and platform-engineering
examples collected from my work and personal projects. It spans cloud providers
(AWS, Yandex Cloud), container orchestration (Kubernetes, Helm, RKE), CI/CD,
and the observability/data stack that typically surrounds them.

> Values in `helm/` and `terraform/aws-infra/` (domains, account IDs, IPs,
> project names) have been replaced with fictional placeholders for public
> sharing — the structure and approach are real, the identifiers are not.

## Repository layout

### Kubernetes & Helm
| Path | Description |
|---|---|
| [`helm/`](helm/) | Production-style Helm charts with per-environment values (`dev1`, `stage`, `prod`), cron jobs, ingress, secrets, and ~20 GitHub Actions workflows for build/deploy automation. |
| [`k8s/`](k8s/) | Bare-cluster manifests and setup scripts: ingress-nginx + cert-manager, kube-prometheus-stack/Grafana, RabbitMQ, Kafka UI, OpenSearch Dashboards, pgAdmin, Yandex Cloud (`yc/`) cluster bootstrap, and a script to generate client certs for cluster users. |
| [`rke/`](rke/) | Rancher Kubernetes Engine (RKE) cluster: Ansible inventory/playbook, `cluster.yml`, ingress + NFS CSI driver, cert-manager issuer. |
| [`argocd/`](argocd/) | Sample ArgoCD `Application` manifest (the upstream `guestbook` example) for smoke-testing a freshly bootstrapped ArgoCD install. |

### Configuration Management
| Path | Description |
|---|---|
| [`ansible/`](ansible/) | Two self-contained roles — `docker-install` (Docker Engine via `get.docker.com` + log-rotation-capped `daemon.json`) and `zabbix-agent2` (Zabbix Agent 2 with PSK-encrypted transport) — plus the inventory/playbooks that drive them, and a separate `rke/` inventory for bootstrapping the RKE cluster (reboot/ping/docker-group rollout across master/worker nodes, iptables DNAT rules for the ingress VIP). |

### Infrastructure as Code
| Path | Description |
|---|---|
| [`terraform/aws-infra/`](terraform/aws-infra/) | Full AWS platform: VPC/network, EKS (with Karpenter, pgbouncer, cosign image verification), RDS, MSK (Kafka), OpenSearch, Redis, CloudFront + WAF, ACM, ECR, ECS (incl. Lambda-based exporters), Route53, S3, Datadog integration — modularized and driven by per-environment `terraform.tfvars`. |
| [`terraform/yc-k8s/`](terraform/yc-k8s/) | Minimal Yandex Cloud Managed Kubernetes cluster + ArgoCD bootstrap via Terraform. |
| [`terraform/AWS-EC2/`](terraform/AWS-EC2/) | Single EC2 instance with VPC, security group, and cloud-init user-data. |
| [`terraform/nextjs/`](terraform/nextjs/) | Static Next.js hosting on S3 + CloudFront + Lambda@Edge. |

### CI/CD
| Path | Description |
|---|---|
| [`ci/`](ci/) | GitLab CI pipeline example (`.gitlab-ci.yml`) for a .NET/Blazor app: versioning via GitVersion, NuGet packaging, merge-request gate checks, and manual deploy/hotfix jobs. |

### Container Images
| Path | Description |
|---|---|
| [`Dockerfiles/`](Dockerfiles/) | PHP-FPM (8.1/8.3) images with MySQL/PostgreSQL/Redis/RabbitMQ/cron support, Apache+PHP+MySQL+cron, Amazon Linux 2, and httpd+PHP-FPM variants. |

### Observability & Monitoring
| Path | Description |
|---|---|
| [`elk/`](elk/) | Elasticsearch + Logstash + Kibana stack with custom Logstash pipelines. |
| [`loki/`](loki/) | Grafana Loki + Promtail log aggregation, auto-provisioned as a Grafana datasource. |
| [`grafana/`](grafana/) | Standalone Grafana instance. |
| [`zabbix/`](zabbix/) | Zabbix server (Postgres-backed) bundled with Grafana (`zabbix-app` plugin) and Loki for combined metrics/logs on one dashboard. |
| [`prometheus/`](prometheus/) | Prometheus + node-exporter + blackbox-exporter (HTTP probing) + Grafana/Loki, for a host that isn't already covered by the Zabbix stack. |
| [`dozzle/`](dozzle/) | Lightweight real-time Docker log viewer. |

### AI / Automation
| Path | Description |
|---|---|
| [`AI/`](AI/) | Self-hosted [n8n](https://n8n.io/) workflow automation (Postgres-backed) alongside [Omniroute](https://github.com/diegosouzapw/omniroute) for LLM-provider routing. |

### Data Pipelines & Ops Automation
| Path | Description |
|---|---|
| [`airflow/`](airflow/) | Apache Airflow instance orchestrating ops/monitoring DAGs: multi-cloud inventory collection (AWS, Proxmox, Selectel, VMware Cloud Director), AWS/Yandex billing alerts, domain-expiry and backup-health checks, S3 cleanup, and Telegram alerting — with the underlying Python scripts organized under `scripts/`. |

### Identity, Networking & Security
| Path | Description |
|---|---|
| [`keycloak/`](keycloak/) | Keycloak IAM behind an Nginx reverse proxy. |
| [`haproxy/`](haproxy/) | HAProxy load balancer config + compose stack. |
| [`openvpn/`](openvpn/) | OpenVPN server with a self-service script to generate client certs and email them out. |
| [`socks/`](socks/) | Disposable SOCKS5 proxy container. |
| [`certbot/`](certbot/) | Let's Encrypt certificate scripts: standalone issuance/renewal/expiry-check, plus an Nginx-plugin variant for issuing certs directly against a running vhost. |
| [`vless/`](vless/) | [3x-ui](https://github.com/MHSanaei/3x-ui) panel for managing a VLESS/Xray proxy server. |

### Databases & Storage
| Path | Description |
|---|---|
| [`psql/`](psql/) | PostgreSQL + pgAdmin, plus dump/restore/DB-creation helper scripts. |
| [`mysql/`](mysql/) | MySQL container with a data-seeding script. |
| [`mssql/`](mssql/) | MS SQL Server 2019 with forced-encryption SSL/TLS setup — self-signed cert generation, compose stack, and connection-test script. |
| [`minio/`](minio/) | Self-hosted S3-compatible object storage. |

### Application Stacks & Misc
| Path | Description |
|---|---|
| [`web_apache2+php-fpm/`](web_apache2+php-fpm/) | Apache reverse-proxying to PHP-FPM, with MySQL. |
| [`gitlab/`](gitlab/) | Self-hosted GitLab instance. |
| [`sopds/`](sopds/) | Self-hosted OPDS e-book catalog server. |
| [`vmware/`](vmware/) | Python scripts pulling inventory data from vCloud Director's API into a database. |
| [`homeassistant/`](homeassistant/) | Home Assistant configuration and container setup. |
| [`tools/`](tools/) | Misc host-maintenance scripts (disk cleanup, etc.). |
| [`begin_docker.sh`](begin_docker.sh) | Installs Docker Engine on a fresh host via the official `get.docker.com` script. |

## Notes

- Most stacks are Docker Compose based; the Kubernetes/Terraform pieces are
  the more representative samples of platform-engineering work at scale.
- Configs are illustrative snapshots rather than a single deployable
  monorepo — paths and variables sometimes assume a project-specific layout
  (e.g. `ci/.gitlab-ci.yml` references a sibling `deploy/` folder not
  included here).
