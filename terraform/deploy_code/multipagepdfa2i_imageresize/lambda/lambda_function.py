import io
import os
import boto3
from PIL import Image

s3 = boto3.client('s3')

async def lambda_handler(event, context):
    print(event)
    src_bucket = event.get('bucket')
    id_val = event.get('id')
    image_keys = event.get('image_keys')
    extension = event.get('extension')

    if not src_bucket or not id_val or not image_keys or not extension:
        raise ValueError("Missing required event parameters")

    if image_keys and len(image_keys) == 1 and image_keys[0] == "single_image":
        # Process single image
        key = event.get('key')
        if not key:
            raise ValueError("Missing 'key' for single image processing")
        width = 1000
        height = 1000
        try:
            src_key = key
            # Retrieve the input image from the source S3 bucket
            response = s3.get_object(Bucket=src_bucket, Key=src_key)
            image_bytes = io.BytesIO(response['Body'].read())
            image = Image.open(image_bytes)
            # Resize the input image to fit within the specified dimensions without cropping
            image.thumbnail((width, height))
            resized_buffer = io.BytesIO()
            format_name = extension.upper() if extension.upper() in Image.registered_extensions() else 'PNG'
            image.save(resized_buffer, format=format_name)
            resized_buffer.seek(0)

            # Upload the resized image to the source S3 bucket
            dst_key = f"wip/{id_val}/{image_keys[0]}/0.{extension}"
            s3.put_object(
                Body=resized_buffer,
                Bucket=src_bucket,
                ContentType=f'image/{extension}',  # Adjust content type based on extension
                Key=dst_key
            )
            print("Resized image uploaded successfully.")
            return {
                'statusCode': '301',
                'headers': {
                    'location': f'/{src_bucket}/{dst_key}',  # Adjust if needed
                },
                'body': ''
            }
        except Exception as e:
            print(f"Error: {e}")
            raise Exception("Image resizing and uploading failed.")
    else:
        # Process multiple images (0, 1, etc.)
        width = 1000
        height = 1000
        try:
            upload_promises = []
            for image_key in image_keys:
                src_key = f"wip/{id_val}/{image_key}.png"  # Assuming image format is PNG, adjust as needed
                # Retrieve the input image from the source S3 bucket
                response = s3.get_object(Bucket=src_bucket, Key=src_key)
                image_buffer = io.BytesIO(response['Body'].read())
                image = Image.open(image_buffer)

                # Resize the input image to fit within the specified dimensions without cropping
                image.thumbnail((width, height))
                resized_buffer = io.BytesIO()
                image.save(resized_buffer, format='PNG')  # Adjust output format if needed
                resized_buffer.seek(0)
                # Upload the resized image to the source S3 bucket
                dst_key = src_key
                upload_promise = s3.put_object(
                    Body=resized_buffer,
                    Bucket=src_bucket,
                    ContentType='image/png',  # Adjust content type based on image format
                    Key=dst_key
                )
                upload_promises.append(upload_promise)
            # Wait for all uploads to complete (in Python, put_object is synchronous in this context, so no need for Promise.all equivalent)
            print("Resized images uploaded successfully.")
            return {
                'statusCode': '301',
                'headers': {
                    'location': f'/{src_bucket}/wip/{id_val}',  # Adjust if needed
                },
                'body': ''
            }
        except Exception as e:
            print(f"Error: {e}")
            raise Exception("Image resizing and uploading failed.")