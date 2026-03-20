# ToggleMaster — Fase 3

![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5-7B42BC?logo=terraform)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-CI%2FCD-2088FF?logo=githubactions&logoColor=white)
![ArgoCD](https://img.shields.io/badge/ArgoCD-GitOps-EF7B4D?logo=argo)
![AWS](https://img.shields.io/badge/AWS-EKS%20%7C%20ECR%20%7C%20RDS-FF9900?logo=amazonaws)

Plataforma de **Feature Flags** desenvolvida como Tech Challenge Fase 3 da Pós-Tech FIAP (Cloud Architecture & DevOps).

A Fase 3 adiciona ao projeto:

- **IaC com Terraform** — toda a infra AWS provisionada como código
- **CI/CD com DevSecOps** — pipelines GitHub Actions com build, lint, SAST/SCA e push para ECR
- **GitOps com ArgoCD** — deploy automatizado a partir de um repositório de manifests Kubernetes

---

## Arquitetura

```
                         ┌─────────────────────────────────────────────┐
                         │                  AWS (us-east-1)             │
                         │                                               │
  Developer ──push──▶  GitHub Actions                                   │
                    │    │  build → lint → security scan → push ECR     │
                    │    └──────────────── sed ──────────────────────▶  │
                    │                  togglemaster-gitops               │
                    │                       │                            │
                    │                    ArgoCD ◀── pull ───────────────┤
                    │                       │                            │
                    │                       ▼                            │
                    │          ┌────────────────────────────┐            │
                    │          │     EKS (tech-challenge)   │            │
                    │          │                            │            │
                    │          │  auth-service   :8001      │            │
                    │          │  flag-service   :8002      │            │
                    │          │  targeting-svc  :8003      │            │
                    │          │  evaluation-svc :8004      │            │
                    │          │  analytics-svc  :8005      │            │
                    │          └────────────┬───────────────┘            │
                    │                       │                            │
                    │         ┌─────────────┼──────────────┐            │
                    │         │             │              │             │
                    │       RDS          Redis           DynamoDB        │
                    │    (PostgreSQL)  (ElastiCache)   + SQS             │
                    │    auth/flag/     evaluation      analytics        │
                    │    targeting                                        │
                    └─────────────────────────────────────────────────┘
```

---

## Microsserviços

| Serviço | Linguagem | Banco | Porta |
|---|---|---|---|
| auth-service | Go | PostgreSQL | 8001 |
| flag-service | Python | PostgreSQL | 8002 |
| targeting-service | Python | PostgreSQL | 8003 |
| evaluation-service | Go | Redis | 8004 |
| analytics-service | Python | DynamoDB + SQS | 8005 |

---

## Estrutura do Repositório

```
tech-challenge-fase-3-fiap/
├── services/
│   ├── auth-service/          # Go — autenticação JWT
│   ├── flag-service/          # Python — CRUD de feature flags
│   ├── targeting-service/     # Python — segmentação de usuários
│   ├── evaluation-service/    # Go — avaliação de flags em tempo real
│   └── analytics-service/     # Python — ingestão de eventos
├── infra/
│   ├── backend.tf             # Remote state no S3
│   ├── main.tf                # Orquestração dos módulos
│   ├── variables.tf
│   ├── outputs.tf
│   ├── data.tf                # LabRole + caller identity
│   ├── terraform.tfvars.example
│   └── modules/
│       ├── networking/        # VPC, subnets, IGW, NAT
│       ├── eks/               # Cluster + Node Group
│       ├── rds/               # 3 instâncias PostgreSQL
│       ├── elasticache/       # Redis
│       ├── dynamodb/          # Tabela ToggleMasterAnalytics
│       ├── sqs/               # Fila togglemaster-events
│       └── ecr/               # 5 repositórios de imagens
├── .github/workflows/
│   ├── ci-reusable.yml        # Workflow reutilizável (5 jobs)
│   ├── ci-auth.yml
│   ├── ci-flag.yml
│   ├── ci-targeting.yml
│   ├── ci-evaluation.yml
│   └── ci-analytics.yml
└── docker-compose.yml         # Ambiente de desenvolvimento local

togglemaster-gitops/           # Repo GitOps separado
├── apps/
│   ├── auth-service/          # deployment + service + hpa
│   ├── flag-service/
│   ├── targeting-service/
│   ├── evaluation-service/
│   └── analytics-service/
├── base/
│   ├── namespace.yaml
│   └── ingress/ingress.yaml
└── argocd/
    ├── applications.yaml      # 6 ArgoCD Application CRs
    └── install.sh             # Script de bootstrap do ArgoCD
```

---

## Terraform — Infraestrutura como Código

### Pré-requisitos

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configurado com credenciais do AWS Academy
- Bucket S3 para armazenar o remote state

### 1. Criar o bucket de remote state

```bash
aws s3api create-bucket \
  --bucket togglemaster-terraform-state-vitor-fiap \
  --region us-east-1
```

### 2. Configurar variáveis

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
# edite terraform.tfvars e defina db_password
```

### 3. Inicializar e aplicar

```bash
terraform init
terraform plan
terraform apply
```

### 4. Configurar o kubeconfig

```bash
# O output eks_update_kubeconfig exibe o comando exato:
aws eks update-kubeconfig --region us-east-1 --name togglemaster-production
```

### Módulos Terraform

| Módulo | Recursos criados |
|---|---|
| `networking` | VPC, 2 subnets públicas, 2 privadas, IGW, NAT Gateway, route tables |
| `eks` | Cluster EKS 1.31 + Node Group (t3.medium) usando LabRole |
| `rds` | 3 instâncias PostgreSQL db.t3.micro (auth, flag, targeting) |
| `elasticache` | Redis cluster cache.t3.micro |
| `dynamodb` | Tabela `ToggleMasterAnalytics` (PAY_PER_REQUEST) |
| `sqs` | Fila `togglemaster-events` |
| `ecr` | 5 repositórios com scan_on_push e lifecycle policy (últimas 10 imagens) |

> **AWS Academy:** IAM Roles/Policies **não** são criadas via Terraform. Todos os recursos usam a `LabRole` existente, referenciada via `data "aws_iam_role" "lab_role"`.

---

## CI/CD — GitHub Actions com DevSecOps

Cada microsserviço possui um workflow caller (ex: `ci-auth.yml`) que delega para o **reusable workflow** (`ci-reusable.yml`). Os pipelines só disparam quando há alteração no path do serviço correspondente.

### Fluxo do pipeline

```
push/PR na main
      │
      ▼
┌─────────────┐   ┌──────┐   ┌───────────────┐
│ build-and   │──▶│ lint │──▶│ security-scan │
│ test        │   └──────┘   └───────┬───────┘
└─────────────┘                      │
                              (apenas push main)
                                     ▼
                          ┌──────────────────────┐
                          │  docker-build-push   │
                          │  • docker build      │
                          │  • trivy image scan  │
                          │  • push ECR          │
                          └──────────┬───────────┘
                                     │
                                     ▼
                          ┌──────────────────────┐
                          │   update-gitops      │
                          │  • checkout gitops   │
                          │  • sed IMAGE_TAG     │
                          │  • git commit+push   │
                          └──────────────────────┘
```

### Jobs do reusable workflow

| Job | Go | Python |
|---|---|---|
| `build-and-test` | `go build ./...` + `go test ./...` | `pip install -r requirements.txt` + `pytest` |
| `lint` | `golangci-lint` | `flake8` |
| `security-scan` (SCA) | Trivy filesystem scan | Trivy filesystem scan |
| `security-scan` (SAST) | `gosec` | `bandit -ll` |
| `docker-build-push` | Docker build + Trivy container scan + push ECR | idem |
| `update-gitops` | `sed` na tag do deployment.yaml + commit no repo GitOps | idem |

> O pipeline **falha com exit-code 1** se qualquer vulnerabilidade **CRITICAL** for encontrada.

### Tags de imagem

As imagens são publicadas com duas tags:

```
<ACCOUNT>.dkr.ecr.us-east-1.amazonaws.com/togglemaster/auth-service:v1.0.0-a3f9c12
<ACCOUNT>.dkr.ecr.us-east-1.amazonaws.com/togglemaster/auth-service:latest
```

---

## GitOps — ArgoCD

O ArgoCD monitora o repositório `togglemaster-gitops` e sincroniza automaticamente qualquer alteração nos manifests com o cluster EKS.

### Bootstrap do ArgoCD

```bash
cd togglemaster-gitops/argocd
./install.sh
```

O script:
1. Cria o namespace `argocd`
2. Instala o ArgoCD via manifest oficial
3. Aguarda os pods ficarem prontos
4. Aplica as 6 `Application` CRs
5. Exibe a URL, usuário e senha inicial
6. Abre port-forward para `https://localhost:8080`

### Applications configuradas

| Application | Path no GitOps | Descrição |
|---|---|---|
| `togglemaster-base` | `base/` | Namespace + Ingress |
| `auth-service` | `apps/auth-service/` | Deployment, Service, HPA |
| `flag-service` | `apps/flag-service/` | Deployment, Service, HPA |
| `targeting-service` | `apps/targeting-service/` | Deployment, Service, HPA |
| `evaluation-service` | `apps/evaluation-service/` | Deployment, Service, HPA |
| `analytics-service` | `apps/analytics-service/` | Deployment, Service, HPA |

Todas as Applications têm:

```yaml
syncPolicy:
  automated:
    prune: true      # remove recursos deletados do repo
    selfHeal: true   # reverte alterações manuais no cluster
```

### Fluxo GitOps completo

```
Developer
   │ git push (services/auth-service)
   ▼
GitHub Actions
   │ build → test → lint → security scan → docker push ECR
   │ sed IMAGE_TAG no deployment.yaml
   │ git push togglemaster-gitops
   ▼
ArgoCD (polling a cada 3 min)
   │ detecta diff no repo GitOps
   ▼
EKS — rolling update automático
```

> O CI **nunca** executa `kubectl apply` diretamente. Toda mutação no cluster passa pelo ArgoCD.

---

## Secrets necessários no GitHub

Configure em **Settings → Secrets and variables → Actions**:

| Secret | Descrição |
|---|---|
| `AWS_ACCESS_KEY_ID` | Credencial AWS Academy |
| `AWS_SECRET_ACCESS_KEY` | Credencial AWS Academy |
| `AWS_SESSION_TOKEN` | Token de sessão AWS Academy |
| `GITOPS_TOKEN` | PAT do GitHub com permissão `repo` no `togglemaster-gitops` |

---

## Desenvolvimento Local

```bash
docker compose up
```

Sobe todos os microsserviços com suas dependências (PostgreSQL, Redis) localmente.

---

## Autores

**Vitor Gabriel de Almeida, Aleff Silva**
- Pós-Tech FIAP - Arquitetura Cloud e DevOps
- Tech Challenge Fase 2

---

## Licença

Este projeto é apenas para fins educacionais como parte do programa de pós-graduação da FIAP.
