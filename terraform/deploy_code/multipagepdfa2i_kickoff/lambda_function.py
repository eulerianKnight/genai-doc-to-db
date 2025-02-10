import json
import boto3
import uuid
import os
from datetime import datetime
import logging
from urllib.parse import unquote, unquote_plus

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def datetime_handler(obj):
    if isinstance(obj, (datetime,)):
        return obj.isoformat()
    # For debugging, log the type we're trying to serialize
    logger.info(f"Attempting to serialize object of type: {type(obj)}")
    return str(obj)

def start_step_function(payload):
    client = boto3.client('stepfunctions')
    response = client.start_execution(
        stateMachineArn=os.environ['state_machine_arn'],
        name=payload["id"],
        input=json.dumps(payload, indent=3, default=str),
    )
    return response

def extract_event_data(record):
    s3 = record["s3"]
    id = uuid.uuid4().hex
    bucket = s3["bucket"]["name"]
    key = unquote_plus(unquote(s3["object"]["key"]))
    pdf_name = key[key.rfind("/")+1:key.rfind(".")]
    
    data = {
        "id": id,
        "bucket": bucket,
        "key": key,
        "pdf_name": pdf_name
    }
    
    return data

def lambda_handler(event, context):
    try:
        logger.info(f"Processing event: {json.dumps(event)}")
        
        for record in event["Records"]:
            logger.info(f"Processing SQS record: {json.dumps(record)}")
            
            for cur_record in json.loads(record["body"])["Records"]:
                data = extract_event_data(cur_record)
                extension = data["key"][-3:].lower()
                
                if extension in ["pdf", "png", "jpg"]:
                    payload = {
                        "id": data["id"],
                        "bucket": data["bucket"],
                        "key": data["key"],
                        "extension": extension
                    }
                    response = start_step_function(payload)
                    # Modified logging statement to handle datetime serialization
                    logger.info(f"Started Step Function execution: {json.dumps(response, default=datetime_handler)}")
            
            # Delete processed message from SQS
            client = boto3.client('sqs')
            response = client.delete_message(
                QueueUrl=os.environ['sqs_url'],
                ReceiptHandle=record["receiptHandle"]
            )
            logger.info("Successfully deleted message from SQS")
        
        return {
            "statusCode": 200,
            "body": "Successfully processed all records"
        }
    
    except Exception as e:
        logger.error(f"Error processing records: {str(e)}", exc_info=True)
        return {
            "statusCode": 500,
            "body": f"Error processing records: {str(e)}"
        }