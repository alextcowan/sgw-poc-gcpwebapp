# Simple Private Web App for Chrome Enterprise Security Gateway Testing

This repository contains Terraform scripts to deploy a Google Cloud Compute Engine Linux VM with Apache web server. 
The VM is created in the project's default VPC. If the cloud project has customized VPCs then the terraform script will need to be adapted to point at the network.
It provides basic Cloud DNS, firewall access, and a helper script to copy the web server's self-signed certificate for incorporation as a root cert.


---
## Prerequisites

* A Google Cloud project with billing enabled.
* An authenticated Google Cloud Shell environment.
* The Go programming language (this is pre-installed on Cloud Shell).

---
## 1. Set Up the custom terraform provider

Assuming this project already has had a Security Gateway deployed via [sgw-poc-terraform github repo](https://github.com/alextcowan/sgw-poc-terraform).
This repo and process leverages the configuration already completed in step 1 of the SGW terraforming.

---
## 2. Deploy the infrastructure

#### **A. Clone this repository**
Clone this repository into your Cloud Shell environment.

```bash
cd ~
git clone https://github.com/alextcowan/sgw-poc-gcpwebapp.git
cd sgw-poc-gcpwebapp
```
#### **B. Configure variables**
Create a `terraform.tfvars` file to define your environment. You can use the `terraform.tfvars.example` file as a reference.

*Example `terraform.tfvars`:*
```hcl
project_id = "cep-project-429502"
dns_zone_name = "gcp.securebrowsing.cloud"
hostname = "pwa"
zone = "us-central1-a"
# ... other variables
```
#### **C. Initialize and apply**
Initialize terraform to download the necessary plugins (it will use the local provider you just built) and then apply the configuration to create the resources.

```bash
terraform init
terraform plan
terraform apply
```
Review the plan and type `yes` to proceed.

---
## 3. Self-signed Certificate Export
As part of the Linux server VM creation, a self-signed certificate will be created using openssl.

There is a helper python script which will copy the root cert from the Linux VM to the GCP Cloud Shell. This can then be downloaded and uploaded for client side installation and TLS handshaking.
```bash
python get_ca_cert.py
```

---
## 4. Cleanup
To remove all resources created by this configuration, run the `destroy` command.

```bash
terraform destroy
