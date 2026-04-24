import json
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Images_TF')

def lambda_handler(event, context):
    try:
        image_name = "sample-image.jpg"
        image_url = "https://httpbin.org/image/jpeg"

        table.put_item(
            Item={
                'image_name': image_name,
                'image_url': image_url
            }
        )

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Image data stored in DynamoDB",
                "image_name": image_name,
                "image_url": image_url
            })
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps(f"Unexpected error: {str(e)}")
        }