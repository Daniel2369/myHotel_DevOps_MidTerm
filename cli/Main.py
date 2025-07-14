# main.py

from functions import initialize_rooms
from functions import display_rooms
from functions import add_room
from functions import remove_room
from functions import edit_room
from functions import assign_guest
from functions import check_out
from functions import sort_rooms_by_number
from functions import check_availability

def main():
    """
     function to run the hotel room management system Main .
    """
    print("Welcome to the Hotel Room Management CRM System!")
    rooms = initialize_rooms()

    while True:
        print("\n--- Menu ---")
        print("1. View all rooms")
        print("2. Add a room")
        print("3. Remove a room")
        print("4. Edit a room")
        print("5. Assign guest to room")
        print("6. Check out guest")
        print("7. Sort rooms by Status")
        print("8. Check availability")
        print("9. Exit")

        choice = input("Choose an option (1-9): ")

        if choice == '1':
            display_rooms(rooms)
        elif choice == '2':
            add_room(rooms)
        elif choice == '3':
            remove_room(rooms)
        elif choice == '4':
            edit_room(rooms)
        elif choice == '5':
            assign_guest(rooms)
        elif choice == '6':
            check_out(rooms)
        elif choice == '7':
            sort_rooms_by_number(rooms)
        elif choice == '8':
            check_availability(rooms)
        elif choice == '9':
            print("no problem Bye")
            break
        else:
            print("Please choose a number between 1 and or '9' or exit.")

if __name__ == "__main__":
    main()
