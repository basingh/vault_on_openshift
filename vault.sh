#!/bin/bash

if hash minishift 2>/dev/null; then
	echo "minishift is already installed moving on to bring vm up"
    
else
	echo "minishift is not installed, installing it now......"
    brew cask install minishift
fi

## bring minishift VM up using virtualbox
echo "########################## starting up the VM ##########################"
minishift start --vm-driver virtualbox --disk-size 20GB --cpus 2 --memory 4GB
## configure your shell for minishift

echo "########################## setting up shell ##########################"
eval $(minishift oc-env)

## confirm setup is completes

echo "########################## run help to confirm setup ##########################"
oc --help

## login in with admin

echo "########################## login using admin ##########################"
oc login -u system:admin
oc adm policy add-role-to-user admin developer
oc adm policy add-cluster-role-to-user cluster-admin developer

oc login -u developer
## create a new project for vault
echo "########################## create a new project for vault ##########################"
oc new-project vault \
    --description="vault" --display-name="vault"

## confirm the project context is set to vault 

oc project

## next up install vault HA cluster using helm
## add Hashicorp to your  Helm
helm repo add hashicorp https://helm.releases.hashicorp.com

## search for repo vault if you have access
helm search repo hashicorp/vault

## for enterprise binary on local
## make sure you update agent image on vaulues.yaml
##  # agentImage sets the repo and tag of the Vault image to use for the Vault Agent
##  # containers.  This should be set to the official Vault image.  Vault 1.3.1+ is
##  # required.
##  agentImage:
##    repository: "vault-enterprise"
##    tag: "1.4.2_ent" 
helm install vault -f values.yaml ./ \
  --set='global.openshift=true' \
  --set='server.ha.enabled=true' \
  --set='server.ha.raft.enabled=true'

## for dev binary

#helm install vault hashicorp/vault \
#    --set "global.openshift=true" \
#    --set "server.dev.enabled=true"

## setup vault now
sleep 10s
# first check pod status, output of this command should be `running`
oc describe pods vault-0 | grep ^Status: | head -1 | awk '{print $2}' | tr -d '\n'

oc exec -ti vault-0 -- vault status

# initialize vault