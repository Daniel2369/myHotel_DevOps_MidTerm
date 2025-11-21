#!/usr/bin/env bash
# Generate ansible_vars.json from terraform outputs and AWS credentials
# Can be run from terraform/main or terraform/main/scripts directories
set -euo pipefail

# Determine script directory and terraform root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# If script is in scripts/ subdirectory, terraform root is parent directory
# Otherwise, assume we're already in terraform root
if [[ "$SCRIPT_DIR" == */scripts ]]; then
  TF_ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
else
  TF_ROOT_DIR="$SCRIPT_DIR"
fi

OUT_JSON="$TF_ROOT_DIR/ansible_vars.json"
AWS_CREDENTIALS_FILE="${HOME}/.aws/credentials"

# Change to terraform root directory for terraform commands
cd "$TF_ROOT_DIR"

if ! command -v terraform >/dev/null 2>&1; then
  echo "Error: terraform is required"
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required. Install it with: brew install jq (macOS) or apt-get install jq (Linux)"
  exit 1
fi

# Get outputs as json
echo "Fetching Terraform outputs from $(pwd)..."
TF_OUT=$(terraform output -json 2>/dev/null || {
  echo "Error: Failed to get terraform outputs. Make sure you're in the terraform directory and terraform apply has completed."
  exit 1
})

# Extract values from terraform outputs
ALB_URL=$(echo "$TF_OUT" | jq -r '.alb_asg_url.value // empty')
ANSIBLE_SERVER_EIP=$(echo "$TF_OUT" | jq -r '.ansible_server_eip.value // empty')
ASG_IDS=$(echo "$TF_OUT" | jq -r '.asg_instance_ids.value // []')

# Function to read AWS credentials from ~/.aws/credentials file
read_aws_credentials() {
  local creds_file="$1"
  local access_key=""
  local secret_key=""
  local session_token=""
  local in_default=false

  if [[ ! -f "$creds_file" ]]; then
    echo "Warning: AWS credentials file not found at $creds_file"
    return 1
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    # Trim whitespace
    line=$(echo "$line" | xargs)
    
    # Skip empty lines and comments
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^#.* ]] && continue
    
    # Check if we're in [default] section
    if [[ "$line" =~ ^\[default\]$ ]]; then
      in_default=true
      continue
    fi
    
    # If we hit another section header, stop reading
    if [[ "$line" =~ ^\[.*\]$ ]]; then
      in_default=false
      continue
    fi
    
    # Parse credentials if in [default] section
    if [[ "$in_default" == true ]]; then
      if [[ "$line" =~ ^aws_access_key_id[[:space:]]*=[[:space:]]*(.+)$ ]]; then
        access_key="${BASH_REMATCH[1]}"
        # Remove quotes if present
        access_key=$(echo "$access_key" | sed 's/^["'\'']*//;s/["'\'']*$//')
      elif [[ "$line" =~ ^aws_secret_access_key[[:space:]]*=[[:space:]]*(.+)$ ]]; then
        secret_key="${BASH_REMATCH[1]}"
        # Remove quotes if present
        secret_key=$(echo "$secret_key" | sed 's/^["'\'']*//;s/["'\'']*$//')
      elif [[ "$line" =~ ^aws_session_token[[:space:]]*=[[:space:]]*(.+)$ ]]; then
        session_token="${BASH_REMATCH[1]}"
        # Remove quotes if present
        session_token=$(echo "$session_token" | sed 's/^["'\'']*//;s/["'\'']*$//')
      fi
    fi
  done < "$creds_file"

  if [[ -z "$access_key" ]] || [[ -z "$secret_key" ]]; then
    echo "Warning: Could not find aws_access_key_id or aws_secret_access_key in [default] section of $creds_file"
    return 1
  fi

  echo "$access_key|$secret_key|${session_token:-}"
  return 0
}

# Read AWS credentials from file
echo "Reading AWS credentials from $AWS_CREDENTIALS_FILE..."
CREDS_OUTPUT=$(read_aws_credentials "$AWS_CREDENTIALS_FILE" || echo "")
if [[ -n "$CREDS_OUTPUT" ]]; then
  IFS='|' read -r AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN <<< "$CREDS_OUTPUT"
else
  AWS_ACCESS_KEY_ID=""
  AWS_SECRET_ACCESS_KEY=""
  AWS_SESSION_TOKEN=""
fi

# Validate ALB URL exists
if [[ -z "$ALB_URL" ]] || [[ "$ALB_URL" == "null" ]] || [[ "$ALB_URL" == "empty" ]]; then
  echo "Warning: ALB URL not found in Terraform outputs. Make sure terraform apply has completed."
  ALB_URL=""
fi

# Validate EIP exists
if [[ -z "$ANSIBLE_SERVER_EIP" ]] || [[ "$ANSIBLE_SERVER_EIP" == "null" ]] || [[ "$ANSIBLE_SERVER_EIP" == "empty" ]]; then
  echo "Warning: Ansible server EIP not found in Terraform outputs."
  ANSIBLE_SERVER_EIP=""
fi

# Escape JSON special characters in values
escape_json() {
  local str="$1"
  str="${str//\\/\\\\}"  # Backslash
  str="${str//\"/\\\"}"  # Double quote
  str="${str//$'\n'/\\n}"  # Newline
  str="${str//$'\r'/\\r}"  # Carriage return
  str="${str//$'\t'/\\t}"  # Tab
  echo "$str"
}

ALB_URL_ESCAPED=$(escape_json "$ALB_URL")
ANSIBLE_SERVER_EIP_ESCAPED=$(escape_json "$ANSIBLE_SERVER_EIP")
AWS_ACCESS_KEY_ID_ESCAPED=$(escape_json "$AWS_ACCESS_KEY_ID")
AWS_SECRET_ACCESS_KEY_ESCAPED=$(escape_json "$AWS_SECRET_ACCESS_KEY")
AWS_SESSION_TOKEN_ESCAPED=$(escape_json "$AWS_SESSION_TOKEN")

# Generate the JSON file
cat > "$OUT_JSON" <<EOF
{
  "alb_asg_url": "${ALB_URL_ESCAPED}",
  "ansible_server_eip": "${ANSIBLE_SERVER_EIP_ESCAPED}",
  "aws_access_key_id": "${AWS_ACCESS_KEY_ID_ESCAPED}",
  "aws_secret_access_key": "${AWS_SECRET_ACCESS_KEY_ESCAPED}",
  "aws_session_token": "${AWS_SESSION_TOKEN_ESCAPED}"
}
EOF

echo ""
echo "✓ Successfully wrote $OUT_JSON"
echo ""
echo "Generated variables:"
echo "  - ALB URL: ${ALB_URL:-<not set>}"
echo "  - Ansible Server EIP: ${ANSIBLE_SERVER_EIP:-<not set>}"
if [[ -n "$AWS_ACCESS_KEY_ID" ]]; then
  echo "  - AWS Access Key ID: <set>"
else
  echo "  - AWS Access Key ID: <not set>"
fi
if [[ -n "$AWS_SECRET_ACCESS_KEY" ]]; then
  echo "  - AWS Secret Access Key: <set>"
else
  echo "  - AWS Secret Access Key: <not set>"
fi
if [[ -n "$AWS_SESSION_TOKEN" ]]; then
  echo "  - AWS Session Token: <set>"
else
  echo "  - AWS Session Token: <not set>"
fi
