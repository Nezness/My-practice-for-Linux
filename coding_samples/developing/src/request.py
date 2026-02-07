import boto3
import json
import uuid
import os
from botocore.client import Config

s3 = boto3.client('s3', region_name = 'ap-northeast-1', endpoint_url = 'https://s3.ap-northeast-1.amazonaws.com', config = Config(signature_version = 's3v4'))
BUCKET_NAME = os.environ['BUCKET_NAME']

def handler(event, context):
    try:
        query_params = event.get('queryStringParameters', {}) or {}
        user_id = query_params.get('userId', 'demo-user') # You create cognito-authorization, then exchange 'demo-user' for 'userid' got from token coginito issued

        content_type = query_params.get('content_type', 'image/jpeg')
        extension = '.png' if 'png' in content_type else '.jpg'

        file_name = f"{uuid.uuid4()}{extension}"
        object_key = f"users/{user_id}/receipts/{file_name}"

        presigned_url = s3.generate_presigned_url (
            'put_object',
            Params = {
                'Bucket': BUCKET_NAME,
                'Key': object_key,
                'ContentType': content_type
            },
            ExpiresIn = 300
        )

        return {
            'statusCode': 200,
            'headers': {"Content-Type": "application/json"},
            'body': json.dumps({
                'uploadUrl': presigned_url,
                'key': object_key,
                'fileName': file_name
            })
        }
    
    except Exception as e:
        print(e)
        return{
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }