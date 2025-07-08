# Import Libraries
from fastapi import FastAPI, Request, Form # Backend app library fastapi
from contextlib import asynccontextmanager
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates # Frontend library using html templates
from starlette import status
import random


# Declare an empty DB
room_db:dict = {}


def setup_rooms(total_rooms=20):
    """
    Creates a database (dictionary) of hotel rooms with default details.
    total_rooms (int): The total number of rooms to initialize.

    Returns:
        dict: A dictionary containing room numbers as keys and their details as values.
    """
    global room_db
    room_db = {}
    guest_names = ("Daniel", "Idan", "Yosi", "Aviva", "Daniela")
    print("Setting up rooms...")
    for room_id in range(1, total_rooms + 1):
        floor_number = (room_id - 1) // 10 + 1  # Calculate floor based on room ID
        room_category = "Single" if room_id % 2 == 1 else "Double"
        cost = 100 if room_category == "Single" else 150
        if random.random() < 0.5: # 50% chance for a room to occupied
            guest_name = random.choice(guest_names)
            occupied = True
        else:
            guest_name = None
            occupied = False

        room_db[room_id] = {
            "category": room_category,
            "cost": cost,
            "floor_number": floor_number,
            "guest_name": guest_name,
            "occupied": bool(guest_name)
        }

@asynccontextmanager
async def lifespan(app: FastAPI):
    setup_rooms(total_rooms=20)
    yield

app = FastAPI(lifespan=lifespan) # Loading the framework to a variable
templates = Jinja2Templates(directory="templates") # Loading the menu.html file


'''
Calling templates/*.html files
'''
@app.get("/", response_class=HTMLResponse)
async def menu(request: Request):
    return templates.TemplateResponse("menu.html", {"request": request})

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

@app.get("/rooms", response_class=HTMLResponse, status_code=status.HTTP_200_OK)
async def get_rooms(request: Request):
    return templates.TemplateResponse("rooms.html", {"request": request, "rooms": room_db})


@app.post("/rooms/create_room", status_code=status.HTTP_201_CREATED)
async def create_room(
    category: str = Form(...),
    cost: int = Form(...),
    floor_number: int = Form(...),
    guest_name: str = Form(None)
):

    new_room_id = max(room_db.keys(), default=0) + 1 # Will append id automatically

    room_db[new_room_id] = {
    "category": category,
    "cost": cost,
    "floor_number": floor_number,
    "guest_name": guest_name,
    "occupied": bool(guest_name)
    }
    
    return {"message": "Room created successfully", "room_id": new_room_id}

@app.post("/rooms/delete_room", status_code=status.HTTP_200_OK)
async def delete_room(
    room_id: int = Form(...)
):
    global room_db
    if room_id in room_db:
        room_db.pop(room_id)
        return {"message": "Room deleted successfully", "room_id": room_id}
    else:
        return {"error": "Room not found", "room_id": room_id}

@app.post("/rooms/update_room", response_class=HTMLResponse, status_code=status.HTTP_200_OK)
async def update_room(
    request: Request,
    room_id: int = Form(...),
    category: str = Form(...),
    cost: int = Form(...),
    floor_number: int = Form(...),
    guest_name: str = Form(None)
):

    if room_id in room_db:
        room = room_db[room_id]

        room.update({
            "category": category,
            "cost": cost,
            "floor_number": floor_number,
            "guest_name": guest_name,
            "occupied": bool(guest_name)
        })
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

@app.post("/rooms/check_in")
async def check_in(
    guest_name: str = Form(...),
    category: str = Form(...)
):
    global room_db
    for room_id, room in room_db.items():
        if not room["occupied"] and room["category"] == category:
            room["guest_name"] = guest_name
            room["occupied"] = True
            return {
                    "message": "Guest was successfully assigned to room",
                    "room_id": room_id
                }
    
    return {"message": "No available room in that category."}

@app.post("/rooms/check_out")
async def check_out(
    room_id: int = Form(...),
    guest_name: str = Form(...)
):
    if room_id in room_db: 
        if room_db[room_id]["guest_name"] == guest_name:
            room_db[room_id]["guest_name"] = None
            room_db[room_id]["occupied"] = False
            return {
                "message": f"{guest_name} was checked_out from room",
                "room_id": room_id
            }
    
    return {"message": "Couldn't complete the check_out"}