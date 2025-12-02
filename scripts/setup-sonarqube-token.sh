#!/bin/bash
set -euo pipefail

# Script to automatically configure SonarQube tokens for DEV and PROD environments
# and update GitHub organization secrets

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SONAR_ADMIN_USER="${SONAR_ADMIN_USER:-admin}"
SONAR_ADMIN_PASSWORD="${SONAR_ADMIN_PASSWORD:-pass}"
MAX_RETRIES=30
RETRY_DELAY=10

# GitHub configuration
GITHUB_ORG="${GITHUB_ORG:-IngesoftV-backend-microservices}"

# Function to print messages (to stderr to avoid polluting token capture)
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_success() {
    echo -e "${BLUE}[SUCCESS]${NC} $1" >&2
}

# Function to get SonarQube service IP
get_sonarqube_url() {
    local namespace=$1
    local retry=0

    while [ $retry -lt $MAX_RETRIES ]; do
        SONAR_IP=$(kubectl get svc sonarqube -n "$namespace" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")

        if [ -n "$SONAR_IP" ]; then
            echo "http://${SONAR_IP}:9000"
            return 0
        fi

        retry=$((retry + 1))
        log_warn "Waiting for SonarQube LoadBalancer IP in $namespace... (attempt $retry/$MAX_RETRIES)"
        sleep $RETRY_DELAY
    done

    log_error "Failed to get SonarQube LoadBalancer IP from $namespace after $MAX_RETRIES attempts"
    return 1
}

# Function to wait for SonarQube to be ready
wait_for_sonarqube() {
    local sonar_url=$1
    local retry=0

    log_info "Waiting for SonarQube to be ready at $sonar_url..."

    while [ $retry -lt $MAX_RETRIES ]; do
        STATUS_CODE=$(curl -s -o /dev/null -w '%{http_code}' "$sonar_url/api/system/status" || echo "000")

        if [ "$STATUS_CODE" == "200" ]; then
            # Check if SonarQube is actually UP
            STATUS=$(curl -s "$sonar_url/api/system/status" | jq -r '.status' 2>/dev/null || echo "DOWN")
            if [ "$STATUS" == "UP" ]; then
                log_success "SonarQube is ready!"
                return 0
            fi
        fi

        retry=$((retry + 1))
        log_warn "SonarQube not ready yet (attempt $retry/$MAX_RETRIES)..."
        sleep $RETRY_DELAY
    done

    log_error "SonarQube did not become ready after $MAX_RETRIES attempts"
    return 1
}

# Function to generate SonarQube token
generate_sonar_token() {
    local sonar_url=$1
    local token_name=$2

    log_info "Generating SonarQube token: $token_name at $sonar_url"

    # First, revoke existing token with same name to avoid conflicts
    log_info "Cleaning up old token with same name if exists..."
    OLD_TOKEN=$(curl -s -u "${SONAR_ADMIN_USER}:${SONAR_ADMIN_PASSWORD}" \
        "$sonar_url/api/user_tokens/search" | jq -r ".userTokens[] | select(.name == \"$token_name\") | .name" 2>/dev/null || echo "")

    if [ -n "$OLD_TOKEN" ]; then
        log_info "Revoking old token: $OLD_TOKEN"
        curl -s -u "${SONAR_ADMIN_USER}:${SONAR_ADMIN_PASSWORD}" \
            -X POST "$sonar_url/api/user_tokens/revoke" \
            -d "name=$OLD_TOKEN" > /dev/null 2>&1 || true
    fi

    # Generate new token
    RESPONSE=$(curl -s -u "${SONAR_ADMIN_USER}:${SONAR_ADMIN_PASSWORD}" \
        -X POST "$sonar_url/api/user_tokens/generate" \
        -d "name=$token_name" || echo "")

    if [ -z "$RESPONSE" ]; then
        log_error "Failed to generate token: Empty response"
        return 1
    fi

    # Extract token from response
    TOKEN=$(echo "$RESPONSE" | jq -r '.token' 2>/dev/null || echo "")

    if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
        log_error "Failed to extract token from response"
        log_error "Response: $RESPONSE"
        return 1
    fi

    # Validate token length (SonarQube tokens are typically 40 chars)
    TOKEN_LENGTH=${#TOKEN}
    if [ $TOKEN_LENGTH -lt 20 ] || [ $TOKEN_LENGTH -gt 60 ]; then
        log_error "Token length invalid (${TOKEN_LENGTH} chars). Captured data: $TOKEN"
        return 1
    fi

    log_success "Token generated successfully! (Length: ${TOKEN_LENGTH} characters)"

    # Output only the token to stdout (to be captured)
    echo "$TOKEN"
    return 0
}

# Function to update GitHub organization secret
update_github_secret() {
    local org=$1
    local secret_name=$2
    local secret_value=$3

    log_info "Updating GitHub organization secret: $secret_name"

    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) is not installed"
        log_error "Install: https://cli.github.com/"
        return 1
    fi

    if ! gh auth status &> /dev/null; then
        log_error "GitHub CLI is not authenticated"
        log_error "Run: gh auth login"
        return 1
    fi

    # Set secret with visibility 'all' for public repos
    echo "$secret_value" | gh secret set "$secret_name" --org "$org" --visibility all

    if [ $? -eq 0 ]; then
        log_success "GitHub secret '$secret_name' updated successfully!"
        return 0
    else
        log_error "Failed to update GitHub secret '$secret_name'"
        return 1
    fi
}

# Function to process one environment
process_environment() {
    local env_name=$1
    local cluster_context=$2
    local namespace=$3
    local secret_name=$4
    local token_name=$5

    log_info "================================"
    log_info "Processing $env_name environment"
    log_info "================================"

    # Switch to the correct cluster context
    log_info "Switching to cluster context: $cluster_context"
    kubectl config use-context "$cluster_context" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        log_error "Failed to switch to context: $cluster_context"
        log_error "Available contexts:"
        kubectl config get-contexts -o name >&2
        return 1
    fi

    # Get SonarQube URL
    SONAR_URL=$(get_sonarqube_url "$namespace")
    if [ $? -ne 0 ]; then
        log_error "Failed to get SonarQube URL for $env_name"
        return 1
    fi
    log_info "SonarQube URL: $SONAR_URL"

    # Wait for SonarQube to be ready
    wait_for_sonarqube "$SONAR_URL"
    if [ $? -ne 0 ]; then
        log_error "SonarQube not ready for $env_name"
        return 1
    fi

    # Generate token
    TOKEN=$(generate_sonar_token "$SONAR_URL" "$token_name")
    if [ $? -ne 0 ]; then
        log_error "Failed to generate token for $env_name"
        return 1
    fi

    # Update GitHub secret
    update_github_secret "$GITHUB_ORG" "$secret_name" "$TOKEN"
    if [ $? -ne 0 ]; then
        log_warn "Failed to update GitHub secret for $env_name"
        log_warn "Manual step required. Token for $env_name: $TOKEN"
        return 1
    fi

    log_success "$env_name environment configured successfully!"
    return 0
}

# Main execution
main() {
    echo ""
    log_info "=========================================="
    log_info "SonarQube Multi-Environment Token Setup"
    log_info "=========================================="
    echo ""

    # Check required tools
    for tool in kubectl jq curl gh; do
        if ! command -v $tool &> /dev/null; then
            log_error "$tool is required but not installed"
            exit 1
        fi
    done

    # Check GitHub CLI authentication
    if ! gh auth status &> /dev/null; then
        log_error "GitHub CLI is not authenticated"
        log_error "Please run: gh auth login"
        exit 1
    fi

    # Override GitHub org if provided as argument
    if [ $# -ge 1 ]; then
        GITHUB_ORG=$1
        log_info "Using GitHub Organization: $GITHUB_ORG"
    else
        log_info "Using default GitHub Organization: $GITHUB_ORG"
    fi

    echo ""
    log_info "This script will:"
    log_info "  1. Connect to DEV cluster (aks-ecommerce-dev)"
    log_info "  2. Generate token from SonarQube in DEV (namespace: ecommerce-dev)"
    log_info "  3. Create GitHub secret: SONAR_TOKEN_DEV"
    log_info "  4. Connect to PROD cluster (aks-ecommerce-prod)"
    log_info "  5. Generate token from SonarQube in PROD (namespace: ecommerce-prod)"
    log_info "  6. Create GitHub secret: SONAR_TOKEN_PROD"
    log_info "  7. Set visibility to 'all' (works for public repos)"
    echo ""

    # Process DEV environment
    if ! process_environment "DEV" "aks-ecommerce-dev" "ecommerce-dev" "SONAR_TOKEN_DEV" "github-actions-dev"; then
        log_error "Failed to process DEV environment"
        exit 1
    fi

    echo ""

    # Process PROD environment
    if ! process_environment "PROD" "aks-ecommerce-prod" "ecommerce-prod" "SONAR_TOKEN_PROD" "github-actions-prod"; then
        log_error "Failed to process PROD environment"
        exit 1
    fi

    echo ""
    log_success "=========================================="
    log_success "All environments configured successfully!"
    log_success "=========================================="
    echo ""
    log_info "GitHub organization secrets created:"
    log_info "  ✓ SONAR_TOKEN_DEV  (for develop branch / dev environment)"
    log_info "  ✓ SONAR_TOKEN_PROD (for main branch / prod environment)"
    echo ""
    log_info "You can now run your CI/CD pipelines!"
    echo ""

    # Verify secrets were created
    log_info "Verifying secrets in GitHub..."
    gh secret list --org "$GITHUB_ORG" | grep "SONAR_TOKEN" || true
}

main "$@"
