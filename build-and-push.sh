#!/usr/bin/env bash
set -euo pipefail

AWS_ACCOUNT_ID="997920956342"
AWS_REGION="us-east-1"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
SERVICES=("auth" "flag" "evaluation" "targeting" "analytics")

echo "==> Login no ECR..."
aws ecr get-login-password --region "${AWS_REGION}" \
  | docker login --username AWS --password-stdin "${ECR_REGISTRY}"

for svc in "${SERVICES[@]}"; do
  SERVICE_DIR="services/${svc}-service"
  IMAGE_NAME="togglemaster/${svc}-service"
  IMAGE_URI="${ECR_REGISTRY}/${IMAGE_NAME}:latest"

  echo ""
  echo "==> [${svc}] Build da imagem..."
  docker build -t "${IMAGE_URI}" "${SERVICE_DIR}"

  echo "==> [${svc}] Push pro ECR..."
  docker push "${IMAGE_URI}"

  echo "==> [${svc}] OK!"
done

echo ""
echo "==> Todas as imagens foram enviadas pro ECR com sucesso!"
