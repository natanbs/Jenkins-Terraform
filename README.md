# Jenkins-Terraform

## Dynamically manage and maintain multiple Terraform environment lifecycles with Jenkins.

https://github.com/natanbs/Jenkins-Terraform

In this post, we will demonstrate how multiple Terraform lifecycle infrastructures can be easily and dynamically managed and maintained per environment with Jenkins.

### Terraform:
Terraform introduces infrastructure as a code and provides the ability to create, update and destroy any kind of component and environment infrastructures in the cloud.
Once provided with the credentials, region, and the required resources, it will be able to create the requested infrastructure. 

Basic Terraform concepts are explained to understand the project's workflow:

#### Terraform env:
An infrastructure created by terraform code. In this project it is just one VPC and a couple of EC2s. But it could be a very complex infrastructure of many VPCs, EC2s,RDS, load-balancing, peering, transit gateway, route53 etc.

#### Terraform init:
Prior to running the code, terraform checks for all the required components needed for the implementation like aws client (It will use it's own), any 3rd party modules like key-pair in this project etc. 
The required components are installed in order the folder .terraform. If any new modules are installed that require new installations, terraform init would have to be run again.

#### Terraform Plan:
Terraform would read all the requirements from the code and compare with the reality in the cloud and would provide a report of the plan.
If it is a new env, it would most like to create from scratch everything from the code. Once the env was created and a new resource was added or deleted in the code, obviously terraform will not create the env from scratch. The terraform plan will provide a report of which components it will add or remove according to the comparison between the requirements in the code the the existing infrastructure in the cloud.

#### Terraform state:
The terraform state if the core of terraform logic. Once terraform compares the requirements in the code vs reality in the cloud, it creates a tfstate file.
The tfstate file is critical as it contains the current state of the infrastructure. Without this file, or in case this file (and its  backup) is corrupted, terraform will not be able to proceed.

#### Cloud bucket:
So having the tfstate file locally is fine as long as you have one admin. But what if there are more admins? They will not be able to use the local tfstate file of the first admin, hence they will not be able to make any changes to the env.
Terraform supports using buckets (S3 in AWS) to maintain the tfstate file in the cloud which allows each admin to access. Terraform would maintain the tfstate in a dedicated Database (DynamoDB in AWS) and manage the lock, which will not allow an admin to run terraform to an env that is currently being handled. Any admin would be able to maintain the env as long as the tfstate in not locked.

#### Terraform workspaces.
So having the tfstate in the cloud is great if you have one env, for example a development infrastructure. A second env would require a separate set of code in another folder and another bucket in the cloud. Not because you can't use variables, but because they cannot share the tfstate file. 
The solution would be to use the terraform workspaces which would create a terraform.tfstate.d folder and each env would have its own folder where the tfstate file is maintained locally. Similarly in the cloud, there would be an env: folder in the bucket with a folder per env where its tfstate file would be held. 
The cloud DB (DynamoDB in AWS) would have a table for the project with one item per env.
Terraform workspaces allows to easily switch between envs on the fly, which will allow in our project to run the same job on different envs per demand. 

#### Getting to business:
In this post we will use AWS, create a VPC with a couple of servers. 
Each Jenkins job would be able create, apply or destroy the env's vpc and its dependencies. 
The key-pairs and the terraform's apply output are stored in the Jenkins artifacts for reference.

For this post you could use the free AWS account. The EC2s are created with the free t2.micro servers. 

Requirements:
- Terraform, Jenkins and AWS basic knowledge.
- <a href="https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html">AWS cli and credentials</a>
- <a href="https://learn.hashicorp.com/terraform/getting-started/install.html">Terraform cli</a>
- Jenkins plugins: 
  - CloudBees AWS Credentials
  - Terraform

The project's terraform file structure includes 3 folders:
- base: Initialise the project - Declare the profile, region, operators, bucket and DynamoDB table. 
  Needs to be applied once before creating the envs. When changing between the envs, the base init should be performed.
  Uses the modules/backend/main module.
- main: Created the env - VPC, Security groups, a couple of EC2s (and their key-pairs)
- modules: Implement the base initialisation.

Jenkins would create / update or destroy any infrastructure you have created with terraform. In this example we used the basic of a couple of EC2s.

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
The base init stage will prepare the S3 bucket
```
$ cd base
$ terraform init
$ terraform plan
$ terraform apply
```

#### The env's lifecyle - init, plan, apply, destroy:: 
```
cd main
terraform workspace new tf-customer1  # Create and select the tf-customer1 env. All the actions will be performed in this env.
terraform init                        # Downloads and installs all the required modules for this project.
terraform plan                        # Show the components terraform will create or update on AWS once applied with Terraform.
terraform apply                       # Perform all the actions shown in the plan above.
terraform destroy                     # Once the env is not needed anymore, the destroy command will remove all its installed components from AWS.
```

#### Created components:
Once terraform is applied, you will be able to find in the AWS console all the components created:<br/>
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

With the cloned git, an AWS account with the AWS credentials set, the env can be instantly create in AWS. 
Managing a couple or a few such envs would be easy. What happens if you have tens of envs?


### Jenkins:
#### Required Jenkins plugin:
- CloudBees AWS Credentials<br>
<img src="https://github.com/natanbs/Jenkins-Terraform/blob/master/screenshots/Plugin_AWS_Credentials.png" width="800" /><br>
- Terraform<br>
<img src="https://github.com/natanbs/Jenkins-Terraform/blob/master/screenshots/Plugin_Terraform.png" width="800" /><br>

Terraform plugin installation:<br>
Manage Jenkins > Global Tool Configuration > Terraform<br>
- Setting Terraform:<br>
  Terraform Name: terraform-0.12.20.<br>
  Version:        Terraform 0.12.20 linux (amd64)   - Notice the OS and platform.<br>

<img src="https://github.com/natanbs/Jenkins-Terraform/blob/master/screenshots/Plugin_Terraform2.png" width="800" /><br>

#### Node installation
Create a permanent node:
<img src="https://github.com/natanbs/Jenkins-Terraform/blob/master/screenshots/Node1.png" /><br>
This agent is configured with ssh launch method, however any preferred method can be used.<br><br>
<img src="https://github.com/natanbs/Jenkins-Terraform/blob/master/screenshots/Node2.png" /><br>
Add a jenkins user and paste its public key:<br><br>
<img src="https://github.com/natanbs/Jenkins-Terraform/blob/master/screenshots/Node3.png" /><br>
We are ready to proceed to set the job<br>
<img src="https://github.com/natanbs/Jenkins-Terraform/blob/master/screenshots/Node4.png" /><br>

#### Job settings
Create a Pipeline job<br>

<img src="https://github.com/natanbs/Jenkins-Terraform/blob/master/screenshots/Pipeline1.png" /><br>
Select:
- Do not allow concurrent builds
- GitHub project
  Project url	https://github.com/natanbs/Jenkins-Terraform

To add parameters, Select:
- This project is parameterized<br>
  Add choice parameter: AWS_REGION and add your regions (can have one or multiple).<br>

<img src="https://github.com/natanbs/Jenkins-Terraform/blob/master/screenshots/Pipeline2.png" /><br>
  Add string parameter: ENV_NAME - This will represent the environment / workspace / customer.<br>
  Add choice parameter: ACTION and add 'plan', 'apply' and 'destroy' - These are the actions Jenkins will trigger Terraform. <br><br>
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

#### Setting AWS access to Jenkins Credentials
To add AWS access to the Jenkins credentials:
- Credentials > System > 	Global credentials (unrestricted) > Add Credentials
- Kind: AWS Credentials
- ID: The Credentialid used in Jenkinsfile, give it a meaningful name.
<img src="https://github.com/natanbs/Jenkins-Terraform/blob/master/screenshots/AWS_access_Jenkins.png" width="800" /><br>


#### Email settings
To set the email notification parameters:
- Settings: Manage Jenkins > Configure System > Extended E-mail Notification
<img src="https://github.com/natanbs/Jenkins-Terraform/blob/master/screenshots/Email.png" /><br>

### The Pipeline
#### Jenkinsfile - Declarative Pipelines 
The declarative pipeline is a relative new Jenkins features using the Jenkinsfile to supports Pipeline as a code concept based on groovy. However basic scripting knowledge is sufficient to understand the script.

The Jenkinsfile code is composed of the following major contexts:
- The terraform command function
- Pipeline settings: Selected slave and job's parameters to run.
- Checkout & Environment Preparations:
  - AWS access
  - Terraform settings
- Actions:
  - Terraform plan
  - Terraform apply
  - Terraform destroy
- Email notification

The full Jenkinsfile is of course in the git repository above. 
The major context will be elaborated bellow:

#### The terraform command function
The following tfCmd command is the terraform command that is executed in each action:
The tfCmd parameters are 'command' and 'options':
- command: The terraform action (init/plan/apply/destroy)
- options: The terraform required options like the output file etc.

Note: Do not confuse between Jenkins and Terraform workspaces:
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
Environment - The environment (Terraform workspace) that will be created (qa/dev/prod etc or customer name or any type of env).
Terraform show - Is perform after each command and outputs the current state to a file. This file is saved in the artifact if the action was 'apply'.

#### Pipeline settings
agent - The slave's label.
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
#### Checkout & Environment Preparations
AWS Access credentials:
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- credentialsId: Taken from Jenkins Credentials:
<img src="https://github.com/natanbs/Jenkins-Terraform/blob/master/screenshots/AWS_access_Jenkins2.png" width="800" /><br>

```
        [ $class: 'AmazonWebServicesCredentialsBinding',
            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
            credentialsId: 'Tikal-AWS-access',
            ]])
```
Setting Terraform:
- tool name: 'terraform-0.12.20     - Terraform version from the terraform plugin configuration above.

Setting AWS credentials:
- aws configure
  - Set AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION and PROFILE before each run
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
#### Actions
##### Action 'plan':
To run only when the action 'plan' or 'apply' are selected. 
Credentials are set as above.
If 'apply' is selected, it will previously run a 'plan' and will use it's tfplan output file.  
```
        stage('terraform plan') {
			when { anyOf
					{
						environment name: 'ACTION', value: 'plan';
						environment name: 'ACTION', value: 'apply'
					}
				}
```

Action 'plan' command:
Will run with the command: 'plan' and options: '-detailed-exitcode -out=tfplan'
Will create a tfplan file to be used by the 'apply'.
```
        tfCmd('plan', '-detailed-exitcode -out=tfplan')
```

##### Action 'apply':
To run only when action 'apply' is selected.
Credentials are set as above.
```
		stage('terraform apply') {
			when { anyOf
					{
						environment name: 'ACTION', value: 'apply'
					}
				}

```
Action 'apply' command:
Simple command: will run: terrform apply tfplan
```
        tfCmd('apply', 'tfplan')

```

Artifacts:
Once action 'apply' is performed and the env is created, the following artifacts will be saved:
- Key pairs of the EC2s
- Output report of the current state

```
			post {
				always {
					archiveArtifacts artifacts: "keys/key-${ENV_NAME}.*", fingerprint: true
					archiveArtifacts artifacts: "main/show-${ENV_NAME}.txt", fingerprint: true
				}
```

##### Action 'destroy':
To run only when action 'destroy' is selected.
If action 'destroy' is selected, a confirmation will be prompt to confirm the deletion of the env.
Credentials are set as above.
```
		stage('terraform destroy') {    
			when { anyOf
					{
						environment name: 'ACTION', value: 'destroy';
					}
				}
				script {
					def IS_APPROVED = input(
						message: "Destroy ${ENV_NAME} !?!",
						ok: "Yes",
						parameters: [
							string(name: 'IS_APPROVED', defaultValue: 'No', description: 'Think again!!!')
						]
					)
					if (IS_APPROVED != 'Yes') {
						currentBuild.result = "ABORTED"
						error "User cancelled"
					}
				}
```

Action 'destroy' command:
Simple command: will run: terrform destroy without prompting.
```
        tfCmd('destroy', '-auto-approve')
```

#### Email notification
Once the job is complete, a notification email is sent with the following details:
- Env (Terraform workspace)
- Job name and number
- Action performed
- Region
```
  post
    {
			always{
			emailext (
			body: """
				<p>${ENV_NAME} - Jenkins Pipeline ${ACTION} Summary</p>
				<p>Jenkins url: <a href='${env.BUILD_URL}/>link</a></p>
				<p>Pipeline Blueocean： <a href='${env.JENKINS_URL}blue/organizations/jenkins/${env.JOB_NAME}/detail/${env.JOB_NAME}/${env.BUILD_NUMBER}/pipeline'>${env.JOB_NAME}(pipeline page)</a></p>
			${env.JENKINS_URL}blue/organizations/jenkins/${env.JOB_NAME}/detail/${env.JOB_NAME}/${env.BUILD_NUMBER}/pipeline
				<ul>
				<li> Branch built: '${env.BRANCH_NAME}' </li>
				<li> ACTION: $ACTION</li>
				<li> REGION: ${AWS_REGION}</li>
				</ul>
				""",
				recipientProviders: [[$class: 'DevelopersRecipientProvider'], [$class: 'RequesterRecipientProvider']],
				to: "${EMAIL}",
				subject: "[${ENV_NAME}] - ${env.JOB_NAME}-${env.BUILD_NUMBER} [$AWS_REGION][$ACTION]",
				attachLog: true
				)
        }
    }
```