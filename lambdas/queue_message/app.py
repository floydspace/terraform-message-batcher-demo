import boto3
import os
import json


def handler(event, context):
    print(event)

    payload = json.loads(event['Records'][0]['body'])
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(os.environ['TABLE_NAME'])
    response = table.delete_item(Key=payload)

    print(response)
