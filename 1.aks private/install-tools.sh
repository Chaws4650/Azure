#!/bin/bash

sudo apt -qq update

# install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# install Kubectl CLI
az aks install-cli
sudo apt install docker.io -y
sudo usermod -aG docker $USER



# login to Azure using VM's Managed Identity
# az login --identity

# az aks list -o table

# az aks get-credentials -g rg-private-aks-bastion-260 -n aks-private-260

# kubectl get nodes