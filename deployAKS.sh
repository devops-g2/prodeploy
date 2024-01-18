#!/bin/bash
 
# This script automates the setup of an Azure Kubernetes Service (AKS) cluster,
# integrates it with GitHub, and configures secrets for deployment.
#Useful tip
#https://learn.microsoft.com/en-us/training/modules/aks-deploy-container-app/3-exercise-create-aks-cluster?tabs=linux
 
#Random Number
randomIdentifier=$((RANDOM % 900 + 100))
customer="dev"
resGroup="resGrp1" #""$customer"rg"$randomIdentifier""
cluster="devaks1" #""$customer"aks"$randomIdentifier""
userpool="userpool1" #""$customer"upl"$randomIdentifier""
location="eastus2"
tag="Deployment=test"
admin="clxadmin"
MCresGroup="MC_${resGroup}_${cluster}_${location}"
 
#ssh="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDT+fbB/SvKNkYY53YPqNwPaE63PgDMlsuMzeQeqSNwpw9PzTqEPInkF7e5p54Hu2ensEyFpw026rAdl9ScUvhSlOgOYc6hgV9o+WOcjHXZa7k0KICKBVkTjuGQ4EDKdVsbhag77VrEmuUDbuVqzKR0Cl/UL+WMt3a/xoJyg9QlZ7hFPRLTtHOLUqji4a/W2jWnuG2Cp1UViWdyzlClFO7PGhGaMfHj9vYM8ZCs5+lTpD0obmmQrcjSXGJhOEEHXnvS7CFl9Cg3dzGjmw4frsHmok162VX5PkK6ia2qXEK2QchDTMQZ98cKGkPuwHUA4N7H5cMXPPGM8H8f7cikZdFv"
 
# Create Azure resource group
echo 'group create - resgrp:'$resGroup', cluster: '$cluster''
az group create --name=$resGroup --location=$location --tag $tag
 
# Add a node pool to the AKS cluster
echo 'create cluster - resgrp:'$resGroup', cluster: '$cluster''
az aks create \
--resource-group $resGroup \
--name $cluster \
--node-count 1 \
--node-vm-size Standard_D2pds_v5 \
--network-plugin azure \
--enable-managed-identity \
--generate-ssh-keys \
--admin-username $admin
 
#--node-count 2 \
 
echo 'create nodepool - resgrp:'$resGroup', cluster: '$cluster''
az aks nodepool add \
--resource-group $resGroup \
--cluster-name $cluster \
--name $userpool \
--node-count 1 \
--node-vm-size Standard_D2pds_v5 \
--os-sku AzureLinux
 
#--node-count 2 \
 
#WRITE VARIABLES TO CONFIG FILE
echo "resGroup=\"$resGroup\"" > config.sh
echo "cluster=\"$cluster\"" >> config.sh
echo "location=\"$location\"" >> config.sh
echo "tag=\"$tag\"" >> config.sh
echo "MCresGroup=\"$MCresGroup\"" >> config.sh
 
# Get AKS cluster credentials
echo 'get credentials - resgrp:'$resGroup', cluster: '$cluster''
az aks get-credentials --resource-group $resGroup --name $cluster
 
#ADD SUPPORT FOR GH API
#CHECK PRIVATE AND PUBLIC KEY
privateKeyFile="$HOME/.ssh/id_rsa"
publicKeyFile="$HOME/.ssh/id_rsa.pub"
 
if [ -f "$privateKeyFile" ] && [ -f "$publicKeyFile" ]; then
    privateKey=$(cat "$privateKeyFile")
    publicKey=$(cat "$publicKeyFile")
    echo "Private key and public key read successfully."
else
    echo "One or both of the key files do not exist or cannot be accessed."
fi
 
# Add indentation to the private key and write to a YAML file
indentedPrivateKey=""
while IFS= read -r line; do
    indentedPrivateKey+="    $line"$'\n'  # Add two spaces (you can adjust the number of spaces as needed)
done <<< "$privateKey"
 
echo "$indentedPrivateKey" >> sshSecret.yaml
cat sshSecret.yaml
# Create a Kubernetes namespace and apply the SSH secret
kubectl create namespace argocd
kubectl apply -f sshSecret.yaml -n argocd
 
# Connect the public key to gitHub
gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  -f title="AKS-key" \
  -f key="$publicKey" \
  /user/keys
#CLOSE ADD SUPPORT FOR GITHUB API
 
# Add a secret to GitHub for external access to the cluster
#gh auth refresh -h github.com -s admin:public_key
gh secret set KUBE_CONFIG --repo devops-g2/prodeploy --body "$(base64 -w 0 -i ~/.kube/config)"
 
#SETUP REMOTE CONNECTION TO GIT
kubectl create serviceaccount github-actions-serviceaccount
kubectl create clusterrole github-actions-clusterrole --verb=get,list,create,update,delete --resource=pods,services,deployments
kubectl create clusterrolebinding github-actions-clusterrolebinding --serviceaccount=default:github-actions-serviceaccount --clusterrole=github-actions-clusterrole
