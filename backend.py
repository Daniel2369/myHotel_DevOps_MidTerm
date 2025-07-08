# Import Libraries
from fastapi import FastAPI, Request # Backend app library fastapi
from contextlib import asynccontextmanager
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates # Frontend library using html templates
from starlette import status


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
    print("Setting up rooms...")
    for room_id in range(1, total_rooms + 1):
        floor_number = (room_id - 1) // 10 + 1  # Calculate floor based on room ID
        room_category = "Single" if room_id % 2 == 1 else "Double"
        cost = 100 if room_category == "Single" else 150
        room_db[room_id] = {
            "category": room_category,
            "cost": cost,
            "floor_number": floor_number,
            "guest_name": None
        }

@asynccontextmanager
async def lifespan(app: FastAPI):
    setup_rooms(total_rooms=20)
    yield

app = FastAPI(lifespan=lifespan) # Loading the framework to a variable
templates = Jinja2Templates(directory="templates") # Loading the menu.html file


'''
Calling the menu.html file to be loaded
'''
@app.get("/", response_class=HTMLResponse)
async def menu(request: Request):
    return templates.TemplateResponse("menu.html", {"request": request})

@app.get("/rooms", status_code=status.HTTP_200_OK)
async def get_rooms():
    return room_db