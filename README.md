# HeartCentrix DevOps challenge

​
Choose any technology to create this demo, write down your thoughts that lead you to your decisions

## The problem

Implement an API, build and deploy it to a Kubernetes cluster

We would like to see the following​

* `terraform code` and `plan output` of the resources to be created in AWS. The terraform code should provision:

    * Required: 
        * 1 VPC
        * 2 subnets - public and private
        * Security groups as needed
        * 1 EKS cluster, hosted in the private subnet
        * 1 ECR
    * Extra:
        * Anything else that you think relevant to this infrastructure
* Manifest files or helm charts to handle everything related to the application
* Github workflows to build and deploy the API
​

About creating the Kubernetes cluster to deploy your manifests/helm charts, you have two options
* Deploy it to AWS with Terraform
* Create your local cluster with Minikube/Rancher or any other you prefer

Since there is a cost on provisioning the EKS and storing images at ECR, don't worry about creating them, sending your `terraform file` and your `plan output` is enough.

## The API

Fell free to use any gen-ai to create this API, this API is not the focus of this evaluation, as long as it works it is fine!

The API should return `Hello!` upon being called at `/api/hello`

```

curl -sv localhost:8000/api/hello 

```

## Result

You can check de result, here: http://k8s-default-ingressh-a140dfd61f-904384313.us-east-1.elb.amazonaws.com/api/hello