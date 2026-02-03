import boto3 # AWS tool-kit SDK
import json # Data to json
import urllib.parse # fix some strange url
from datetime import datetime

s3 = boto3.client('s3')
textract = boto3.client('textract', region_name = 'us-east-1')
dynamodb = boto3.resource('dynamodb', region_name='ap-northeast-1')

TABLE_NAME = 'Receipts'
table = dynamodb.Table(TABLE_NAME)

receipt_data = {
            "vendor_name": "unknown",
            "date": "unknown",
            "total": "unknown"
        }

def handler(event, context): # Get bucket-name and file-name from s3-bucket
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'])

    # key structure: users/{user_id}/receipts/{receipt_id}.{extention}
    # ex:      users/abc-123/receipts/receipt-20260131-001.jpg
    try:
        key_parts = key.split('/')
        # key_parts = ['users', 'abc-123', 'receipts', 'receipt-20260131-001.jpg']
        user_id = key_parts[1]
        # Remove extention
        filename = key_parts[3]
        receipt_id = filename.rsplit('.', 1)[0]  # split「.」and remove extention
    except (IndexError, ValueError):
        print(f"Error: S3 key is something strange: {key}")
        raise

    try: # Analyze receipt in with Textract
        s3_object = s3.get_object(Bucket=bucket, Key=key)
        image_content = s3_object['Body'].read()

        # 3. Send not "S3Object" but "Bytes"
        response = textract.analyze_expense(
            Document={
                'Bytes': image_content
            }
        )

        # Export result from analyze
        for expense_doc in response['ExpenseDocuments']:
            # SummaryFields include "Vendor-Name", "Date", "Total"
            for field in expense_doc['SummaryFields']:
                field_type = field['Type']['Text']
                field_value = field['ValueDetection']['Text']
                        
                if field_type == 'VENDOR_NAME':
                    receipt_data["vendor_name"] = field_value
                elif field_type == 'DATE':
                    receipt_data["date"] = field_value
                elif field_type == 'TOTAL':
                    receipt_data["total"] = field_value

        print(f"Result")
        print(f"Total: {receipt_data['total']}")

        save_to_dynamodb(user_id, receipt_id, receipt_data, key)

        return{
            'StatusCode': 200,
            'body': json.dumps('Analysis successful')
        }
    
    except Exception as e:
        print(f"Error:{str(e)}")
        raise e
    
def save_to_dynamodb(user_id, receipt_id, receipt_data, s3_key):
    try:
        item = {
            'user_id': user_id,
            'receipt_id': receipt_id,
            'vendor_name': receipt_data['vendor_name'],
            'date': receipt_data['date'],
            'total': receipt_data['total'],
            's3_key': s3_key,
            'created_at': datetime.now().strftime('%Y-%m-%dT%H:%M:%S')
        }

        table.put_item(Item=item)
        print(f"Well done to write DynamoDB: user_id={user_id}, receipt_id={receipt_id}")

    except Exception as e:
        print(f"Error for writing to DynamoDB: {str(e)}")
        raise e