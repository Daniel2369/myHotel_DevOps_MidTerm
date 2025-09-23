# 🏨 Hotel Room Management System

A simple hotel room management system built with **FastAPI** and **Jinja2** templates, 
Designed to demonstrate:
* ![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)
  Operations
* room assignments 
* guest check-in/check-out functionalities
All in a clean HTML UI.

## Deployment
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-844FBA?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)
* AWS HA using:
  * Application load balancer
  * Auto scaler
  * Launch template

---
## 🌟 Project Overview

This system allows hotel staff to:

- 📥 Add new rooms  
- 🧹 Delete rooms  
- 📝 Update room information  
- ✅ Check guests into available rooms  
- ❌ Check guests out of rooms  
- 📊 View all rooms in a color-coded table (vacant or occupied)

Everything is handled through clean, interactive web forms and served via FastAPI.

---

## ✨ Features

### 🔧 Core Functionality

- **Create Room**: Add new rooms with category, cost, and optional guest name.
- **Delete Room**: Remove rooms from the system by room ID.
- **Update Room**: Modify any room's details including cost, guest name, or category.
- **Check-In**: Assign a guest to the first available room of the selected category.
- **Check-Out**: Free up a room and mark it as available again.
- **Room Dashboard**: View a table of all rooms with live status (occupied/vacant), color-coded.

### 💻 Web Interface
- Built using **FastAPI** with **Jinja2 HTML templates**
- CSS styling for forms and tables
- Feedback messages appear after each form action (success/failure)

---

## 📂 Project Structure

```text
# 🏨 Hotel Room Management System

A simple hotel room management system built with **FastAPI** and **Jinja2**, designed to demonstrate:

- ![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white) API operations
- Room assignments and management
- Guest check-in/check-out
- Web UI with form-based interactions

---

## 🚀 Deployment Stack

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-844FBA?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)

**AWS High Availability setup using:**

- Application Load Balancer
- Auto Scaling Group
- Launch Template
- EC2 Instances with Docker
- Terraform-managed infrastructure

---

## 🌟 Features

### 🔧 Core Functionality

- 📥 **Add Room**  
- 🧹 **Delete Room**  
- 📝 **Update Room**  
- ✅ **Guest Check-In**  
- ❌ **Guest Check-Out**  
- 📊 **Room Dashboard** (Vacant/Occupied with color-coding)

### 💻 Web Interface

- Built with **FastAPI + Jinja2 HTML templates**
- CSS-styled forms and tables
- Real-time feedback messages

---

## 📂 Project Structure

```text
myHotel_DevOps_MidTerm/
├── Dockerfile
├── backend.py
├── readme.md
├── ansible/
│   └── ansible-playbook.yml
├── templates/
│   ├── menu.html
│   ├── create_room.html
│   ├── update_room.html
│   ├── delete_room.html
│   ├── check_in.html
│   ├── check_out.html
│   └── rooms.html
├── static/
│   ├── devops_hotel.jpeg
│   ├── favicon.png
│   └── MyHotel AWS Deployment Diagram.drawio.png
├── terraform/
│   ├── bootstrap/
│   │   ├── main.tf
│   │   └── variables.tf
│   ├── dynamoDB/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── README.md
│   ├── main/
│   │   ├── main.tf, outputs.tf, variables.tf
│   │   ├── terraform.tfstate, plan, inventory.ini
│   │   ├── setup-tf-backend.sh, docker_image_push.sh, etc.
│   │   ├── scripts/
│   │   │   ├── generate-ansible-vars.sh
│   │   │   ├── scp_data.sh
│   │   │   ├── destroy-infra.sh
│   │   │   └── setup-tf-backend.sh
│   └── modules/
│       ├── alb_asg/
│       ├── ecr/
│       └── vpc/

```

---

## 🐳 Running with Docker (Local deployment)
      > ⚠️ **Important:** If you want fully automatec AWS deployment skip this part.

### 1. Build the Docker image
- Easily containerized using Docker for consistent deployment
- Run anywhere with one command
  
```bash
docker buildx build --platform linux/amd64 -t hotels:latest . (For MacOS)
docker run -d --name hotels-container -p 8000:8000 hotels:latest
# Inside the host machine run ip a and take the IPv4
# Browse to http://<IPv4>:8000
```

# AWS Deployment
## 🚀 Deploment with Terraform IaaC!!!
![Alt text for the image](https://github.com/Daniel2369/myHotel_DevOps_MidTerm/blob/1c541f51c9a7638f0d2248eb6ae7a264160cbfb2/static/MyHotel%20AWS%20Deployment%20Diagram.drawio.png)

 ```bash
    1. Create S3 bucket manually in AWS console = devops2025-technion-finalcourse-dberliant-bucket
    2. Create the Docker image locally - docker build -t myHotel:latest .
    3. Copy AWS creds inside ~/.aws/credentials
    4. Create the DynamoDB lock table (bootstrap):
       a. cd terraform/dynamoDB
       b. terraform init
       c. terraform apply -auto-approve
       This creates terraform-locks. Confirm the output shows the table name.
    5. Run /Terraform/main/scripts/setup-tf-backend.sh
       a. Validate the following output is printed: DynamoDB table 'terraform-locks' already exists.
                                                    Terraform backend resources are ready.
    6. Apply Terraform infra:
       a. cd /myHotel_DevOps_MidTerm/terraform/main
       b. terraform init -reconfigure
       c. terraform plan -out plan
       d. terraform apply plan
      # If something about ECR fails - update variable ECR_REPO_URL var inside
      # /scripts/docker_image_push.sh
    7. Generate ansible_vars.json (and fill credentials securely): 
       a. ./scripts/generate-ansible-vars.sh
          # then edit ansible_vars.json to add AWS credentials (or put them on the Ansible host)
    8. Copy files to the Ansible server (example): - Download the key from the console and set
       a. mv ~/Downloads/labsuer.pem
       b. chmod 400 labsuser.pem
       c. ./scripts/scp_data.sh $(terraform output -raw ec2_public_ip)
    9. Ansible part:
       ssh -i /path/to/labsuser.pem ubuntu@<ANSIBLE_IP>

        Inside the server:
        sudo su - # switch to root user
        # confirm files are present in /home/ubuntu
        ls -la ~
        
        # Install jq
        sudo apt-get update && sudo apt-get install -y jq
        jq --version # validate
        
        # Set AWS creds using the .json file
        mkdir -p ~/.aws
        cat > ~/.aws/credentials <<EOF
        [default]
        aws_access_key_id = $(jq -r '.aws_access_key_id' ansible_vars.json)
        aws_secret_access_key = $(jq -r '.aws_secret_access_key' ansible_vars.json)
        aws_session_token = $(jq -r '.aws_session_token' ansible_vars.json)
        EOF
        
        chmod 600 ~/.aws/credentials # Set permissions to read the file
        
        # Update inventory.ini file with the private vm's private ip's
        Take the IP's from AWS console and edit the file using vi
        
        # Run playbook
        ansible-playbook -i inventory.ini ansible-playbook.yml --extra-vars "@ansible_vars.json" --private-key ./labsuser.pem -u ubuntu
        
        # Check container runs
        ssh -i labsuser.pem ubuntu@private-ip-vm-1 # can get from inventory.ini
        docker ps
        ssh private-ip-vm-2 
        docker ps

    10. Check in AWS console EC2 → Target group machine health
    11. Load balancer → Take ELB domain and run in HostOS’s browser check the application is loaded.
    12. Delete ECR container manually, Run /scripts/destroy-infra.sh - to clean the environment.
   ```
