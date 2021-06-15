import boto3
import os
import json


def handler(event, context):
    queue_arn = os.environ['QUEUE_ARN']
    event_name = event['Records'][0]['eventName']
    print(event)

    boto3.resource('dynamodb')
    deserializer = boto3.dynamodb.types.TypeDeserializer()

    if event_name == 'INSERT':
        sqs = boto3.resource('sqs')

        keys = {
            k: deserializer.deserialize(v) for k, v in event['Records'][0]['dynamodb']['Keys'].items()
        }

        queue = sqs.get_queue_by_name(
            QueueName=queue_arn.split(':')[-1]
        )

        response = queue.send_message(
            MessageBody=json.dumps(keys, ensure_ascii=False),
            DelaySeconds=10,
        )

        print(response)

        return

    if event_name == 'REMOVE':
        record = {
            k: deserializer.deserialize(v) for k, v in event['Records'][0]['dynamodb']['OldImage'].items()
        }

        import requests
        from requests_aws4auth import AWS4Auth

        aws = boto3.session.Session()
        session = requests.Session()
        credentials = aws.get_credentials().get_frozen_credentials()
        session.auth = AWS4Auth(
            credentials.access_key,
            credentials.secret_key,
            aws.region_name,
            'appsync',
            session_token=credentials.token
        )
        session.headers = {
            'Content-Type': 'application/graphql',
        }

        mutation = """
            mutation batchRelease($messages: [String]) {
                batchRelease(criteria: "batch" messages: $messages) {
                    criteria
                    messages
                }
            }
        """

        response = session.request(
            url=os.environ['APPSYNC_URL'],
            method='POST',
            json={'query': mutation, 'variables': record}
        )

        print(response.text)
