# Prodeploy
A simple startup version for your Azure project and resources using helm

**Note: The scripts are used inside the Azure CLI where the `prodeploy` repository has been pulled**  

## Table of Contents

1. [Introduction](#introduction)
2. [Before Installation](#before-installation)
   - [Step-by-step](#step-by-step)
   - [Passwords](#passwords)
3. [Configuration Details](#configuration-details)
     - [YAML Files](#yaml-files) 
4. [Close cluster](#close-cluster)
5. [Troubleshooting](#troubleshooting)

## Introduction

This repository is made to automate the startup-process, cluster, and the resources needed to log, monitor, data in various tools and resources. Prodeploy consists of two scripts:

#### `deployAKS.sh`

This script is your gateway to the cloud! It effortlessly creates an Azure resource group, deploys an AKS cluster with a sprinkle of magic, and sets up the necessary configurations for a smooth sailing experience. No more tangled commands – just run this script, and watch your cluster come to life. Modify the file to change the number of nodes deployed.

#### `deployResources.sh`

Once your AKS cluster is up and running, the `deployResources.sh` script takes charge. It orchestrates the deployment of essential tools, such as Traefik, ArgoCD, Prometheus, and Grafana. The script ensures that the Kubernetes environment is well-equipped for any challenge. Resources are deployed on port 9000.

## Before Installation

**Note: Before you do anything log in to a GitHub account with access using: \  
```
gh auth login" \  
"gh auth refresh -h github.com -s admin:public_key"
```

**Note: If using NSG (netwrok security rule) - Before running this script, ensure you check the IP access configuration in the `deployResources.sh` and add the appropriate IPs (your own IP to access the resources). Example Below:**

```
az network nsg rule create \
--nsg-name $nsgName \
-n ipAccess \
--priority 498 \
-g mc_${resGroup}_${cluster}_${location} \
--source-address-prefixes <Example:000.000.000.000> <Your-IP> \
--source-port-ranges "*" \
--access Allow \
--destination-port-ranges 9000
# END OF NSG(NETWORK SECURITY GOUP) CONFIGURATIONS
```

**Note: IP are meant to be changed in the `deployResources.sh`. But to find the NSG rules in Azure look for NSG rule that  that has similar pattern as "aks-agentpool-17505690-nsg", that is your NSG rule. Inside you will find the section "Inbound Security Rules" and a rule named ipAccess, add your wished IP to access the resources on port 9000**  

### Step-by-step

1. Login to Microsoft Azure  
2. Access the Azure CLI  
3. Run the command to authenticate yourself to github using the account thats connected with the prodeploy repo.  
```
"gh auth login" \  
"gh auth refresh -h github.com -s admin:public_key"
```  
4. Pull the Prodeploy repository from the github using the Azure CLI
```
git clone https://github.com/<repo-path>/prodeploy.git
```  
5. Run the scripts in the specified order using the Azure CLI (this might take a while):
**Note: If its not the first time running the scripts, check the sshSecrets.yml and make sure that the "sshPrivateKey" is empty**  

`bash deployAKS.sh` Azure unfolds and configures your Kubernetes environment.
```
bash deployAKS.sh
```
`bash deployResources.sh` to deploy the essential tools.   
```
bash deployResources.sh
```  
6. The cluster and resources should be up and running.  

** To access the resources check the URL inside of the ingress-route files that is inside of the:  
github-->prodeploy-->"...Ingress.yaml"**  

### Passwords  
Grafana: Check grafanaValues.yml  
Traefik: Check traefikAuth.yml  
ArgoCD: ArgoCD currently sets the password automatically, run the following command inside of the Azure CLI to get the password:  
```
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## Configuration Details

### YAML Files

ProDeploy/  
|-- README.md/ 
|-- **application.yaml** *(Brief description)*/  
|-- argoIngress.yaml *(Brief description)*/  
|-- argoValues.yaml/  
|-- azureCredentials.yaml/  
|-- config.sh/  
|-- deployAKS.sh/  
|-- deployResources.sh/  
|-- deployment-api.yaml/  
|-- deployment-website.yaml/
|-- gitCredentials.yaml/  
|-- grafanaIngress.yaml/  
|-- grafanaScript.sh/  
|-- grafanaValues.yaml/  
|-- sshSecret.yaml/  
|-- traefikAuth.yaml/  
|-- traefikValues.yaml/  
|-- ..../

## Close cluster
To close the cluster run the command
```
az group delete --resource-group resGrp1 -y 
```
This will shut down the cluster and delete everything and a restart and re-installation of the resources is required to get it functioning again.
