import boto3
import os
import datetime

s3 = boto3.client('s3')

def lambda_handler(event, context):
    bucket = event['Records'][0]['s3']['bucket']['name']
    input_key = event['Records'][0]['s3']['object']['key']

    if not input_key.endswith('.txt'):
        return {'status': 'skipped'}

    input_obj = s3.get_object(Bucket=bucket, Key=input_key)
    input_data = input_obj['Body'].read().decode('utf-8')
    word_count = len(input_data.split())

    now = datetime.datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')
    output_line = f"{now} - {input_key}: {word_count} words\n"

    output_key = 'count/count.txt'

    try:
        existing_obj = s3.get_object(Bucket=bucket, Key=output_key)
        existing_data = existing_obj['Body'].read().decode('utf-8')
    except s3.exceptions.NoSuchKey:
        existing_data = ""

    updated_data = existing_data + output_line

    s3.put_object(
        Bucket=bucket,
        Key=output_key,
        Body=updated_data.encode('utf-8')
    )

    return {
        'status': 'success',
        'file_processed': input_key,
        'word_count': word_count
    }
