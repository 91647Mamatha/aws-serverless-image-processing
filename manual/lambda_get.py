import json
import boto3
from botocore.exceptions import ClientError

s3 = boto3.client('s3')
BUCKET_NAME = "image-storage-bucket-123"

def lambda_handler(event, context):
    try:
        # Fix: queryStringParameters can be None from API Gateway
        params = event.get("queryStringParameters") or {}
        image_name = params.get("image_name")

        if not image_name:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "image_name query parameter is required"})
            }

        # Check if object exists and get metadata
        response = s3.head_object(Bucket=BUCKET_NAME, Key=image_name)

        # Fix: pre-signed URL instead of broken public URL
        presigned_url = s3.generate_presigned_url(
            'get_object',
            Params={'Bucket': BUCKET_NAME, 'Key': image_name},
            ExpiresIn=3600  # valid for 1 hour
        )

        return {
            "statusCode": 200,
            "body": json.dumps({
                "image_url": presigned_url,
                "last_modified": str(response["LastModified"])
            })
        }

    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == '404':
            return {
                "statusCode": 404,
                "body": json.dumps({"error": f"Image '{image_name}' not found in S3"})
            }
        return {
            "statusCode": 500,
            "body": json.dumps({"error": f"AWS error: {str(e)}"})
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": f"Unexpected error: {str(e)}"})
        }