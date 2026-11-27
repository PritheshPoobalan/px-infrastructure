# px-infrastructure

Infrastructure as Code for the PritheshPoobalan platform.

This repository holds the world-class CI/CD and infrastructure foundation for all
PritheshPoobalan repositories:

- **Terraform modules** — EKS, GKE, AKS, RDS, ElastiCache, S3, CloudFront
- **Helm charts** — umbrella `px-app` chart with Prometheus, Grafana, Loki, Tempo, Pyroscope
- **ArgoCD GitOps** — app-of-apps application pointing at this repo
- **HashiCorp Vault** + ExternalSecrets Operator secret management
- **Cert-manager** + Let's Encrypt ClusterIssuer
- **Ingress-nginx** / Gateway API ingress
- **Service mesh** — Istio (default) and Linkerd (optional)
- **Monitoring stack** — kube-prometheus-stack (Prometheus + Grafana + Alertmanager),
  Loki + Promtail (logs), Tempo (traces), Pyroscope (profiling),
  Blackbox exporter (synthetic), Alertmanager (PagerDuty/Slack/Email/SMS)

## Repository structure

```
terraform/
  modules/
    k8s-eks/      # Amazon EKS
    k8s-gke/      # Google Kubernetes Engine
    k8s-aks/      # Azure Kubernetes Service
    rds/          # Amazon RDS (PostgreSQL)
    elasticache/  # Amazon ElastiCache (Redis)
    s3/           # Amazon S3
    cloudfront/   # Amazon CloudFront
  environments/
    prod/         # Production environment composition
helm/
  charts/
    app/          # px-app umbrella Helm chart
kubernetes/
  argocd/         # ArgoCD app-of-apps
  vault/          # Vault + ExternalSecrets
  cert-manager/   # Let's Encrypt ClusterIssuer
  ingress-nginx/  # Ingress classes + ingress
  service-mesh/   # Istio + Linkerd
monitoring/
  prometheus/     # kube-prometheus-stack values
  loki/           # Loki + Promtail values
  tempo/          # Tempo values
  pyroscope/      # Pyroscope values
  blackbox/       # Blackbox exporter values
  alertmanager/   # Alertmanager routes (PagerDuty/Slack/Email/SMS)
```

## Prerequisites

- Terraform >= 1.5
- helm
- kubectl
- AWS / GCP / Azure provider credentials
- Vault server (see `kubernetes/vault/server.yaml`)

## Usage

### Terraform (production)

```bash
cd terraform/environments/prod
terraform init
terraform plan -var-file=terraform.tfvars.example
terraform apply
```

### Helm (monitoring stack)

```bash
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace -f monitoring/prometheus/values.yaml

helm upgrade --install loki grafana/loki-stack -n monitoring --create-namespace \
  -f monitoring/loki/values.yaml

helm upgrade --install tempo grafana/tempo -n monitoring --create-namespace \
  -f monitoring/tempo/values.yaml
```

### ArgoCD GitOps

ArgoCD is configured via `kubernetes/argocd/app-of-apps.yaml` to sync this repo's
`kubernetes/` directory into the `px-platform` namespace.

## CI/CD

Every repository in the PritheshPoobalan GitHub org is covered by the same CI/CD
profile (`.github/workflows/`):

- `ci.yml` — lint → typecheck → test → build → security → deploy (Node 18/20/22)
- `dependabot.yml` — weekly updates, auto-merge for patch
- `release.yml` — semantic release on main
- `security-scan.yml` — daily gitleaks, trivy, semgrep, npm audit
- `nightly.yml` — full test suite, mutation testing, k6 load tests
- `performance.yml` — Lighthouse CI, k6 load tests
- `dependency-review.yml` — PR dependency review

## License

Private — PritheshPoobalan
