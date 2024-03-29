#!/bin/bash
git pull
# Source configuration variables from a separate file
source config.sh

# Read Traefik values from a file
#sed -i -e 's/\r$//' deploy.sh
traefikValues="$(cat traefikValues.yaml)"

# Print some configuration information for reference
echo "resgrp:"$resGroup""
echo "MCresgrp:"$MCresGroup""
echo "cluster:"$cluster""
echo "location=\"$location\""
echo "tag=\"$tag\""



# Installing Traefik in a Kubernetes cluster
kubectl create namespace traefik
helm repo add traefik https://helm.traefik.io/traefik
helm upgrade --install traefik --values traefikValues.yaml \
    --namespace traefik \
    traefik/traefik \
    --version 24.0.0 \
    --create-namespace 
kubectl apply -f traefikAuth.yaml -n traefik
# END OF TRAEFIK INSTALLATION

# Installing ArgoCD in the cluster
helm repo add argo https://argoproj.github.io/argo-helm
helm upgrade --install my-argo-cd argo/argo-cd --values argoValues.yaml \
    --namespace argocd \
    --version 5.46.8 \
    --create-namespace 
kubectl apply -f argoIngress.yaml -n argocd
kubectl create namespace reddit-application
kubectl apply -f application.yaml -n argocd
kubectl apply -f gitCredentials.yaml -n argocd
kubectl apply -f azureCredentials.yaml
echo "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d"
# END OF ARGOCD INSTALLATION

# Installing Prometheus and Grafana
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack --values grafanaValues.yaml \
--namespace prometheus-grafana \
--version 51.x \
--create-namespace 
bash grafanaScript.sh serve_from_sub_path=true
bash grafanaScript.sh root_url=http://20.10.108.94/grafana/

grafanaPod=$(kubectl get pods -n prometheus-grafana | awk '$1 ~ /^prometheus-grafana/ {print $1; exit}')

echo "grafanaPod: $grafanaPod"
kubectl delete pods $grafanaPod -n prometheus-grafana
kubectl apply -f grafanaIngress.yaml -n prometheus-grafana
# END OF PROMETHEUS/GRAFANA INSTALLATION

# Apply manifest files
kubectl apply -f deployment-api.yaml
kubectl apply -f deployment-website.yaml
#End of applying mainfest files 

# Configuring Network Security Group (NSG) rules
externalIP=$(kubectl get service/traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}' -n traefik)
echo "$externalIP"

# Retrieving VNet, subnet, and NSG information
vnetName=$(az network vnet list --resource-group "mc_${resGroup}_${cluster}_${location}" --query '[].name' --output tsv)
echo "vnetName: $vnetName"

subnetName=$(az network vnet subnet list --vnet-name $vnetName --resource-group "MC_${resGroup}_${cluster}_${location}" --query '[].name' --output tsv)
echo "subnetName: $subnetName"

nsgName=$(az network nsg list --resource-group "mc_${resGroup}_${cluster}_${location}" --output json | jq -r '.[0].name')
echo "nsgName: $nsgName"

echo "kubectl get secret <secret-name> -o jsonpath="{.data.admin-password}" | base64 --decode"

# Creating NSG rules to control traffic
#az network nsg rule create \
#--nsg-name $nsgName \
#-n denyAll \
#--priority 499 \
#-g mc_${resGroup}_${cluster}_${location} \
#--source-address-prefixes Internet \
#--source-port-ranges "*" \
#--access Deny \
#--destination-port-ranges 9000

#az network nsg rule create \
#--nsg-name $nsgName \
#-n ipAccess \
#--priority 498 \
#-g mc_${resGroup}_${cluster}_${location} \
#--source-address-prefixes 155.137.24.159 \
#--source-port-ranges "*" \
#--access Allow \
#--destination-port-ranges 9000
# END OF NSG(NETWORK SECURITY GOUP) CONFIGURATIONS
