# Import Libraries
from fastapi import FastAPI, Request, Form # Backend app library fastapi
from contextlib import asynccontextmanager
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates # Frontend library using html templates
from fastapi.staticfiles import StaticFiles
import json
import os
import requests
from pathlib import Path

# Declare an empty DB
room_db:dict = {}

# JSON file path - prioritize mounted volume in Kubernetes, fallback to local file
JSON_FILE_PATH = os.getenv("HOTEL_JSON_PATH", "/app/data/hotel_rooms.json")
LOCAL_JSON_PATH = "hotel_rooms.json"

def get_json_file_path():
    """Determine the correct path for the JSON file."""
    # First check if mounted volume path exists (Kubernetes)
    if os.path.exists(JSON_FILE_PATH):
        return JSON_FILE_PATH
    # Fallback to local file (local development)
    elif os.path.exists(LOCAL_JSON_PATH):
        return LOCAL_JSON_PATH
    # If neither exists, use the mounted volume path (will create new file)
    else:
        # Create directory if it doesn't exist
        os.makedirs(os.path.dirname(JSON_FILE_PATH), exist_ok=True)
        return JSON_FILE_PATH

def load_rooms():
    """
    Loads hotel rooms from JSON file.
    Returns:
        dict: A dictionary containing room numbers as keys and their details as values.
    """
    global room_db
    json_path = get_json_file_path()
    
    try:
        if os.path.exists(json_path):
            with open(json_path, 'r') as f:
                data = json.load(f)
                # Convert string keys to int keys to match the original structure
                rooms_dict = {}
                for room_id_str, room_data in data.get("rooms", {}).items():
                    rooms_dict[int(room_id_str)] = room_data
                room_db = rooms_dict
                print(f"Loaded {len(room_db)} rooms from {json_path}")
            return
    except Exception as e:
        print(f"Error loading rooms from {json_path}: {e}")
    
    # If file doesn't exist or error occurred, initialize empty database
    room_db = {}
    print(f"No existing room data found. Starting with empty database.")

def save_rooms():
    """
    Saves hotel rooms to JSON file.
    """
    json_path = get_json_file_path()
    
    try:
        # Convert int keys to string keys for JSON
        rooms_dict = {str(room_id): room_data for room_id, room_data in room_db.items()}
        data = {"rooms": rooms_dict}
        
        # Create directory if it doesn't exist (only if path has a directory)
        dir_path = os.path.dirname(json_path)
        if dir_path:
            os.makedirs(dir_path, exist_ok=True)
        
        with open(json_path, 'w') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        print(f"Saved {len(room_db)} rooms to {json_path}")
    except Exception as e:
        print(f"Error saving rooms to {json_path}: {e}")

# Get EC2 instance-id
def get_instance_id():
    try:
        return requests.get(
            "http://169.254.169.254/latest/meta-data/instance-id",
            timeout=1
        ).text
    except:
        return "unknown"

@asynccontextmanager
async def lifespan(app: FastAPI):
    load_rooms()
    yield
    # Save rooms on shutdown
    save_rooms()

app = FastAPI(lifespan=lifespan) # Loading the framework to a variable
templates = Jinja2Templates(directory="templates") # Loading the menu.html file

app.mount("/static", StaticFiles(directory="static"), name="static")

'''
Calling templates/*.html files
'''
@app.get("/", response_class=HTMLResponse)
async def menu(request: Request):
    instance_id = get_instance_id()
    return templates.TemplateResponse("menu.html", {"request": request, "instance_id": instance_id})

@app.get("/form/create_room", response_class=HTMLResponse)
async def create_room_form(request: Request):
    return templates.TemplateResponse("create_room.html", {"request": request})

@app.get("/form/update_room", response_class=HTMLResponse)
async def update_room_form(request: Request):
    return templates.TemplateResponse("update_room.html", {"request": request})

@app.get("/form/delete_room", response_class=HTMLResponse)
async def delete_room_form(request: Request):
    return templates.TemplateResponse("delete_room.html", {"request": request})

@app.get("/form/check_in", response_class=HTMLResponse)
async def check_in_form(request: Request):
    return templates.TemplateResponse("check_in.html", {"request": request})

@app.get("/form/check_out", response_class=HTMLResponse)
async def check_in_form(request: Request):
    return templates.TemplateResponse("check_out.html", {"request": request})

@app.get("/rooms", response_class=HTMLResponse)
async def get_rooms(request: Request):
    return templates.TemplateResponse("rooms.html", {"request": request, "rooms": room_db})


@app.post("/rooms/create_room", response_class=HTMLResponse)
async def create_room(
    request: Request,
    category: str = Form(...),
    cost: int = Form(...),
    floor_number: int = Form(...),
    guest_name: str = Form(None)
):
    global room_db

    new_room_id = max(room_db.keys(), default=0) + 1 # Will append id automatically

    room_db[new_room_id] = {
    "category": category,
    "cost": cost,
    "floor_number": floor_number,
    "guest_name": guest_name,
    "occupied": bool(guest_name)
    }
    
    # Save to JSON file
    save_rooms()
    
    return templates.TemplateResponse("create_room.html", {
    "request": request,
    "message": f"Room {new_room_id} created successfully!"
    })

@app.post("/rooms/delete_room", response_class=HTMLResponse)
async def delete_room(
    request: Request,
    room_id: int = Form(...)
):
    global room_db
    if room_id in room_db:
        room_db.pop(room_id)
        # Save to JSON file
        save_rooms()
        message = f"Room deleted successfully, Room_ID = {room_id}"
        is_error = False
    else:
        message = f"Room {room_id} not found."
        is_error = True

    return templates.TemplateResponse("delete_room.html", {
        "request": request,
        "message": message,
        "is_error": is_error
    })

@app.post("/rooms/update_room", response_class=HTMLResponse)
async def update_room(
    request: Request,
    room_id: int = Form(...),
    category: str = Form(...),
    cost: int = Form(...),
    floor_number: int = Form(...),
    guest_name: str = Form(None)
):
    global room_db

    if room_id in room_db:
        room = room_db[room_id]

        room.update({
            "category": category,
            "cost": cost,
            "floor_number": floor_number,
            "guest_name": guest_name,
            "occupied": bool(guest_name)
        })
        # Save to JSON file
        save_rooms()
        message = f"Room {room_id} was successfully updated."
        is_error = False
    else:
        message = f"Room {room_id} not found."
        is_error = True

    return templates.TemplateResponse("update_room.html", {
        "request": request,
        "message": message,
        "is_error": is_error
    })

@app.post("/rooms/check_in", response_class=HTMLResponse)
async def check_in(
    request: Request,
    guest_name: str = Form(...),
    category: str = Form(...)
):
    global room_db
    message = f"No available room in that category."
    is_error = True
    
    for room_id, room in room_db.items():
        if not room["occupied"] and room["category"] == category:
            room["guest_name"] = guest_name
            room["occupied"] = True
            # Save to JSON file
            save_rooms()
            message = f"Guest was successfully assigned to room, Room_ID= {room_id}."
            is_error = False
            break

    return templates.TemplateResponse("check_in.html", {
        "request": request,
        "message": message,
        "is_error": is_error
    })

@app.post("/rooms/check_out", response_class=HTMLResponse)
async def check_out(
    request: Request,
    room_id: int = Form(...),
    guest_name: str = Form(...)
):
    global room_db
    
    if room_id in room_db: 
        if room_db[room_id]["guest_name"] == guest_name:
            room_db[room_id]["guest_name"] = None
            room_db[room_id]["occupied"] = False
            # Save to JSON file
            save_rooms()
            message = f"{guest_name} was checked_out from Room_ID = {room_id}."
            is_error = False
        else:
            message = "Couldn't complete the check_out."
            is_error = True
    else:
        message = f"Room {room_id} not found."
        is_error = True

    return templates.TemplateResponse("check_out.html", {
        "request": request,
        "message": message,
        "is_error": is_error
    })
