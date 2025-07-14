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
docker build -t hotels:latest .
docker run -d --name hotels-container -p 8000:8000 hotels:latest
# Inside the host machine run ip a and take the IPv4
# Browse to http://<IPv4>:8000
