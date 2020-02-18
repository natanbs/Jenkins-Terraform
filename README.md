# Jenkins-Terraform

## Dynamically manage and maintain multiple Terraform environment lifecycles with Jenkins.


In this post, we will demonstrate how multiple Terraform lifecycle infrastructures can be easily and dynamically managed and maintained per envromnment with Jenkings.

### Terraform:
Terraform introduces infrastructure as a code and provides the ability to create, update and destroy any kind of component and environemt infrastructures in the cloud.
Once provided with the credentials, region, and the required resources, it will be able to create the requested infrastructure. 

Basic Terraform concepts are explained to understand the projent's workflow:

#### Terraform env:
An infrastructure created by terraforrm code. In this project it is just one VPC and a couple of EC2s. But iot could be a very complex infrastructure of many VPCs, EC2s,RDS, loadbalancing, peering, transit gateway, route53 etc.

#### Terraform init:
Prior to running the code, terraform checks for all the required components needed for the implementation like aws client (It will use it's own), any 3rd party modules like key-pair in this project etc. 
The required components are installed onder the folder .terraform. If any new modeles are installed that require new installations, terrform init would have to be run again.

#### Terraform Plan:
Terraform would read all the requirements from the code and compare with the reality in the cloud and would provide a report of the plan.
If it is a new env, it would most like to create from scratch everything from the code. Once the envc was created and a new resource was added or deleted in the code, obviosly terraform will not create the env from scratch. The terraform plan will provide a report of which components it will add or remove according to the comparison between the requirements in the code the the existing infrastructure in the cloud.

#### Terraform state:
The teraform state if the core of terraform logic. Once terraform compares the requirements in the code vs reality in the cloud, it creates a tfstate file.
The tfstate file is critical as it contains the current state of the infrastructure. Without this file, or in case this file (and it's  backup) is currupted, terraform will not be able to proceed.

#### Cloud bucket:
So having the tfstate file locally is fine as long as you have one admin. But what if there are more admins? They will not be able to use the local tfstate file of the first admin, hence they will not be able to make any changes to ther env.
Terraform supports using buckets (S3 in AWS) to mainten the tfstate file in the cloud which allows each admin to access. Terraform would maintain the tfstate in a dedicated Database (DynamoDB in AWS) and manage the lock, which will not allow an admin to run terraform to an env that is currently being handled. Any admin would be able to maintain the env as long as the tfstate in not locked.

#### Terraform workspaces.
So having the tfstate in the cloud is great if you have one env, for example a development infrastructure. A second env would require a separate set of code in another folder and another bucket in the cloud. Not because you can't use variables, butr because they canniot share the tfstate file. 
The solution would be to use the terraform workspaces which would create a terraform.tfstate.d folder and each env would have it's own folder where the tfstate file is maintained locally. Similarily in the cloud, there would be an env: folder in the bucket with a folder per env where it's tfstate file would be held. 
The cloud DB (DynamoDB in AWS) would have a table for the project with one item per env.
Terraform workspaces allows to easily switch between envs on the fly, which will allow in our project to run the same job on different envs per demand. 

#### Getting to business:
In this post we will use AWS, create a VPC with a couple of servers. 
Each Jenkins job would be able create, apply or destroy ther env's vpc and its dependencies. 
The key-pairs and the terrform's apply output are stored in the Jenkins artifacts for refernace.

For this post you could use the free AWS account. The EC2s are created with the free t2.micro servers. 

Requirements:
- Terraform, Jenkins and AWS basic knowledge.
- <a href="https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html">AWS cli and credentials</a>
- <a href="https://learn.hashicorp.com/terraform/getting-started/install.html">Terraform cli</a>
- Jenkins plugins: 
  - CloudBees AWS Credentials
  - Terraform

The project's terraform file structure includes 3 folders:
- base: Initialize the project - Declare the profile, region, operators, bucket and dynamodb table. 
  Needs to be applied once before creating the envs. When changing between the envs, the base init should be performed.
  Uses the modules/backend/main module.
- main: Created the env - VPC, Security goups, a couple of EC2s (and thier key-pairs)
- modules: Implement the base initialization.

Jenkins would create / update or destroy and infrastructure you have created with terraform. In this example we used the basic of a couple of EC2s.

The project's full structure: 

<img src="https://github.com/natanbs/Jenkins-Terraform/blob/master/screenshots/Proj-tree.png" width="180" /><br>

#### git repository
https://github.com/natanbs/Jenkins-Terraform

The procedure to run the terraform code:

#### Set your AWS credentials:

cat ~/.aws/credentials<br/>
Example output:<br/>
[tikal]<br/>
aws_access_key_id = ***************OUEU<br/>
aws_secret_access_key = ********************************i8S8<br/>

aws configure<br/>
Example output:<br/>
AWS Access Key ID [****************OUEU]:<br/>
AWS Secret Access Key [****************i8S8]:<br/>
Default region name [eu-central-1]:<br/>
Default output format [text]:<br/>

#### Initiate the project:
cd base<br/>
terraform init<br/>
terraform plan<br/>
terraform apply // Run only once.<br/>

Create an env:<br/>
cd main<br/>
terraform workspace new tf-customer1  // Will create and select the tf-customer1 env. Now on all the actions will be performed in this env.<br/>
terraform init                        // Downloads and installs all the required modules for this project.<br/>
terraform plan                        // Show which components terraform will create or update with once applied in AWS.<br/>
terraform apply                       // Will perform all the actions shown in the plan.<br/>
terraform destroy                     // Once you don't need the env anymore this command will remove all the installed components.<br/> 

#### Created components:
Once teraform is applied, you will be able to find in the AWS console all the components created:<br/>
- S3 bucket (under env: you will find a folder per environment which will include the env's tfstate file)
- Dynamodb table (which manages and maintains the tfstate files)
- VPC
- Subnets - two private and two public
- Route tables
- Internet Gateway
- Network ACLs
- Security Groups
- EC2s - Two servers (server1 and server 2 in this example)
- Key-pairs
- Network instances

If you have cloned the git, have an AWS account and set the AWS credentials, yiu can instantly create new envs in AWS.
Managing a couple or a few such envs would be easy. What happens if you have tens of envs? What if you have more than one 


### Jenkins:
#### Required Jenkins plugin:
- CloudBees AWS Credentials<br>
<img src="https://github.com/natanbs/Jenkins-Terraform/blob/master/screenshots/Plugin_AWS_Credentials.png" width="800" /><br>
- Terraform<br>
<img src="https://github.com/natanbs/Jenkins-Terraform/blob/master/screenshots/Plugin_Terraform.png" width="800" /><br>

Terraform plugin installation:<br>
Manage Jenkins > Global Tool Configuration > Terraform<br>

<img src="https://github.com/natanbs/Jenkins-Terraform/blob/master/screenshots/Plugin_Terraform2.png" width="800" /><br>

#### Node installation
Create a permanent node:
<img src="https://github.com/natanbs/Jenkins-Terraform/blob/master/screenshots/Node1.png" /><br>
This agent is configured with ssh launch method, however any method preferred.<br><br>
<img src="https://github.com/natanbs/Jenkins-Terraform/blob/master/screenshots/Node2.png" /><br>
Use jenkins user and paste its public key.<br><br>
<img src="https://github.com/natanbs/Jenkins-Terraform/blob/master/screenshots/Node3.png" /><br>
<br>
We are ready to proceed to set the job
<img src="https://github.com/natanbs/Jenkins-Terraform/blob/master/screenshots/Node4.png" /><br>

#### Job settings
Create a Pipeline job
<img src="https://github.com/natanbs/Jenkins-Terraform/blob/master/screenshots/Pipeline1.png" /><br>
Select:
- Do not allow concurrent builds
- GitHub project
  Project url	https://github.com/natanbs/Jenkins-Terraform

To add parameters, Select:
- This project is parameterized<br>
  Add choice parameter: AWS_REGION and add your regions (can have one or multiple).<br>
<br>
<img src="https://github.com/natanbs/Jenkins-Terraform/blob/master/screenshots/Pipeline2.png" /><br>
  Add string parameter: ENV_NAME - This will represent the environemnt / workspace / customer.<br>
  Add choice parameter: ACTION and add plan, apply and destroy - These are the actions Jenkins will trigger Terraform. <br>
<img src="https://github.com/natanbs/Jenkins-Terraform/blob/master/screenshots/Pipeline3.png" /><br>
  Add string parameter: PROFILE which is the AWS credential profile.<br>
  Add string parameter: EMAIL with the emails or mailing list to the admins.<br>
<img src="https://github.com/natanbs/Jenkins-Terraform/blob/master/screenshots/Pipeline4.png" /><br>

Set the Git for the Pipeline:<br>
  Pipeline definition: Pipeline script from SCM<br>
    SCM: Git<br>
      Repositories:<br>
        Repository URL: git@github.com:natanbs/Jenkins-Terraform.git<br>
        Credentials: jenkins's user.<br>

Script Path: Jenkinsfile <br><br>
<img src="https://github.com/natanbs/Jenkins-Terraform/blob/master/screenshots/Pipeline5.png" /><br>

#### Setting AWS Credentials
To configure the AWS Credentials:
- Install the CloudBees AWS Credentials plugin
- Settings: Manage Jenkins > Configure System > Global properties
<img src="https://github.com/natanbs/Jenkins-Terraform/blob/master/screenshots/AWS_credentials.png" width="800" /><br>


#### Declartive Pipelines 
The declerative pipeline is a relative new Jenkins features using the Jenkinsfile to supports Pipeline as a code concept based on groovy. However basic scripting knowledge is sufficient to understand the script. 

The following tfCmd command is the terraform command that is executed in each action:
The tfCmd parameters are 'command' and 'options':
- command: The terraform action (init/plan/apply/destroy)
- options: The terraform required options like the output file etc.

Note: Do not confuse between Jenkins and Terraform workspace:
- Jenkins workspace is the Jenkins directory where the job is running.
- Terraform workspace is the environment created.

```
def tfCmd(String command, String options = '') {
	ACCESS = "export AWS_PROFILE=${PROFILE} && export TF_ENV_profile=${PROFILE}"
	sh ("cd $WORKSPACE/base && ${ACCESS} && terraform init") // base
	sh ("cd $WORKSPACE/main && ${ACCESS} && terraform init") // main
	sh ( "cd $WORKSPACE/main && terraform workspace select ${ENV_NAME} || terraform workspace new ${ENV_NAME}" )
	sh ( script: "echo ${command} ${options} && cd $WORKSPACE/main && ${ACCESS} && terraform init && terraform ${command} ${options} && terraform show -no-color > show-${ENV_NAME}.txt", returnStatus: true)
}
```


The following parameters are set with each run (tfCmd) since the jobs can be run each time for a different env:
- WORKSPACE - Junkins workspace
- ENV_NAME  - Terraform workspace (env) each time the command is run, jenkins ($WORKSPACE) and terraform ($ENV_NAME) workspace are selected and terraform init is run in the base and main folders.
- ACCESS    - The AWS credentials profile to be used, taken from the PROFILE parameter when running the build and it's settings shown above.
 
Terraform init - Performed both in the base ands main directories with each run since to make sure the env is updated as the job can be run by other users on other slaves.
Environment - The environemt (Terraforn workspace) that will be created (qa/dev/prod etc or customer name or any type of env).
Terraform show - Is perform after each command and outputs the current state to a file. This file is saved in the artifact if the action was 'apply'.

#### The Pipeline:
For the full file, see the Junkfile in the git.

agent - The slave's lable.
```
pipeline {
  agent { node { label 'tf-slave' } }
``` 

Parameters
- AWS_REGION (choice): The job supports multiple AWS regions. 
- ENV_NAME   (string): The created env (Terraform workspace).
- ACTION     (choice): The terraform action to perform (plan/apply/destroy)
- EMAIL      (string): Emails or mailing lists for notification.  
```
	parameters {

		choice (name: 'AWS_REGION',
				choices: ['eu-central-1','us-west-1', 'us-west-2'],
				description: 'Pick A regions defaults to eu-central-1')
		string (name: 'ENV_NAME',
			   defaultValue: 'tf-customer1',
			   description: 'Env or Customer name')
		choice (name: 'ACTION',
				choices: [ 'plan', 'apply', 'destroy'],
				description: 'Run terraform plan / apply / destroy')
		string (name: 'PROFILE',
			   defaultValue: 'tikal',
			   description: 'Optional. Target aws profile defaults to tikal')
		string (name: 'EMAIL',
			   defaultValue: 'natanb@tikalk.com',
			   description: 'Optional. Email notification')
    }
```
Checkout & Environment Prep
AWS Access credentials:
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY

```
        [ $class: 'AmazonWebServicesCredentialsBinding',
            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
            credentialsId: 'larobot-aws-credentials',
            ]])
```
Setting Terraform:
- tool name: 'terraform-0.12.20     - Terraform version from the terraform plugin.
```
    {
        echo "Setting up Terraform"
        def tfHome = tool name: 'terraform-0.12.20',
            type: 'org.jenkinsci.plugins.terraform.TerraformInstallation'
            env.PATH = "${tfHome}:${env.PATH}"
            currentBuild.displayName += "[$AWS_REGION]::[$ACTION]"
            sh("""
                /usr/local/bin/aws configure --profile ${PROFILE} set aws_access_key_id ${AWS_ACCESS_KEY_ID}
                /usr/local/bin/aws configure --profile ${PROFILE} set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY}
                /usr/local/bin/aws configure --profile ${PROFILE} set region ${AWS_REGION}
                export AWS_PROFILE=${PROFILE}
                export TF_ENV_profile=${PROFILE}
                mkdir -p /home/jenkins/.terraform.d/plugins/linux_amd64
            """)
            tfCmd('version')
    } 
```