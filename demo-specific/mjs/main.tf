# Used to determine your public IP for forwarding rules
data "http" "whatismyip" {
  url = "http://whatismyip.akamai.com/"
}

provider "aws" {
  # Change your default region here
  region = "us-west-2"
}

provider "azurerm" {
  version = "~> 1.16.0"
}

provider "google" {
  project = "development-152700"
  region  = "us-central-1"
  version = "~> 2.8"
}


module "dcos" {
  # version = "~> 0.2.0"
  version = "~> 0.1.0"
# Uncomment one of: AWS, Azure, GCP
# # AWS
#   source  = "dcos-terraform/dcos/aws"
#   availability_zones = ["us-east-1a","us-east-1b"]
#   bootstrap_instance_type = "c4.xlarge"
#   masters_instance_type  = "c4.xlarge"
#   private_agents_instance_type = "c4.4xlarge"
#   public_agents_instance_type = "c4.xlarge"
# Azure  
  source  = "dcos-terraform/dcos/azurerm"
  location            = "West US" # Azure param
  bootstrap_vm_size = "Standard_A2m_v2"
  masters_vm_size = "Standard_D8s_v3"
  private_agents_vm_size = "Standard_D8_v3"
  public_agents_vm_size = "Standard_D4_v3"

# GCP - Google Cloud Platform
# # If you want to use GCP service account key instead of GCP SDK
# # uncomment the line below and update it with the path to the key file
# #gcp_credentials_key_file = "PATH/YOUR_GCP_SERVICE_ACCOUNT_KEY.json"
# gcp_zone = "a"
# gcp_bootstrap_instance_type = "n1-standard-1"
# gcp_master_instance_type = "n1-standard-8"
# gcp_agent_instance_type = "n1-standard-8"
# gcp_public_agent_instance_type = "n1-standard-8"
## End of Cloud platform-specific parameters
  
  cluster_name = "REPLACE_CLUSTER_NAME"
  ssh_public_key_file= "/home/ec2-user/SE-UI-Toolkit/resources/ssh_public_key.pub"
  admin_ips = ["0.0.0.0/0"]
  dcos_instance_os    = "centos_7.5"
  num_masters        = "1"
  num_private_agents = "8"
  num_public_agents  = "1"
  tags={owner = "REPLACE_OWNER", expiration = "REPLACE_EXPIRATION"}
  dcos_version = "1.13.1"
  providers = {
    azurerm = "azurerm"
    aws     = "aws"
    google  = "google"
  }

  # dcos_variant              = "ee"
  dcos_license_key_contents="${file("/home/ec2-user/SE-UI-Toolkit/resources/license.txt")}"
  dcos_variant = "ee"
  # public_agents_additional_ports = ["18080","18081","10500","10339","6443","6444"]
}

output "masters-ips" {
  value = "${module.dcos.masters-ips}"
}

output "cluster-address" {
  value = "${module.dcos.masters-loadbalancer}"
}

output "public-agents-loadbalancer" {
  value = "${module.dcos.public-agents-loadbalancer}"
}
