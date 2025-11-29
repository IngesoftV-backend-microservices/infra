#!/bin/bash
set -euo pipefail

# Script to automatically configure SonarQube and update GitHub secret
# FIXED: Logs are now sent to stderr to avoid polluting the token variable capture

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SONAR_ADMIN_USER="${SONAR_ADMIN_USER:-admin}"
SONAR_ADMIN_PASSWORD="${SONAR_ADMIN_PASSWORD:-admin}"
SONAR_TOKEN_NAME="${SONAR_TOKEN_NAME:-github-actions-$(date +%Y%m%d-%H%M%S)}"
MAX_RETRIES=30
RETRY_DELAY=10

# GitHub configuration
GITHUB_ORG="${GITHUB_ORG:-}"
GITHUB_SECRET_NAME="${GITHUB_SECRET_NAME:-SONAR_TOKEN}"

# Function to print messages (Modified to print to stderr >&2)
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
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
        log_warn "Waiting for SonarQube LoadBalancer IP... (attempt $retry/$MAX_RETRIES)"
        sleep $RETRY_DELAY
    done

    log_error "Failed to get SonarQube LoadBalancer IP after $MAX_RETRIES attempts"
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
                log_info "SonarQube is ready!"
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

    log_info "Generating SonarQube token: $token_name"

    # First, revoke all existing github-actions tokens to avoid conflicts
    log_info "Cleaning up old tokens..."
    OLD_TOKENS=$(curl -s -u "${SONAR_ADMIN_USER}:${SONAR_ADMIN_PASSWORD}" \
        "$sonar_url/api/user_tokens/search" | jq -r '.userTokens[] | select(.name | startswith("github-actions")) | .name' 2>/dev/null || echo "")

    if [ -n "$OLD_TOKENS" ]; then
        while IFS= read -r old_token; do
            if [ -n "$old_token" ]; then
                log_info "Revoking old token: $old_token"
                curl -s -u "${SONAR_ADMIN_USER}:${SONAR_ADMIN_PASSWORD}" \
                    -X POST "$sonar_url/api/user_tokens/revoke" \
                    -d "name=$old_token" > /dev/null 2>&1 || true
            fi
        done <<< "$OLD_TOKENS"
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

    # Validate token length
    TOKEN_LENGTH=${#TOKEN}
    # SonarQube tokens are typically 40 chars
    if [ $TOKEN_LENGTH -lt 20 ] || [ $TOKEN_LENGTH -gt 60 ]; then 
        log_error "Token length invalid (${TOKEN_LENGTH} chars). Captured data: $TOKEN"
        return 1
    fi

    log_info "Token generated successfully! (Length: ${TOKEN_LENGTH} characters)"
    
    # IMPORTANTE: Esto es lo único que sale por stdout para ser capturado
    echo "$TOKEN"
    return 0
}

# Function to update GitHub secret
update_github_secret() {
    local org=$1
    local secret_name=$2
    local secret_value=$3

    log_info "Updating GitHub secret: $secret_name in organization $org"

    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) is not installed"
        return 1
    fi

    if ! gh auth status &> /dev/null; then
        log_error "GitHub CLI is not authenticated"
        return 1
    fi

    echo "$secret_value" | gh secret set "$secret_name" --org "$org" --visibility all

    if [ $? -eq 0 ]; then
        log_info "GitHub secret updated successfully!"
        return 0
    else
        log_error "Failed to update GitHub secret"
        return 1
    fi
}

# Main execution
main() {
    log_info "=== SonarQube Token Setup Automation ==="

    for tool in kubectl jq curl; do
        if ! command -v $tool &> /dev/null; then
            log_error "$tool is required but not installed"
            exit 1
        fi
    done

    if [ $# -lt 2 ]; then
        log_error "Usage: $0 <kubernetes-namespace> <github-org> [token-name]"
        exit 1
    fi

    NAMESPACE=$1
    GITHUB_ORG=$2

    if [ $# -ge 3 ]; then
        SONAR_TOKEN_NAME=$3
    fi

    log_info "Namespace: $NAMESPACE"
    log_info "GitHub Organization: $GITHUB_ORG"

    SONAR_URL=$(get_sonarqube_url "$NAMESPACE")
    if [ $? -ne 0 ]; then exit 1; fi
    log_info "SonarQube URL: $SONAR_URL"

    wait_for_sonarqube "$SONAR_URL"
    if [ $? -ne 0 ]; then exit 1; fi

    # AQUI ESTABA EL ERROR: Ahora TOKEN capturará solo el token limpio
    TOKEN=$(generate_sonar_token "$SONAR_URL" "$SONAR_TOKEN_NAME")
    if [ $? -ne 0 ]; then exit 1; fi

    update_github_secret "$GITHUB_ORG" "$GITHUB_SECRET_NAME" "$TOKEN"
    if [ $? -ne 0 ]; then
        log_warn "Manual step required. Token: $TOKEN"
        exit 1
    fi

    log_info "=== Setup completed successfully! ==="
    log_info "You can now run your CI/CD pipelines."
}

main "$@"