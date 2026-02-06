import boto3
import json
import urllib.parse
from datetime import datetime
from decimal import Decimal

# ------------------------------------------------------------------
# Clients
# ------------------------------------------------------------------
s3 = boto3.client('s3')
textract = boto3.client('textract', region_name='us-east-1')
bedrock = boto3.client('bedrock-runtime', region_name='ap-northeast-1')
dynamodb = boto3.resource('dynamodb', region_name='ap-northeast-1')

TABLE_NAME = 'Receipts'
table = dynamodb.Table(TABLE_NAME)

# ------------------------------------------------------------------
# Model ID (Claude 3.5 Sonnet)
# ------------------------------------------------------------------
MODEL_ID = "anthropic.claude-3-5-sonnet-20240620-v1:0"

def handler(event, context):
    print("SQS Event received. Processing batch...")
    
    for record in event['Records']:
        try:
            print(f"Processing SQS Message ID: {record['messageId']}")
            
            # SQS message body to json
            body = json.loads(record['body'])
            
            if 'Records' not in body:
                print("Skipping: No S3 Records found in body.")
                continue

            # S3 information
            s3_record = body['Records'][0]
            bucket = s3_record['s3']['bucket']['name']
            key = urllib.parse.unquote_plus(s3_record['s3']['object']['key'])
            
            print(f"Target S3 File: {bucket}/{key}")

            key_parts = key.split('/')
            if len(key_parts) < 4: 
                print(f"Skipping invalid path: {key}")
                continue
                
            user_id = key_parts[1]
            filename = key_parts[3]
            receipt_id = filename.rsplit('.', 1)[0]

            # Get image-Obj from S3
            s3_object = s3.get_object(Bucket=bucket, Key=key)
            image_content = s3_object['Body'].read()

            # to Textract
            print("Step 1: Reading text with Textract...")
            raw_text = get_raw_text_from_textract(image_content)

            # to Bedrock
            print("Step 2: Analyzing with Bedrock (Claude)...")
            receipt_data = invoke_bedrock_analysis(raw_text)
            print(f"Bedrock Result: {receipt_data}")

            # Write to DynamoDB
            save_to_dynamodb(user_id, receipt_id, receipt_data, key)
            
            print(f"Successfully processed: {key}")

        except Exception as e:
            print(f"ERROR: {str(e)}")
            import traceback
            traceback.print_exc()
            # raise e

# ------------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------------

def get_raw_text_from_textract(image_bytes):
    """Textractを使って画像内の全テキストを1つの文字列にする"""
    response = textract.detect_document_text(Document={'Bytes': image_bytes})
    lines = []
    for block in response['Blocks']:
        if block['BlockType'] == 'LINE':
            lines.append(block['Text'])
    return "\n".join(lines)

def invoke_bedrock_analysis(raw_text):
    """Claudeにテキストを投げてJSONで受け取る"""
    
    # プロンプト：OCRの誤読(At=合計)やノイズを補正する指示を含める
    prompt = f"""
    あなたは優秀な経理アシスタントです。
    以下のテキストは、レシートをOCRで読み取った結果です。ノイズや誤字(例:「合計」が「At」と誤認識される等)が含まれています。
    文脈を読み解き、以下の情報を抽出してJSON形式のみを出力してください。
    
    【抽出ルール】
    - vendor_name: 店名を特定してください。
    - date: 日付を 'YYYY-MM-DD' 形式に修正してください。不明な場合は 'unknown'を出力してください。
    - total: 支払った合計金額（数値のみ）。
      ※注意: 「現金（お預かり）」や「お釣り」ではなく、「請求金額」「合計」を優先してください。
      ※ '130' と '150(現金)' がある場合、文脈から請求額である '130' を選んでください。
      ※店名は、**商店や**ストア、**店、株式会社**となっている傾向があります。できるだけ妥当なものを探し、なければunknownを返してください。

    【OCRテキスト】
    {raw_text}
    
    【出力形式(JSON)】
    {{
        "vendor_name": "店名",
        "date": "YYYY-MM-DD",
        "total": "金額(カンマなし数値文字列)"
    }}
    """

    body = json.dumps({
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 1000,
        "messages": [
            {"role": "user", "content": prompt}
        ]
    })

    response = bedrock.invoke_model(
        modelId=MODEL_ID,
        body=body
    )
    
    response_body = json.loads(response['body'].read())
    result_text = response_body['content'][0]['text']
    
    # JSON部分だけを抽出する（Markdown記法 ```json ... ``` を除去）
    try:
        json_str = result_text.strip()
        if "```json" in json_str:
            json_str = json_str.split("```json")[1].split("```")[0].strip()
        elif "```" in json_str: # 単なるcode blockの場合
            json_str = json_str.split("```")[1].split("```")[0].strip()
            
        return json.loads(json_str)
    except Exception as e:
        print(f"Failed to parse JSON from Bedrock: {result_text}")
        # エラー時はunknownを返す
        return {"vendor_name": "unknown", "date": "unknown", "total": "0"}

def save_to_dynamodb(user_id, receipt_id, data, s3_key):
    """DynamoDB保存"""
    # 数値変換
    try:
        amount_val = Decimal(str(data.get('total', 0)).replace(',', ''))
    except:
        amount_val = Decimal(0)

    item = {
        'user_id': user_id,
        'receipt_id': receipt_id,
        'vendor_name': data.get('vendor_name', 'unknown'),
        'date': data.get('date', 'unknown'),
        'total': str(data.get('total', '0')), # 文字列としての金額
        'total_amount': amount_val,           # 計算用数値
        's3_key': s3_key,
        'created_at': datetime.now().isoformat(),
        'method': 'Bedrock_AI' # AIで処理した証
    }
    table.put_item(Item=item)
    print(f"Saved to DynamoDB: {item}")