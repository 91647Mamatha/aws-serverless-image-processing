import json
import boto3
import urllib.request
import os

s3 = boto3.client('s3')
BUCKET_NAME = "image-storage-tf-12345"

def lambda_handler(event, context):
    results = []

    for record in event['Records']:
        image_name = None
        try:
            if record['eventName'] != 'INSERT':
                continue

            new_image = record['dynamodb']['NewImage']
            image_name = new_image['image_name']['S']
            image_url = new_image['image_url']['S']

            print(f"Processing: {image_name} from {image_url}")

            # Download with headers
            req = urllib.request.Request(
                image_url,
                headers={'User-Agent': 'Mozilla/5.0'}
            )
            tmp_path = f"/tmp/{image_name}"
            with urllib.request.urlopen(req) as response:
                with open(tmp_path, 'wb') as f:
                    f.write(response.read())

            print(f"Downloaded: {image_name}")

            s3.upload_file(tmp_path, BUCKET_NAME, image_name)
            print(f"Uploaded to S3: {image_name}")

            os.remove(tmp_path)
            results.append({"image_name": image_name, "status": "success"})

        except Exception as e:
            print(f"Error: {str(e)}")
            results.append({"image_name": image_name, "status": "failed", "error": str(e)})

    return {
        "statusCode": 200,
        "body": json.dumps(results)
    }