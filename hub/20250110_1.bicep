# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: webapp
        image: <your-acr>.azurecr.io/webapp:latest
        ports:
        - containerPort: 80
        env:
        - name: USERNAME
          valueFrom:
            secretKeyRef:
              name: webapp-secrets
              key: username
        - name: PASSWORD
          valueFrom:
            secretKeyRef:
              name: webapp-secrets
              key: password
        volumeMounts:
        - name: secrets-store
          mountPath: "/mnt/secrets-store"
          readOnly: true
      volumes:
      - name: secrets-store
        csi:
          driver: secrets-store.csi.k8s.io
          readOnly: true
          volumeAttributes:
            secretProviderClass: azure-kvname
---
# secret-provider.yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-kvname
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "true"
    userAssignedIdentityID: "<your-managed-identity-client-id>"
    keyvaultName: "<your-keyvault-name>"
    objects: |
      array:
        - |
          objectName: username
          objectType: secret
          objectVersion: ""
        - |
          objectName: password
          objectType: secret
          objectVersion: ""
    tenantId: "<your-tenant-id>"
---
# storage-classes.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: azure-disk
provisioner: disk.csi.azure.com
parameters:
  skuName: StandardSSD_LRS
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: azure-file
provisioner: file.csi.azure.com
parameters:
  skuName: Standard_LRS
---
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: webapp-service
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-internal: "true"    # Makes the load balancer internal
    service.beta.kubernetes.io/azure-load-balancer-internal-subnet: "internal-subnet"    # Specify the subnet for the internal load balancer
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
  selector:
    app: webapp


-----
FROM nginx:alpine

# Install required packages
RUN apk add --no-cache curl

# Copy the HTML template
COPY index.html /usr/share/nginx/html/
COPY update-secrets.sh /docker-entrypoint.d/

# Make the script executable
RUN chmod +x /docker-entrypoint.d/update-secrets.sh

# Copy the nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

----
<!DOCTYPE html>
<html>
<head>
    <title>Credentials Display</title>
    <script>
        function fetchCredentials() {
            fetch('/credentials')
                .then(response => response.json())
                .then(data => {
                    document.getElementById('username').value = data.username;
                    document.getElementById('password').value = data.password;
                });
        }

        // Fetch credentials every 30 seconds
        setInterval(fetchCredentials, 30000);
        
        // Initial fetch
        window.onload = fetchCredentials;
    </script>
</head>
<body>
    <h1>Credentials</h1>
    <form>
        <label for="username">Username:</label><br>
        <input type="text" id="username" readonly><br>
        <label for="password">Password:</label><br>
        <input type="text" id="password" readonly><br>
    </form>
</body>
</html>

---
#!/bin/sh

# Script to update secrets from mounted volume
while true; do
    if [ -f /mnt/secrets-store/username ] && [ -f /mnt/secrets-store/password ]; then
        USERNAME=$(cat /mnt/secrets-store/username)
        PASSWORD=$(cat /mnt/secrets-store/password)
        
        # Create JSON response file
        echo "{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\"}" > /usr/share/nginx/html/credentials.json
    fi
    sleep 30
done

---
server {
  listen 80;
  server_name localhost;

  location / {
      root /usr/share/nginx/html;
      index index.html;
  }

  location /credentials {
      alias /usr/share/nginx/html/credentials.json;
      default_type application/json;
  }
}
--- 
docker build -t <your-acr>.azurecr.io/webapp:latest .
docker push <your-acr>.azurecr.io/webapp:latest

--- 

# Grant Key Vault access to the managed identity
az keyvault set-policy --name <keyvault-name> \
    --object-id <managed-identity-object-id> \
    --secret-permissions get list
