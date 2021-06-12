import boto3
import os
import json


def handler(event, context):
    queue_arn = os.environ['QUEUE_ARN']
    event_name = event['Records'][0]['eventName']
    print(event)

    deserializer = boto3.dynamodb.types.TypeDeserializer()

    if event_name == 'INSERT':
        boto3.resource('dynamodb')
        sqs = boto3.resource('sqs')

        keys = {
            k: deserializer.deserialize(v) for k, v in event['Records'][0]['dynamodb']['Keys'].items()
        }

        queue = sqs.get_queue_by_name(
            QueueName=queue_arn.split(':')[-1]
        )

        response = queue.send_message(
            MessageBody=json.dumps(keys, ensure_ascii=False),
            DelaySeconds=30,
        )

        print(response)

        return

    if event_name == 'REMOVE':
        record = {
            k: deserializer.deserialize(v) for k, v in event['Records'][0]['dynamodb']['OldImage'].items()
        }

        print(record)
