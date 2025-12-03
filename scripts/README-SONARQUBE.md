# Automated SonarQube Token Setup

## Script: `setup-sonarqube-token.sh`

Automatiza la generación de tokens de SonarQube para **DEV y PROD** y los configura como secrets de GitHub a nivel de organización.

## Prerequisitos

1. **Herramientas instaladas:**
   ```bash
   # Verificar instalación
   kubectl version --client
   jq --version
   curl --version
   gh --version
   ```

2. **GitHub CLI autenticado:**
   ```bash
   # Autenticar (solo primera vez)
   gh auth login

   # Verificar autenticación
   gh auth status
   ```
   **Importante:** El usuario debe tener permisos de **Owner** o **Admin** en la organización para crear secrets.

3. **Acceso a Kubernetes:**
   ```bash
   # Verificar que tienes acceso a ambos clusters
   kubectl config get-contexts

   # Deberías ver:
   # - aks-ecommerce-dev
   # - aks-ecommerce-prod

   # El script cambiará automáticamente entre clusters
   ```

4. **SonarQube corriendo:**
   - Ambas instancias (dev y prod) deben estar desplegadas y accesibles
   - LoadBalancers deben tener IPs públicas asignadas

## Uso

### Ejecución Simple (Organización por defecto)

```bash
cd infra/scripts
./setup-sonarqube-token.sh
```

Usa la organización por defecto: `IngesoftV-backend-microservices`

### Ejecución con Organización Personalizada

```bash
./setup-sonarqube-token.sh mi-organizacion
```

### Variables de Entorno Opcionales

```bash
# Credenciales de SonarQube (si cambiaste el password por defecto)
export SONAR_ADMIN_USER="admin"
export SONAR_ADMIN_PASSWORD="tu-password"

# Ejecutar script
./setup-sonarqube-token.sh
```

## ¿Qué hace el script?

1. **Valida prerequisitos:**
   - Verifica que `kubectl`, `jq`, `curl`, `gh` estén instalados
   - Verifica autenticación de GitHub CLI

2. **Procesa ambiente DEV:**
   - Cambia al contexto del cluster: `aks-ecommerce-dev`
   - Obtiene IP del LoadBalancer de SonarQube en `ecommerce-dev`
   - Espera a que SonarQube esté listo (máx. 5 minutos)
   - Revoca token existente `github-actions-dev` si existe
   - Genera nuevo token `github-actions-dev`
   - Crea/actualiza secret `SONAR_TOKEN_DEV` en GitHub org

3. **Procesa ambiente PROD:**
   - Cambia al contexto del cluster: `aks-ecommerce-prod`
   - Obtiene IP del LoadBalancer de SonarQube en `ecommerce-prod`
   - Espera a que SonarQube esté listo (máx. 5 minutos)
   - Revoca token existente `github-actions-prod` si existe
   - Genera nuevo token `github-actions-prod`
   - Crea/actualiza secret `SONAR_TOKEN_PROD` en GitHub org

4. **Verifica secrets creados:**
   - Lista los secrets de la organización para confirmar

## Salida Esperada

```
[INFO] ==========================================
[INFO] SonarQube Multi-Environment Token Setup
[INFO] ==========================================

[INFO] Using default GitHub Organization: IngesoftV-backend-microservices

[INFO] This script will:
[INFO]   1. Connect to DEV cluster (aks-ecommerce-dev)
[INFO]   2. Generate token from SonarQube in DEV (namespace: ecommerce-dev)
[INFO]   3. Create GitHub secret: SONAR_TOKEN_DEV
[INFO]   4. Connect to PROD cluster (aks-ecommerce-prod)
[INFO]   5. Generate token from SonarQube in PROD (namespace: ecommerce-prod)
[INFO]   6. Create GitHub secret: SONAR_TOKEN_PROD
[INFO]   7. Set visibility to 'all' (works for public repos)

[INFO] ================================
[INFO] Processing DEV environment
[INFO] ================================
[INFO] Switching to cluster context: aks-ecommerce-dev
[INFO] SonarQube URL: http://4.156.60.177:9000
[SUCCESS] SonarQube is ready!
[INFO] Generating SonarQube token: github-actions-dev at http://4.156.60.177:9000
[SUCCESS] Token generated successfully! (Length: 40 characters)
[INFO] Updating GitHub organization secret: SONAR_TOKEN_DEV
[SUCCESS] GitHub secret 'SONAR_TOKEN_DEV' updated successfully!
[SUCCESS] DEV environment configured successfully!

[INFO] ================================
[INFO] Processing PROD environment
[INFO] ================================
[INFO] Switching to cluster context: aks-ecommerce-prod
[INFO] SonarQube URL: http://68.220.213.215:9000
[SUCCESS] SonarQube is ready!
[INFO] Generating SonarQube token: github-actions-prod at http://68.220.213.215:9000
[SUCCESS] Token generated successfully! (Length: 40 characters)
[INFO] Updating GitHub organization secret: SONAR_TOKEN_PROD
[SUCCESS] GitHub secret 'SONAR_TOKEN_PROD' updated successfully!
[SUCCESS] PROD environment configured successfully!

[SUCCESS] ==========================================
[SUCCESS] All environments configured successfully!
[SUCCESS] ==========================================

[INFO] GitHub organization secrets created:
[INFO]   ✓ SONAR_TOKEN_DEV  (for develop branch / dev environment)
[INFO]   ✓ SONAR_TOKEN_PROD (for main branch / prod environment)

[INFO] You can now run your CI/CD pipelines!

[INFO] Verifying secrets in GitHub...
SONAR_TOKEN_DEV    Updated 2025-12-01
SONAR_TOKEN_PROD   Updated 2025-12-01
```

## Troubleshooting

### Error: "kubectl: command not found"
```bash
# Instalar kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

### Error: "jq: command not found"
```bash
# Ubuntu/Debian
sudo apt-get install jq

# macOS
brew install jq
```

### Error: "gh: command not found"
```bash
# Ubuntu/Debian
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh

# macOS
brew install gh
```

### Error: "GitHub CLI is not authenticated"
```bash
# Autenticar con GitHub
gh auth login

# Seleccionar:
# - GitHub.com
# - HTTPS
# - Login with a web browser (o paste an authentication token)
```

### Error: "Failed to get SonarQube LoadBalancer IP"
```bash
# Verificar que SonarQube esté desplegado
kubectl get svc sonarqube -n ecommerce-dev
kubectl get svc sonarqube -n ecommerce-prod

# Verificar que el LoadBalancer tenga IP externa
kubectl get svc sonarqube -n ecommerce-dev -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Si está <pending>, esperar unos minutos o verificar cuotas de Azure
```

### Error: "Not authorized" al generar token
```bash
# Verificar credenciales de SonarQube
export SONAR_ADMIN_PASSWORD="tu-password-correcto"
./setup-sonarqube-token.sh

# O acceder manualmente a SonarQube para verificar password
# http://<SONAR_IP>:9000
```

### Error: "HTTP 403: Resource not accessible by personal access token"
```bash
# Tu token de GitHub necesita el scope 'admin:org'
gh auth refresh -s admin:org

# O crear un nuevo PAT con permisos:
# - admin:org (para crear secrets a nivel org)
```

### Error: Token generado pero no se actualiza el secret
```bash
# Verificar permisos en la organización
# Debes ser Owner o tener rol de Admin

# Verificar en: https://github.com/organizations/IngesoftV-backend-microservices/settings/member_privileges
```

## Regenerar Tokens

Si necesitas regenerar los tokens (ej: compromiso de seguridad):

```bash
# Simplemente ejecuta el script de nuevo
./setup-sonarqube-token.sh

# El script automáticamente:
# 1. Revoca los tokens viejos en SonarQube
# 2. Genera tokens nuevos
# 3. Actualiza los secrets en GitHub
```

## Verificar Tokens en GitHub

```bash
# Listar secrets de la organización
gh secret list --org IngesoftV-backend-microservices

# Ver detalles de un secret específico
gh secret list --org IngesoftV-backend-microservices | grep SONAR_TOKEN
```

## Próximos Pasos

Una vez ejecutado el script exitosamente:

1. ✅ Los secrets están configurados en GitHub
2. 🚀 Puedes hacer push a `develop` o `main`
3. 🔍 Los pipelines usarán automáticamente el token correcto según el ambiente
4. 📊 SonarQube analizará el código sin errores de autenticación

## Seguridad

- Los tokens nunca se muestran en logs (solo su longitud)
- Los tokens viejos se revocan automáticamente al regenerar
- Los secrets en GitHub están cifrados
- Visibilidad "all" permite que funcionen en repos públicos
- Los tokens son específicos por ambiente (aislamiento)
