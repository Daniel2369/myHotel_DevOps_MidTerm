🏨 Hotel Room Management System
Welcome to the Hotel Room Management System ! This project is a Python-based application designed to manage hotel rooms, track occupancy, and provide room details. It also includes a web interface and containerization using Docker for easy deployment.



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

hotel-room-management/
│
├── python-app/               # Python application files
│   ├── main.py               # Main entry point for the CLI app
│   └── functions.py          # Reusable functions for room management
├── docker/                   # Docker-related files
│   ├── Dockerfile            # Instructions to build the Docker image
│   
