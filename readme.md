# 🏨 Hotel Room Management System
Welcome to the Hotel Room Management System ! This project is a Python-based application designed to manage hotel rooms, track occupancy, and provide room details. It also includes a web interface and containerization using Docker for easy deployment.

# Part 1 - CLI Application

🌟 Project Overview
The Hotel Room Management System is a CLI (Command-Line Interface) application built with Python. It allows users to:

Add, remove, and edit rooms.
Assign guests to rooms and check them out.
View room availability and sort rooms by status or number.
Perform calculations (e.g., count free vs. occupied rooms).
I’ve also added a web-based interface using Streamlit to make the system more user-friendly and accessible via a browser. The application is containerized using Docker for consistent deployment across environments.

✨ Features
Core Functionality
Add Rooms : Add new rooms with custom details (type, price).
Remove Rooms : Remove rooms from the system.
Edit Rooms : Update room details (type, price).
Assign Guests : Assign guests to available rooms.
Check Out : Mark rooms as free when guests check out.
Display Rooms : Show all rooms with their current status (free/occupied).
Sort Rooms : Sort rooms by occupancy status (occupied first) and then by room number.
Room Availability : Display how many rooms are free or occupied, along with their room numbers.



📂 Folder Structure
Below is the folder structure for the project, represented as a tree:

```text
hotel-room-management/
├── python-app/ # Python application files
│ ├── main.py # Main entry point for the CLI app
│ └── functions.py # Reusable functions for room management
```

# Part 2 - Web Application

# 🏨 Hotel Room Management System

A simple hotel room management system built with **FastAPI** and **Jinja2** templates, 
Designed to demonstrate:
* FastAPI operations
* room assignments 
* guest check-in/check-out functionalities
All in a clean HTML UI.

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
hotel-room-management/
├── app/
│   ├── backend.py                 # Main FastAPI application
│   ├── templates/                 # HTML templates for all frontend pages
|   ├── static/                    # Banner image
│   │   ├── menu.html
│   │   ├── create_room.html
│   │   ├── update_room.html
│   │   ├── delete_room.html
│   │   ├── check_in.html
│   │   ├── check_out.html
│   │   └── rooms.html
├── Dockerfile                  # Docker build instructions
├── README.md                   # Project documentation

```

---

## 🐳 Running with Docker

### 1. Build the Docker image
- Easily containerized using Docker for consistent deployment
- Run anywhere with one command
  
```bash
docker buildx build --platform linux/amd64 -t hotels:latest .
docker run -d --name hotels-container -p 8000:8000 hotels:latest
# Inside the host machine run ip a and take the IPv4
# Browse to http://<IPv4>:8000
```

# AWS Deployment
## 🚀 Deploy Docker Web App from ECR to Elastic Beanstalk with:
* Private Subnets,
* NAT Gateway
* Load Balancer

This guide explains how to deploy a Docker-based web application stored in **Amazon ECR** to **Elastic Beanstalk**, using a secure and scalable infrastructure:

- EC2 instances in **private subnets**
- Access to **Amazon ECR**
- NAT Gateway for outbound traffic
- Application Load Balancer for inbound HTTP traffic
- Auto Scaling across 2 Availability Zones

---

## 🧱 Prerequisites

Before starting:

- ✅ AWS account
- ✅ Docker image pushed to [Amazon ECR](https://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-push-ecr-image.html)
- ✅ AWS CLI installed
- ✅ IAM permissions to manage VPC, EC2, ECR, Elastic Beanstalk, and IAM roles

---

## 📦 Step 1: Prepare `Dockerrun.aws.json`

Create a file named `Dockerrun.aws.json` in the root of your project and zip it:

```json
{
  "AWSEBDockerrunVersion": "1",
  "Image": {
    "Name": "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-service:latest", # ECR Repo/image
    "Update": "true"
  },
  "Ports": [
    {
      "ContainerPort": 8000
    }
  ]
}
```

## 🌐 Step 2: Create a Secure VPC Architecture
In the AWS Console, go to the VPC Dashboard and create:

### ✅ 1. VPC
CIDR block: 10.0.0.0/16

Enable DNS hostnames & DNS resolution

### ✅ 2. Subnets
2 Public Subnets (e.g., 10.0.1.0/24 in us-east-1a, 10.0.2.0/24 in us-east-1b)

2 Private Subnets (e.g., 10.0.11.0/24, 10.0.12.0/24)

Tag accordingly (e.g., Name: PublicSubnetA, PrivateSubnetB)

### ✅ 3. Internet Gateway
Attach to the VPC

Update public subnet route table to route 0.0.0.0/0 → IGW

### ✅ 4. NAT Gateway
Allocate Elastic IP

Create NAT Gateway in one public subnet using that Elastic IP

Update private subnet route table to route 0.0.0.0/0 → NAT Gateway

### ✅ 5. Create Security Groups
| Rule Type     | Protocol | Port | Source      | Purpose                      |
| ------------- | -------- | ---- | ----------- | ---------------------------- |
| Inbound Rule  | HTTP     | 80   | `0.0.0.0/0` | Allow public web traffic     |
| Outbound Rule | All      | All  | `0.0.0.0/0` | Allow ALB to forward traffic |
🔧 Attach this SG to the Application Load Balancer.

✅ 2. EC2 Instance Security Group (SG-EC2)
| Rule Type     | Protocol | Port | Source      | Purpose                     |
| ------------- | -------- | ---- | ----------- | --------------------------- |
| Inbound Rule  | TCP      | 8000 | SG-ALB      | Allow traffic from ALB only |
| Outbound Rule | All      | All  | `0.0.0.0/0` | Allow app to access ECR/etc |
🔧 Attach this SG to the Elastic Beanstalk EC2 instances.
Make sure the inbound rule uses the SG ID of the ALB, not 0.0.0.0/0, for internal-only access.

### ✅ 6. Configure Route Tables
Public Subnet Route Table
Associated with: Public Subnets
Contains:
Destination      Target
0.0.0.0/0        Internet Gateway (igw-xxxxxx)

Used by: ALB and NAT Gateway

Private Subnet Route Table
Associated with: Private Subnets
Contains:
Destination      Target
0.0.0.0/0        NAT Gateway (nat-xxxxxx)
Used by: EC2 instances (Elastic Beanstalk app servers)

## 🔐 Step 3: Set Up IAM Role for EC2
Go to IAM > Roles

Locate the EC2 instance profile used by Elastic Beanstalk (e.g., aws-elasticbeanstalk-ec2-role)

Attach the policy: AmazonEC2ContainerRegistryReadOnly

This allows EC2 to pull your image from ECR.

## 🏗 Step 4: Deploy to Elastic Beanstalk
Go to Elastic Beanstalk Console

Click Create Application

Fill in:

* App name: my-eb-app
* Domain name: Hotel

##Platform: Docker
* Platform branch: Docker on Amazon Linux 2 (64bit)

##Under Application code:
* Choose Upload your code
* Upload the zipped my-app.zip

##Preset
* High availability
Next

## IAM
* Choose the pre-built key and role.
Next

## VPC
* Choose the created VPC
* Enable IP checkbox
* Choose 2 private subnets
Next

## EC2 security groups
* Choose LB Security group & EC2 Security group.

### Load balancer 
* Architecture: Choose AMD ( Note if you build the docker image localy without the --platform flag then choose ARM if you are using a MAC with M1,2,3 chip)
* Number of instances
* Instance type leave as be.
* Choose public subnets.
* Health check enhanced & True.


