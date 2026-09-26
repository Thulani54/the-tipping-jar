#!/bin/bash
set -e

COMMIT=$(git rev-parse --short HEAD)
echo "Deploying backend:sha-$COMMIT"

az acr build \
  --registry tippingjarregistry2 \
  --subscription a1bd1234-3920-463f-87bc-6c5614c52b18 \
  --image "backend:sha-$COMMIT" \
  --file backend/Dockerfile \
  backend/

az webapp config container set \
  --name tippingjar-be \
  --resource-group TippingJar \
  --subscription a1bd1234-3920-463f-87bc-6c5614c52b18 \
  --container-image-name "tippingjarregistry2.azurecr.io/backend:sha-$COMMIT" \
  --container-registry-url "https://tippingjarregistry2.azurecr.io" \
  --container-registry-user "tippingjarregistry2" \
  --container-registry-password "DMYRkc4hnU5rXsMaUWVoDzCeyt95gANHl0E3S3KS82NUBJP4HqG8JQQJ99CCACrIdLPEqg7NAAACAZCRt0pU"

az webapp restart \
  --name tippingjar-be \
  --resource-group TippingJar \
  --subscription a1bd1234-3920-463f-87bc-6c5614c52b18

echo "Done — deployed backend:sha-$COMMIT"
