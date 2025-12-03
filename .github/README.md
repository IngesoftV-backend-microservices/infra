# Infrastructure CI/CD Pipeline

## Overview

This pipeline automates the complete deployment of Azure infrastructure (AKS, ACR, VNet) and all microservices to both dev and prod environments.

## Triggers

- **develop branch** - Automatically deploys to dev environment
- **main branch** - Deploys to prod environment (requires manual approval)
- **workflow_dispatch** - Manual trigger with environment selection

## Pipeline Stages

1. **Validate Terraform** - Executes format check and configuration validation
2. **Setup Backend** - Creates Azure Storage Account for Terraform state (idempotent)
3. **Deploy Infrastructure** - Applies Terraform configuration (AKS, ACR, VNet)
4. **Build & Push Images** - Clones all microservice repos, builds Docker images and pushes to ACR
5. **Deploy to AKS** - Clones manifests-k8s repo, applies Kubernetes manifests and performs health checks
6. **Setup SonarQube Tokens** - Generates tokens and updates GitHub Secrets
7. **Verify Deployment** - Validates final state and generates report
8. **Notify** - Sends Slack notification with deployment status

## Prerequisites

### GitHub Organization Secrets
- `AZURE_CLIENT_ID` - Service principal client ID for OIDC authentication
- `AZURE_TENANT_ID` - Azure tenant identifier
- `AZURE_SUBSCRIPTION_ID` - Target subscription identifier
- `GH_PAT` - GitHub Personal Access Token for updating SonarQube secrets
- `SLACK_WEBHOOK_URL` - Slack webhook URL (optional)

### GitHub Environments
The following environments must be configured in Settings > Environments:
- **dev** - No protection rules
- **prod** - Required reviewers enabled

### Azure Resources
The pipeline expects the following Azure resources (created automatically):
- Service Principal configured for OIDC authentication
- Federated Credentials (configured via `federate_all.sh`)

### Required Repositories
The pipeline clones the following repositories during execution:
- **manifests-k8s** - Kubernetes manifests and Kustomize configurations
- **10 microservices** - cloud-config, service-discovery, api-gateway, order-service, payment-service, product-service, shipping-service, user-service, favourite-service, proxy-client

All repositories must be accessible with the provided GH_PAT token.

## Manual Deployment

The pipeline can be triggered manually through GitHub Actions UI:
1. Navigate to Actions tab
2. Select "Infrastructure Deployment" workflow
3. Click "Run workflow"
4. Select target environment

## Pipeline Outputs

Each deployment produces:
- Deployment report artifact with complete status information
- Configured AKS credentials for kubectl access
- Updated SonarQube tokens in GitHub organization secrets
- Slack notification with deployment results

## Environment Configuration

| Aspect | Dev | Prod |
|---------|-----|------|
| Azure Region | East US | East US 2 |
| VNet CIDR | 10.0.0.0/16 | 10.1.0.0/16 |
| Node Pool | 2x Standard_B2ms | 2x Standard_B2ms |
| Pod Replicas | 1 | 2 |
| Manual Approval | No | Yes |
| Deployment Timeout | 5 minutes | 10 minutes |

## Post-Deployment Verification

```bash
# View deployment status
kubectl get all -n ecommerce-{dev|prod}

# Access services via port-forward
kubectl port-forward -n ecommerce-dev svc/service-discovery 8761:8761
kubectl port-forward -n ecommerce-dev svc/api-gateway 8080:8080
kubectl port-forward -n ecommerce-dev svc/sonarqube 9000:9000
kubectl port-forward -n ecommerce-dev svc/zipkin 9411:9411
```

## Troubleshooting

### Setup Backend Failure
- Verify Azure CLI authentication is valid
- The backend setup is idempotent and can be retried safely

### Infrastructure Deployment Failure
- Check Azure subscription quotas for Standard_B2ms VMs
- Verify terraform.tfvars contains correct vm_size specification
- Review Terraform state in Azure Storage Account

### SonarQube Token Setup Failure
- Verify SonarQube pod is running: `kubectl get pods -n ecommerce-{env} -l app=sonarqube`
- Confirm GH_PAT has organization secrets write permissions
- The pipeline automatically changes SonarQube password from admin/admin to admin/pass
- Verify LoadBalancer IP has been assigned to SonarQube service

### Services Not Ready
- Allow additional time for SonarQube initialization (approximately 5 minutes)
- Review pod logs: `kubectl logs -f deployment/{service} -n ecommerce-{env}`
- Check cluster events: `kubectl get events -n ecommerce-{env} --sort-by='.lastTimestamp'`
- Verify image pull from ACR is successful

## Technical Notes

- **Idempotency**: The pipeline can be executed multiple times without adverse effects
- **State Management**: Terraform uses remote backend stored in Azure Storage Account
- **Cost Estimation**: Approximately $100-150 per month per environment (2x Standard_B2ms nodes)
- **Token Rotation**: SonarQube tokens are regenerated automatically on each deployment
- **Federated Credentials**: Pre-configured and do not require recreation on each run
- **OIDC Authentication**: Uses workload identity federation, no client secrets stored
- **SonarQube Password**: Automatically changed from default (admin/admin) to admin/pass on first deployment
