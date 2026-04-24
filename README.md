# Task 2 - AWS Serverless Image Processing System

##  Overview

This project is an event-driven serverless application that automatically processes images using AWS services. It enables image upload, triggers processing, stores metadata, and provides access through APIs.

##  Key Features

* Upload images via API
* Automatic image processing using AWS Lambda
* Store image metadata in DynamoDB
* Event-driven workflow using S3 triggers
* REST API exposure using API Gateway
* Scalable and serverless architecture

##  Architecture

API Gateway → Lambda (Ingest) → S3 → Lambda (Process) → DynamoDB

## AWS Services Used

* API Gateway
* AWS Lambda
* Amazon S3
* DynamoDB
* IAM


## Workflow

1. User uploads image via API Gateway
2. Lambda function stores image in S3
3. S3 triggers another Lambda function
4. Image is processed (resize/metadata extraction)
5. Data is stored in DynamoDB
6. API can be used to retrieve image details


## APIs

* POST /upload → Upload image
* GET /images → Get all images
* GET /images/{id} → Get specific image

## Infrastructure

* Infrastructure as Code using Terraform
* IAM roles for secure access
* Event-driven triggers configured

## Output

* Processed images stored in S3
* Metadata stored in DynamoDB

## Use Cases

* Image hosting platforms
* Media processing pipelines
* Automated content systems



