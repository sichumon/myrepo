# Create Resource Group
az group create -l westus -n 1-0f144bc1-playground-sandbox

# Deploy template with in-line parameters
az deployment group create -g 1-0f144bc1-playground-sandbox  --template-uri https://github.com/Azure/AKS-Construction/releases/download/0.10.7/main.json --parameters \
	resourceName=az-k8s-pvt \
	upgradeChannel=stable \
	AksPaidSkuForSLA=true \
	SystemPoolType=Standard \
	agentCountMax=20 \
	custom_vnet=true \
	bastion=true \
	enable_aad=true \
	AksDisableLocalAccounts=true \
	enableAzureRBAC=true \
	adminPrincipalId=$(az ad signed-in-user show --query id --out tsv) \
	registries_sku=Premium \
	acrPushRolePrincipalId=$(az ad signed-in-user show --query id --out tsv) \
	enableACRTrustPolicy=true \
	azureFirewalls=true \
	privateLinks=true \
	keyVaultIPAllowlist="[\"144.178.252.146/32\"]" \
	enableTelemetry=false \
	omsagent=true \
	retentionInDays=30 \
	networkPolicy=azure \
	azurepolicy=deny \
	availabilityZones="[\"1\",\"2\",\"3\"]" \
	enablePrivateCluster=true \
	ingressApplicationGateway=true \
	appGWcount=0 \
	appGWsku=WAF_v2 \
	appGWmaxCount=10 \
	appgwKVIntegration=true \
	aksOutboundTrafficType=userDefinedRouting \
	keyVaultAksCSI=true \
	keyVaultCreate=true \
	keyVaultOfficerRolePrincipalId=$(az ad signed-in-user show --query id --out tsv) \
	daprAddon=true \
	daprAddonHA=true \
	acrPrivatePool=true \
	kedaAddon=true

