'use strict';
const { S3 } = require('@aws-sdk/client-s3');
const Sharp = require('sharp');
const s3 = new S3();
exports.handler = async (event, context) => {
  console.log(event);
  const srcBucket = event.bucket;
  const id = event.id;
  const imageKeys = Array.isArray(event.image_keys) ? event.image_keys : [];
  const extension = event.extension;

  if (!srcBucket || !id) {
    throw new Error("Missing required parameters: bucket and id are required");
  }
  if (imageKeys && imageKeys.length === 1 && imageKeys[0] === "single_image") {
    // Process single image
    const key = event.key;
    const width = 1000;
    const height = 1000;
    try {
      const srcKey = key;
      // Retrieve the input image from the source S3 bucket
      const response = await s3.getObject({ Bucket: srcBucket, Key: srcKey });
      const imageBuffer = await streamToBuffer(response.Body);
      // Resize the input image to fit within the specified dimensions without cropping
      const resizedBuffer = await Sharp(imageBuffer)
        .resize({ width, height, fit: 'inside' })
        .toFormat(extension) // Adjust output format based on extension
        .toBuffer();
      // Upload the resized image to the source S3 bucket
      const dstKey = `wip/${id}/${imageKeys[0]}/0.${extension}`;
      await s3.putObject({
        Body: resizedBuffer,
        Bucket: srcBucket,
        ContentType: `image/${extension}`, // Adjust content type based on extension
        Key: dstKey,
      });
      console.log("Resized image uploaded successfully.");
      return {
        pages: [{
          id: id,
          bucket: srcBucket,
          key: event.key,
          wip_key: `wip/${id}/${imageKeys[0]}/0.${extension}`
        }]
      };
    } catch (error) {
      console.error("Error:", error);
      throw new Error("Image resizing and uploading failed.");
    }
  } else {
    // Process multiple images (0, 1, etc.)
    
    const width = 1000;
    const height = 1000;
    try {
      const uploadPromises = [];
      for (const imageKey of imageKeys) {
        const srcKey = `wip/${id}/${imageKey}.png`; // Assuming image format is PNG, adjust as needed
        // Retrieve the input image from the source S3 bucket
        const response = await s3.getObject({ Bucket: srcBucket, Key: srcKey });
        const imageBuffer = await streamToBuffer(response.Body);
        // Resize the input image to fit within the specified dimensions without cropping
        const resizedBuffer = await Sharp(imageBuffer)
          .resize({ width, height, fit: 'inside' })
          .toFormat('png') // Adjust output format if needed
          .toBuffer();
        // Upload the resized image to the source S3 bucket
        const dstKey = srcKey;
        const uploadPromise = s3.putObject({
          Body: resizedBuffer,
          Bucket: srcBucket,
          ContentType: 'image/png', // Adjust content type based on image format
          Key: dstKey,
        });
        uploadPromises.push(uploadPromise);
      }
      // Wait for all uploads to complete
      await Promise.all(uploadPromises);
      console.log("Resized images uploaded successfully.");
      return {
        pages: imageKeys.map((imageKey, index) => ({
          id: id,
          bucket: srcBucket,
          key: event.key,
          wip_key: `wip/${id}/${imageKey}.png`
        }))
      };
    } catch (error) {
      console.error("Error:", error);
      throw new Error("Image resizing and uploading failed.");
    }
  }
};
async function streamToBuffer(stream) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    stream.on('data', (chunk) => chunks.push(chunk));
    stream.on('end', () => resolve(Buffer.concat(chunks)));
    stream.on('error', (err) => reject(err));
  });
}









