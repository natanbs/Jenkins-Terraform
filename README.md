# Jenkins-Terraform

## Dynamically manage and maintain multiple Terraform environment lifecycles with Jenkins.

Overview:
Terraform enables you to create, update and destroy environemts infrastructures.
If you have a few environments like production, staging and QA for example, you could live with Terraform alon.
But in the scenario where you need to manage the same or similar infrastructure per customer, this can become overkilling.  
We will demonstrate how multiple lifecycle infrastructures can be easily and dynamically managed and maintained per envromnment
with Jenkings.

In this workshop we will use AWS, create a VPC with a couple of servers. 
Each Jenkins job will create / apply / destroy a customer's vpc. 
The key-pars and the terrform output are stored in the Jenkins artifacts.

Requirements:
AWS credentials
AWS cli
Terraform cli


The project's file structure includes a Jenkinsfile and the Terraform code:

.
├── Jenkinsfile
├── README.md
├── base
│   ├── main.tf
│   ├── terraform.tfvars
│   └── variables.tf
├── main
│   ├── backend.tf
│   ├── data.tf
│   ├── ec2.tf
│   ├── main.tf
│   ├── securitygroup.tf
│   ├── terraform.tfvars
│   └── variables.tf
└── modules
    └── backend
        ├── main.tf
        └── variables.tf



