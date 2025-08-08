def setup_rooms(total_rooms=20):
    """
    Creates a database (dictionary) of hotel rooms.

    Returns:
        dict: A dictionary called room_db{} with the auto generated data.
    """
    room_db = {}
    for room_id in range(1, total_rooms + 1):
        floor_number = (room_id - 1) // 10 + 1  # Calculate floor based on room ID
        room_category = "Single" if room_id % 2 == 1 else "Double"
        cost = 100 if room_category == "Single" else 150
        room_db[room_id] = {
            "category": room_category,
            "cost": cost,
            "guest_name": None
        }
    return room_db


def show_rooms(room_db):
    """
    Displays all hotel rooms along with their current status (free or occupied)
    By red color for occupied room and green for non.
    """
    print("\n--- Hotel Room Status ---")
    free_count = 0
    occupied_count = 0

    for room_id, details in room_db.items():
        guest = details["guest_name"] if details["guest_name"] else "No Guest"
        status = "Occupied" if details["guest_name"] else "Free"

        if status == "Free":
            free_count += 1
        else:
            occupied_count += 1

        print(
            f"Room {room_id} | Category: {details['category']} | Cost: ${details['cost']} | Guest: {guest} | Status: {status}"
        )

    print(f"\nTotal Free Rooms: {free_count}")
    print(f"Total Occupied Rooms: {occupied_count}")


def add_new_room(room_db):
    """
    Adds a new room to the hotel database.
    """
    try:
        room_id = int(input("Enter the room number to add: "))
        if room_id in room_db:
            print("Error: This room already exists.")
            return
        category = input("Enter the room category (e.g., Single/Double): ")
        cost = float(input("Enter the room cost per night: "))
        room_db[room_id] = {"category": category, "cost": cost, "guest_name": None}
        print("Room successfully added!")
    except ValueError:
        print("Invalid input. Please enter valid numbers.")


def remove_existing_room(room_db):
    """
    Removes a room from the hotel database.
    """
    try:
        room_id = int(input("Enter the room number to remove: "))
        if room_id in room_db:
            del room_db[room_id]
            print("Room successfully removed!")
        else:
            print("Error: Room not found.")
    except ValueError:
        print("Invalid input. Please enter a valid room number.")


def update_room_details(room_db):
    """
    Updates the details of an existing room.
    """
    try:
        room_id = int(input("Enter the room number to update: "))
        if room_id not in room_db:
            print("Error: Room not found.")
            return
        category = input("Enter the new room category (e.g., Single/Double): ")
        cost = float(input("Enter the new room cost per night: "))
        room_db[room_id]["category"] = category
        room_db[room_id]["cost"] = cost
        print("Room details successfully updated!")
    except ValueError:
        print("Invalid input. Please provide valid values.")


def assign_guest_to_room(room_db):
    """
    Assigns a guest to a specific room if it is unoccupied.
    """
    try:
        room_id = int(input("Enter the room number to assign a guest: "))
        if room_id not in room_db:
            print("Error: Room not found.")
            return
        if room_db[room_id]["guest_name"]:
            print("This room is already occupied.")
            return
        guest_name = input("Enter the guest's name: ")
        room_db[room_id]["guest_name"] = guest_name
        print(f"Guest '{guest_name}' has been assigned to Room {room_id}.")
    except ValueError:
        print("Invalid input. Please try again.")


def check_out_guest(room_db):
    """
    Checks out a guest from a room, marking it as free.
    """
    try:
        room_id = int(input("Enter the room number for checkout: "))
        if room_id not in room_db:
            print("Error: Room not found.")
            return
        if not room_db[room_id]["guest_name"]:
            print("This room is already free.")
            return
        guest_name = room_db[room_id]["guest_name"]
        room_db[room_id]["guest_name"] = None
        print(f"Guest '{guest_name}' has checked out from Room {room_id}.")
    except ValueError:
        print("Invalid input. Please try again.")


def sort_rooms_by_status_and_number(room_db):
    """
    Sorts rooms by occupancy status (occupied first) and then by room number.
    """
    sorted_rooms = dict(
        sorted(
            room_db.items(),
            key=lambda item: (item[1]["guest_name"] is None, item[0])  # (is_free, room_id)
        )
    )
    show_rooms(sorted_rooms)


def display_room_availability(room_db):
    """
    Displays the availability of rooms, showing occupied and free rooms separately.
    """
    occupied_rooms = [str(room_id) for room_id, details in room_db.items() if details["guest_name"]]
    free_rooms = [str(room_id) for room_id, details in room_db.items() if not details["guest_name"]]

    print("\n--- Room Availability Report ---")
    print(f"Occupied Rooms ({len(occupied_rooms)}): {', '.join(occupied_rooms)}")
    print(f"Free Rooms ({len(free_rooms)}): {', '.join(free_rooms)}")
