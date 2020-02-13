# Jenkins-Terraform

## Dynamically manage and maintain multiple Terraform environment lifecycles with Jenkins.

Overview:
Terraform enables you to create, update and destroy environemts infrastructures.
If you have a few environments like production, staging and QA for example, you could live with Terraform alon.
But in the scenario where you need to manage the same or similar infrastructure per unknown amount of envs (i.e. custoemrs), this can become overkilling.  
We will demonstrate how multiple lifecycle infrastructures can be easily and dynamically managed and maintained per envromnment with Jenkings.

This project supports running the job by multiple users, independent of the jenkins agent where the env was initially created.

In this workshop we will use AWS, create a VPC with a couple of servers. 
Each Jenkins job would be able create, apply or destroy ther env's vpc and its dependencies. 
The key-pars and the terrform apply output are stored in the Jenkins artifacts.

Requirements:
AWS credentials
AWS cli
Terraform cli
Jenkins plugins: 
- CloudBees AWS Credentials
- Terraform



The project's file structure includes a Jenkinsfile and the Terraform code:

.
├── Jenkinsfile
├── README.md
├── base
│   ├── main.tf
│   ├── plan
│   ├── terraform.tfvars
│   └── variables.tf
├── keys
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
        ├── templates
        │   └── policy.json.tpl
        └── variables.tf



