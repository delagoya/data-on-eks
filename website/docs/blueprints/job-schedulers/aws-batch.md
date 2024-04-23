---
title: AWS Batch on EKS
sidebar_position: 5
---

# AWS Batch on EKS
AWS Batch is a fully managed batch computing service that plans, schedules, and runs your containerized batch machine-learning, simulation, and analytics workloads on top of AWS managed container orchestrations services like Amazon Elastic Kubernetes Service (EKS). AWS Batch adds the necessary operational semantics and resources for batch and high performance compute workloads so that they run efficiently and cost-effectively on your EKS clusters.

Specifically, Batch provides an always-on job queue to accept work requests. You define your jobs using AWS Batch job definitions resources, then submit them to the job queue. Batch then takes care of provisioning nodes for your EKS cluster in a Batch-specific namespace and places pods on these instances to run your workloads. 

The example demonstrates how to use to run a simple "hello world!" job on an Amazon EKS cluster. The code is located at the [Code repo](https://github.com/awslabs/data-on-eks/tree/main/schedulers/terraform/aws-batch) for this example.

## Considerations

AWS Batch is meant for offline analytics and data processing tasks, such as reformatting media, training models, or other compute and data intensive tasks. In particular, Batch is tuned for running jobs that are greater than a few minutes long. If your jobs are short (less than a minute), consider packing more work units into a single Batch job request to increase the total runtime of the process.

## Prerequisites


Ensure that you have the following tools installed locally:

1. [aws cli](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
2. [kubectl](https://Kubernetes.io/docs/tasks/tools/)
3. [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

## Deploy

To provision this example:

```bash
git clone https://github.com/awslabs/data-on-eks.git
cd data-on-eks/schedulers/terraform/managed-airflow-mwaa
chmod +x install.sh
./install.sh
```

Enter region at command prompt to continue.

Once done, you will see terraform output like below.

![terraform output](img/terraform-output.png)

The following components are provisioned in your environment:

- A sample VPC, with 2 Private Subnets and 2 Public Subnets
- Internet gateway for Public Subnets and NAT Gateway for Private Subnets
- EKS Cluster Control plane with one managed node group
- EKS Managed Add-ons: VPC_CNI, CoreDNS, EBS_CSI_Driver
- AWS Batch compute environment attached to the EKS cluster
- AWS Batch job queue attached to the compute environment
- An example Batch job definition to run `echo "hello world!"`


## Validate

## Run an example job on your EKS cluster using AWS Batch

The following command will update the `kubeconfig` on your local machine and allow you to interact with your EKS Cluster using `kubectl` to validate the deployment.
### Run `update-kubeconfig` command

Run the command below.  You may also copy the command from the terraform output 'configure_kubectl'.
```bash
aws eks --region us-west-2 update-kubeconfig --name managed-airflow-mwaa
```

### List the nodes

```bash
kubectl get nodes

# Output should look like below
NAME                         STATUS   ROLES    AGE     VERSION
ip-10-0-0-42.ec2.internal    Ready    <none>   5h15m   v1.26.4-eks-0a21954
ip-10-0-22-71.ec2.internal   Ready    <none>   5h15m   v1.26.4-eks-0a21954
ip-10-0-44-63.ec2.internal   Ready    <none>   5h15m   v1.26.4-eks-0a21954
```

### List the namespaces in EKS cluster

```bash
kubectl get ns

# Output should look like below
default           Active   4h38m
aws-batch          Active   4h34m
kube-node-lease   Active   4h39m
kube-public       Active   4h39m
kube-system       Active   4h39m
```

The namespace `aws-batch` will be used by Batch to add Batch-managed EC2 instances for nodes and run jobs on these nodes.

## Cleaning up

To clean up your environment&mdash;remove all AWS Batch resources and kubernetes constructs from your cluster&mdash;run the `cleanup.sh` script.

```bash
chmod +x cleanup.sh
./cleanup.sh
```
