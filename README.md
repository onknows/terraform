
azure-openshift
===============

This Terraform project is based on [/drhelius/terraform-azure-openshift](https://github.com/drhelius/terraform-azure-openshift). It creates VM's, load balancers etc in Azure that can be used for an OpenShift installation using for example Ansible.  

To use this project create a file `azure.tfvars` with your Azure client id, tenant id etc. This project uses fixed public IP's that you need to create manually using Azure web interface. See `azure.tfvars.example` for an example file. 

To configure SSH keys based access to bastion and nodes, masters place public keys in current folder. You need to provide two keys: `id_rsa_dic_azure_openshift.pub` and `id_rsa_dic_azure_bastion.pub`

After that you should be able to run Terraform using the script

```
./bootstrap.sh
```

