# 🏨 Hotel Room Management System

A simple hotel room management system built with **FastAPI** and **Jinja2** templates, 
Designed to demonstrate:
* FastAPI operations
* room assignments 
* guest check-in/check-out functionalities
All in a clean HTML UI.

---

## 🚀 Features

- 📄 View all rooms with occupancy status (with sortable table headers)
- ➕ Create new rooms via web form
- ✏️ Update existing room details
- ❌ Delete rooms
- ✅ Guest check-in based on room availability
- 🛏️ Guest check-out from assigned room
- 🌐 Fully Dockerized for quick deployment

---

## 🧰 Tech Stack

- **Backend:** FastAPI (Python 3.9)
- **Frontend:** HTML + Jinja2 Templates + Basic CSS
- **Containerization:** Docker
- **Server:** Uvicorn (ASGI)

---

## 🐳 Running with Docker

### 1. Build the Docker image

```bash
docker build -t hotels:latest .
docker run -d --name hotels-container -p 8000:8000 hotels:latest

Browse to http://localhost:8000
