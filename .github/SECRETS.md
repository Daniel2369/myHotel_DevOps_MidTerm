# GitHub Actions Secrets Configuration

This document describes all the secrets that need to be configured in your GitHub repository for the deployment workflow to work.

## Required Secrets

Configure these secrets in your GitHub repository:
**Settings → Secrets and variables → Actions → New repository secret**

### 1. AWS Credentials

#### `AWS_ACCESS_KEY_ID`
- **Description**: AWS access key ID for programmatic access
- **Type**: String
- **Example**: `AKIAIOSFODNN7EXAMPLE`
- **How to get**: AWS Console → IAM → Users → Your User → Security credentials → Create access key

#### `AWS_SECRET_ACCESS_KEY`
- **Description**: AWS secret access key
- **Type**: String (sensitive)
- **Example**: `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`
- **How to get**: Same as above (only shown once during creation)

#### `AWS_SESSION_TOKEN`
- **Description**: AWS session token (required for temporary credentials, e.g., AWS Academy/Labs)
- **Type**: String (sensitive)
- **Example**: `IQoJb3JpZ2luX2VjE...` (long token)
- **How to get**: 
  - If using AWS Academy/Labs: Copy from your AWS credentials file or AWS CLI session
  - If using permanent credentials: Leave empty or set to empty string
- **Note**: For AWS Academy/Labs, this is usually required and expires periodically

### 2. Docker Hub Credentials

#### `DOCKERHUB_USERNAME`
- **Description**: Your Docker Hub username
- **Type**: String
- **Example**: `myusername`
- **How to get**: Your Docker Hub account username

#### `DOCKERHUB_TOKEN`
- **Description**: Docker Hub access token (preferred) or password
- **Type**: String (sensitive)
- **How to get**: 
  - Docker Hub → Account Settings → Security → New Access Token
  - Or use your Docker Hub password (less secure)
- **Note**: Access tokens are recommended over passwords

### 3. SSH Private Key

#### `SSH_PRIVATE_KEY`
- **Description**: Private SSH key (.pem file) for accessing EC2 instances
- **Type**: String (sensitive, multiline)
- **Example**: 
  ```
  -----BEGIN RSA PRIVATE KEY-----
  MIIEpAIBAAKCAQEA...
  ...
  -----END RSA PRIVATE KEY-----
  ```
- **How to get**: 
  - Download from AWS Console → EC2 → Key Pairs
  - Or from your AWS Academy/Labs interface
  - Copy the entire content including `-----BEGIN` and `-----END` lines
- **Important**: 
  - Include the entire key including header and footer
  - Preserve all newlines (GitHub secrets handle multiline correctly)
  - This is the same key file you would use locally (e.g., `labsuser.pem`)

## Optional Configuration

### Environment Variables (can be set in workflow or as secrets)

- `AWS_REGION`: Defaults to `us-east-1` in the workflow
- `TERRAFORM_VERSION`: Defaults to `1.6.0`
- `ANSIBLE_VERSION`: Defaults to `8.0.0`

## How to Add Secrets

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Enter the secret name (exactly as listed above)
5. Paste the secret value
6. Click **Add secret**

## Verification

After adding all secrets, you can verify by:
1. Running the workflow manually (Workflow dispatch)
2. Checking the logs for any authentication errors
3. The workflow should proceed through all steps without credential errors