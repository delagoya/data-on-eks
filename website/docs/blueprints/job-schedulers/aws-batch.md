---
title: AWS Batch on EKS
sidebar_position: 5
---

# AWS Batch on EKS
AWS Batch is a fully managed batch computing service that plans, schedules, and runs your containerized batch machine-learning, simulation, and analytics workloads on top of AWS managed container orchestrations services like Amazon Elastic Kubernetes Service (EKS). AWS Batch adds the necessary operational semantics and resources for batch and high performance compute workloads so that they run efficiently and cost-effectively on your EKS clusters.

Specifically, Batch provides an always-on job queue to accept work requests. You define your jobs using AWS Batch job definitions resources, then submit them to the job queue. Batch then takes care of provisioning nodes for your EKS cluster in a Batch-specific namespace and places pods on these instances to run your workloads. 

## Prerequisites

## Deploy

## Validate

## Run an example job on your EKS cluster using AWS Batch

## Cleaning up

To clean up your environment&mdash;remove all AWS Batch resources and kubernetes constructs from your cluster&mdash;run the `cleanup.sh` script.

```bash
chmod +x cleanup.sh
./cleanup.sh
```
---
