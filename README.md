# Prodeploy
A simple startup version for your Azure project and resources using helm

**Note: The scripts are used inside the Azure CLI where the `prodeploy` repository has been pulled**  
**Note: Before you do anything log in to a GitHub account with access using:** \  
```
"gh auth login"  
"gh auth refresh -h github.com -s admin:public_key"
```  
## Table of Contents

1. [Introduction](#introduction)
2. [Before Installation](#before-installation)
   - [Step-by-step](#step-by-step)
   - [Passwords](#passwords)
3. [Configuration Details](#configuration-details)
     - [YAML Files](#yaml-files) 
4. [Close cluster](#close-cluster)

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

**ProDeploy/**  
|-- **README.md**/  
*(README guides through installation, configuration, troubleshooting, and offers insights into YAML files. For cluster closure, a command is provided. Detailed instructions ensure smooth deployment and usage.)*  
|-- **application.yaml/**  
*("This YAML configures Argo CD ("reddit") to deploy from "https://github.com/devops-g2/prodeploy.git" to "reddit-application" with auto-sync, pruning, self-healing, and namespace creation.)*  
|-- **argoIngress.yaml/**  
*("Defines Traefik IngressRoute for Argo CD server, routing requests to <LoadBalancer-IP>/argocd/ in the argocd namespace.)*   
|-- **argoValues.yaml/**  
*("ArgoCD configuration with server properties, ingress setup for '/argocd/' path, TLS options, and image details from a specified repository.)*  
|-- **azureCredentials.yaml/**  
*("Azure Container Registry (ACR) credentials stored as a Kubernetes secret, labeled for ArgoCD instance 'reddit' to authenticate with ACR.)*  
|-- **config.sh/**  
*(Bash file containing some information about the cluster. This file is being used by deployAKS.sh)*  
|-- **deployAKS.sh/**  
*("Bash script automating Azure Kubernetes Service (AKS) setup, GitHub integration, and secrets configuration. Creates resources, SSH keys, and GitHub connections.)*  
|-- **deployResources.sh/**  
*("Bash script automating the setup and deployment of Traefik, ArgoCD, Prometheus, and Grafana in an Azure Kubernetes Service (AKS) cluster.)*  
|-- **deployment-api.yaml/**  
*("Kubernetes manifest defining a Deployment, Service, and IngressRoute for 'service2-api'. Deploys 3 replicas with ClusterIP service and Traefik IngressRoute.)*  
|-- **deployment-website.yaml/**  
*("Kubernetes manifest for 'service2-website' deployment, ClusterIP service, and Traefik IngressRoute in the 'reddit-application' namespace with 3 replicas.)*  
|-- **gitCredentials.yaml/**  
*("Secret named 'git-credentials' in 'argocd' namespace, storing Git credentials with username 'dueweb' and a personal access token.)*  
|-- **grafanaIngress.yam/l**/  
*("IngressRoute for Traefik in 'prometheus-grafana' namespace, directing traffic to 'prometheus-grafana' service at IP <LoadBalancer-IP> with path prefix '/grafana/'.)*  
|-- **grafanaScript.sh/**  
*("Bash script to add key-value pairs to a ConfigMap named 'prometheus-grafana' in the 'prometheus-grafana' namespace for Grafana configuration. Used in the deployResources.sh script")*  
|-- **grafanaValues.yaml/**  
*("Grafana values file specifying the admin password as 'Password123'.)*  
|-- **sshSecret.yaml/**  
*("Secret named 'private-repo' in 'argocd' namespace, labeled as a repository secret. Contains Git repository details with type 'git', URL 'git@github.com:devops-g2/prodeploy.git', and an SSH private key thats get set during the running of the deployAKS.sh script.)*  
|-- **traefikAuth.yaml/**  
*("Secret 'traefik-dashboard-auth-secret' with basic authentication credentials for Traefik dashboard. Middleware includes 'traefik-dashboard-auth' and 'content-type-autodetect'.)*  
|-- **traefikValues.yaml/**  
*(This Helm chart values file configures Traefik, a Kubernetes ingress controller. It defines deployment, ingress, providers, ports, TLS, autoscaling, and more.)*  
|-- ..../

## Close cluster
To close the cluster run the command
```
az group delete --resource-group resGrp1 -y 
```
This will shut down the cluster and delete everything and a restart and re-installation of the resources is required to get it functioning again.

