
# Devops pretest task

As per the sent mail took up the task of creating Docker image and ECS/EKS cluster of simmple timestamp and Ip app 

The public repository for the task is [public-GitHub-repo-for-Task](https://github.com/gowtham014/41-pre-test.git)

Directory structure of repository is as follows 
├── Dockerfile
├── README.md
├── app
├── docker-compose.yaml
└── terraform


## Task-1 Dockerizing SimpleTimeService 

- Created a SimpleTimeService node js application which can be found in dir `app`
- This node js script is suitable for both conatiner instance services and AWS lambda(serverless) as well 
- For creating docker image  i have created `Dockerfile` and also to run container locally created `docker-compose.yaml` file which creates docker image and runs the container 
- __Docker Commands__
    ```
    docker build -t <image-name>:tag .
    docker run -d -p 3000:3000 <image-name>:tag     
    ```
- __Docker Compose Commands__
    ```
    docker compose up -d 
    docker compoose down --rmi all (removes all images and volumes as well)
    ```
- __SAMPLE DOCKER IMAGES__
  - I have already created  docker images and pushed to public repo, the sample images are 
    ```
     1. gowtham014/ip-service-app:1.0.0
     2. gowtham014/ip-service-app:2.0.0
    ```

## Task-2 CREATION of infrastructure Using terraform
- I have created terraform scripts and are pushed to director `terraform`
- This script has optional creation of resource in AWS cloud, the options are as follows 
1. __Only ECS__ : This option creates resources which are helpful to expose service from ECS cluster, The resources are as follows
    -  VPC
    - Public and Private Subnets 
    -  ECS CLUSTER, ECS TASK, ECS FARGATE
    -  ALB 
 - Commands for creating ECS only infra 
  ```terraform
    var.deploy_lambda=false
    var.deploy_ecs=true # this variable should be define 
    # Sample variables can be found in ecs.tfvars
    terraform plan --var-file ecs.tfvars
    terraform apply --var-file ecs.tfvars
    terraform destroy --var-file ecs.tfvars
  ```
2.  __Only Lambda__ : This option createas only lambda and API gateway related services, The resources are as follows 
    - Lambda function and Lambda Basic role 
    - Api Gateway, Api route and Deploy 
    - Roles  to access Lambda 
   - Commands for creating ECS only infra 
  ```terraform
    var.deploy_lambda=true
    var.deploy_ecs=false
    # Sample variables can be found in ecs.tfvars
    terraform plan --var-file lambda.tfvars
    terraform apply --var-file lambda.tfvars
    terraform destroy --var-file lambba.tfvars
  ```
3. __HYBRID__ : This Option creates Both the resources 
  - This creates both option `1 and 2`
  - Commands for creating ECS only infra 
   ```terraform
    var.deploy_lambda=true
    var.deploy_ecs=true
    # Sample variables can be found in ecs.tfvars
    terraform plan --var-file hybrid.tfvars
    terraform apply --var-file hybrid.tfvars
    terraform destroy --var-file hybrid.tfvars
  ```
