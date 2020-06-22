

> :warning: ***This is work in progress with some additional updates to handle some known nuances coming  soon.***

## Vault on Openshift using Helm
-------------

This is a sample repo to setup a Hashicorp Vault Enterprise 1.4.2 HA cluster using integrated storage on your local system using Minishift. 


### Prerequisite
The automation script vault.sh assumes you have:

    1. Oracle virtual box setup
    2. Helm 3.0+ is setup

The script will also check if you have minishift installed already.
If not, it will install  minishift on you system using homebrew.

### Usage

1. Clone this repo on you local system

>       $ git clone git@github.com:basingh/vault_on_openshift.git

2. Make sure you have Oracle Virtual box and Helm installed then run vault.sh

>       $ ./vault.sh

3. The script will do couple of things as listed below:

```
       . Check if minishift is already installed, if not, it will install it through homebrew
       . Start a minishift VM with following spec : --disk-size 20GB --cpus 2 --memory 4GB
       . Configure your shell path for minishift command to process
       . Give appropriate access to user `developer`
       . Using developer spin up a OS project named `vault`
       . It will then using parameters in vaules.yaml spin up a vault enterprise cluster using Helm.
                - In the end you will see 3 vault pods named `vault-<n>`
                - And Vault agent injector pod
       . Display output of Vault status from vault-0 pod
```

:eyes: **Please Note**: There are couple of changes are done here on Hashicorp Vault official Vault-Helm chart to make it work in local

```
        1. As minishift like minicube is lightweight single node instance, we have to comment out the affinity lsrules from vaules.yaml. So that all 4 pods are created under same node.
        2. Commented out caBundle from injector-mutating-webhook.yaml to suppress the error.
        3. Values.yaml is set to fetch Vault Enterprise latest image from Docker hub. If you want use OSS or other version please update the repository information and version on agentImage and server accordingly.
```

