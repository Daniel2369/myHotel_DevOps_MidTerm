# 🏨 Hotel Room Management System

A simple hotel room management system built with **FastAPI** and **Jinja2** templates, 
Designed to demonstrate:
* ![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)
  Operations
* room assignments 
* guest check-in/check-out functionalities
All in a clean HTML UI.

## Owners:
   * Daniel Briliant
   * Idan Less
   * Finish date: 25/11/2025

## Deployment
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-844FBA?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)
* AWS HA using:
  * Application load balancer
  * Auto scaler
  * Launch template
* Terraform IaaC
* Kubernetes cluster for docker ochestration
* Helm for applicaiton deployment in K8s
* Ansible for Linux playbooks automations deployment of:
  * K8s cluster 3 nodes
  * NFS server and client with shared mount to host JSON DB
  * Helm chart deployment
* GitHub Secrets & Actions CI/CD
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
│   └── install-k8s-cluster.yml # Kubernetes cluster
|   --- install-nfs-server.yml # NFS server and client
|   --- site.yml # Helm chart deployment
|-- Helm charts/
|-- Chart.yaml
|-- values.yaml
|-- |-- templates/
|   |   |-- |-- configmap.yaml
|   |   |-- |-- deployment.yaml
|   |   |-- |-- nfs-server.yaml
|   |   |-- |-- pv.yaml
|   |   |-- |-- pvc.yaml
|   |   |-- |-- service.yaml
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
|   |   |-- |-- scp_helm_charts.sh
|   |   |-- |-- setup-tf-backend.sh
|   |   |-- |-- docker_image_push.sh
|   |   |-- |-- update-inventory.sh
│   │   │   ├── generate-ansible-vars.sh
│   │   │   ├── scp_data.sh
│   │   │   ├── destroy-infra.sh
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

## Automatic workflow
   * Any change to code will trigger GitActions workflow

## Manual Steps
 ```bash
    1. Create the Docker image locally:
       * docker buildx build --platform linux/amd64 -t myhotel:latest .
    2. Copy AWS creds inside ~/.aws/credentials
    3. Create the DynamoDB lock table (bootstrap):
       a. cd terraform/dynamoDB
       b. terraform init
       c. terraform apply -auto-approve
       This creates terraform-locks. Confirm the output shows the table name.
    4. Run /Terraform/main/scripts/setup-tf-backend.sh
       a. Validate the following output is printed: DynamoDB table 'terraform-locks' already exists.
                                                    Terraform backend resources are ready.
       b. If there is a failure due to a taken S3 bucket name then change the name inside the following files and re-run the script:
          * terraform/main/backend.tf
          * terraform/main/setup-tf-backend.sh
    5. Apply Terraform infra:
       Pre-setup: Configure in the ternminal the following variables:
                  export DOCKERHUB_USERNAME="your_username"
                  export DOCKERHUB_TOKEN="your_token"
                  Values will be in the moodle.
                  Validation: echo $DOCKERHUB_USERNAME
                              echo $DOCKERHUB_TOKEN
                  Run terraform/main/docker_push_script.sh
       a. cd /myHotel_DevOps_MidTerm/terraform/main
       b. terraform init -reconfigure
       c. terraform plan -out plan
       d. terraform apply plan
    6. Generate ansible_vars.json:
       a. ./scripts/generate-ansible-vars.sh
       b. ./scripts/update-inventory.sh
    7. Copy files to the Ansible server
       Note: Copy the certificate from the AWS lab's UI and copy it into the project directory .pem file and save
       a. ./scripts/scp_data.sh
       b. ./scripts/scp_helm_charts.sh
    8. Ansible part:
       ssh -i /terraform/main/labsuser.pem ubuntu@<ANSIBLE_IP>

        Inside the server:
        sudo su - # switch to root user
        # confirm files are present in /home/ubuntu
        ls -la

         cat <<EOF > /home/ubuntu/.aws/credentials
         [default]
         aws_access_key_id     = $(jq -r '.aws_access_key_id' /home/ubuntu/ansible_vars.json)
         aws_secret_access_key = $(jq -r '.aws_secret_access_key' /home/ubuntu/ansible_vars.json)
         aws_session_token     = $(jq -r '.aws_session_token' /home/ubuntu/ansible_vars.json)
         EOF

        cat /home/ubuntu/.aws/credentials # verify
        
        # Install K8s cluster:
        ansible-playbook -i inventory.ini install-k8s-cluster.yml --extra-vars "@ansible_vars.json" --private-key ./labsuser.pem -u ubuntu
         * After finish check VERIFY_K8S.md for tests of the control plane.

       # Install NFS server and client:
         ansible-playbook -i inventory.ini install-nfs-server.yml

       # Install Helm and deploy chart and application:
         ansible-playbook -i inventory.ini site.yaml

       

    9. Check in AWS console EC2 → Target group machine health
    10. Load balancer → Take ELB domain and run in HostOS’s browser check the application is loaded.
   ```
