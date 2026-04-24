AWS Serverless Image Processing System
An event-driven serverless application that ingests image data, processes it automatically, and exposes it through REST APIs using AWS services.

AWS Services Used

API Gateway - REST API endpoints
Lambda - Serverless processing logic
DynamoDB - Image metadata storage
DynamoDB Streams - Event-driven trigger
S3 - Image file storage
IAM - Permissions and roles


How It Works

User calls the POST /image_url API
Lambda fetches image data and stores it in DynamoDB
DynamoDB Stream automatically triggers the Process Lambda
Process Lambda downloads the image and uploads it to S3
User calls GET /get-image API with image name
Lambda returns a pre-signed S3 URL and last modified timestamp

Implementation
Manual Implementation
Resources created manually via AWS Console including S3 bucket, DynamoDB table with Streams enabled, three Lambda functions, and API Gateway routes.
Terraform Implementation
All the same resources automated using Terraform for reproducible deployments. Run terraform apply to create and terraform destroy to clean up.


API Endpoints
POST /image_url
Fetches image data from an external source and stores it in DynamoDB.
GET /get-image
Takes image_name as input and returns a pre-signed S3 URL along with the last modified timestamp.

Key Design Decisions

Pre-signed URLs are used for secure temporary access to the private S3 bucket
DynamoDB Streams enables fully event-driven architecture with no manual polling
Each Lambda has proper error handling with specific error codes
Terraform automates all infrastructure for clean and repeatable deployments

