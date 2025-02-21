FROM public.ecr.aws/amazonlinux/amazonlinux:2023

# Install zip
RUN dnf install -y zip nodejs

# Set working directory
WORKDIR /layer

# Create nodejs directory
RUN mkdir -p nodejs

# Set working directory to nodejs
WORKDIR /layer/nodejs

# Initialize package.json
RUN npm init -y

# Install sharp with specific settings for AWS Lambda
RUN npm install --arch=x64 --platform=linux --target=20.9.0 sharp

# Clean up unnecessary files to reduce layer size
RUN rm -rf node_modules/sharp/vendor/ \
    node_modules/sharp/docs/ \
    node_modules/sharp/src/ \
    node_modules/sharp/.github/

# Go back to layer directory
WORKDIR /layer

# Create zip file
RUN zip -r sharp-layer.zip nodejs/