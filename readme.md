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
hotel-room-management/
├── app/
│   ├── backend.py                 # Main FastAPI application
│   ├── templates/                 # HTML templates for all frontend pages
|   ├── static/                    # Banner image
|   |── terraform/                 # IaaC using Terraform
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
 ```bash
    1. cd terraform/main
    2. Inside the host shell run vi/nano ~/.aws/credentials paste inside:
       * ACCESS_KEY_ID
       * SECRET_KEY
       * SESSION_TOKEN
    3.  Inside the .sh file under CREDENTIALS insert the same as step 2.
    3. terarform init
    4. terraform plan -out plan
    5. terraform apply plan
       # Wait for a few minutes.
    6. Copy the Load balancer domain and paste in the host browser.
   ```
