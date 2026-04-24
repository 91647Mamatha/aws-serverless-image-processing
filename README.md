AWS Serverless Image Processing System
An event-driven serverless application that ingests image data, processes it automatically, and exposes it through REST APIs using AWS services.

Architecture
API Gateway → Lambda (Ingest) → DynamoDB → DynamoDB Streams → Lambda (Process) → S3  -> API Gateway → Lambda (Get Image)
                            

AWS Services Used
ServicePurposeAPI GatewayREST API endpointsLambdaServerless processing logicDynamoDBImage metadata storageDynamoDB StreamsEvent-driven triggerS3Image file storageIAMPermissions and roles

Components
1. Image Ingestion API (/image_url)

Method: POST
Function: Fetches image data from an external source
Action: Extracts image_name and image_url, stores in DynamoDB

2. Event Listener (DynamoDB → S3)

Trigger: DynamoDB Streams on new record insertion
Function: Downloads image from URL and uploads to S3 using image_name as filename

3. Image Retrieval API (/get-image)

Method: GET
Input: image_name (query parameter)
Response: Pre-signed S3 URL + last modified timestamp


Project Structure
aws-serverless-image-processing/
│
├── manual/
│   ├── lambda_ingest.py       # Image Ingestion Lambda
│   ├── lambda_process.py      # DynamoDB Stream → S3 Lambda
│   └── lambda_get.py          # Image Retrieval Lambda
│
├── terraform/
│   ├── main.tf                # All AWS infrastructure as code
│   ├── lambda_ingest.py       # Ingest Lambda for Terraform
│   ├── lambda_process.py      # Process Lambda for Terraform
│   ├── lambda_get.py          # Get Lambda for Terraform
│   ├── lambda_ingest.zip      # Zipped Lambda package
│   ├── lambda_process.zip     # Zipped Lambda package
│   └── lambda_get.zip         # Zipped Lambda package
│
└── README.md

Implementation
Manual Implementation
Resources created manually via AWS Console:

S3 Bucket: image-storage-bucket-123
DynamoDB Table: Images (with Streams enabled)
Lambda Functions: ImageIngestionLambda, ProcessImageLambda, GetImageLambda
API Gateway: REST API with /image_url and /get-image routes

Terraform Implementation
All resources automated using Terraform:

S3 Bucket: image-storage-tf-12345
DynamoDB Table: Images_TF (with Streams enabled)
Lambda Functions: IngestImageLambdaTF, ProcessImageLambdaTF, GetImageLambdaTF
API Gateway: image-api-tf with /image_url and /get-image routes


Setup Instructions
Prerequisites

AWS Account with appropriate permissions
AWS CLI configured
Terraform installed
Python 3.9+

Manual Setup

Create S3 bucket image-storage-bucket-123
Create DynamoDB table Images with image_name as partition key and Streams enabled
Create 3 Lambda functions with Python 3.9 runtime
Add DynamoDB Stream trigger to ProcessImageLambda
Create API Gateway with /image_url (POST) and /get-image (GET) routes
Deploy API Gateway stage

Terraform Setup

Clone the repository:

bashgit clone https://github.com/91647Mamatha/aws-serverless-image-processing.git
cd aws-serverless-image-processing/terraform

Zip the Lambda functions:

bashzip lambda_ingest.zip lambda_ingest.py
zip lambda_process.zip lambda_process.py
zip lambda_get.zip lambda_get.py

Initialize Terraform:

bashterraform init

Preview changes:

bashterraform plan

Deploy infrastructure:

bashterraform apply

Destroy infrastructure (cleanup):

bashterraform destroy

API Endpoints
POST /image_url
Fetches image data and stores in DynamoDB.
Request:
POST https://<api-id>.execute-api.us-east-1.amazonaws.com/dev/image_url
Response:
json{
  "message": "Image data stored in DynamoDB",
  "image_name": "sample-image.jpg",
  "image_url": "https://example.com/image.jpg"
}

GET /get-image
Retrieves image URL and metadata from S3.
Request:
GET https://<api-id>.execute-api.us-east-1.amazonaws.com/dev/get-image?image_name=sample-image.jpg
Response:
json{
  "image_url": "https://bucket.s3.amazonaws.com/sample-image.jpg?AWSAccessKeyId=...&Expires=...",
  "last_modified": "2026-04-23 10:53:20+00:00"
}

Event-Driven Flow
1. POST /image_url
        ↓
2. ImageIngestionLambda fetches image data
        ↓
3. Stores image_name + image_url in DynamoDB
        ↓
4. DynamoDB Stream detects new record (INSERT event)
        ↓
5. ProcessImageLambda triggered automatically
        ↓
6. Downloads image from URL → uploads to S3
        ↓
7. GET /get-image?image_name=sample-image.jpg
        ↓
8. GetImageLambda returns pre-signed URL + last_modified

