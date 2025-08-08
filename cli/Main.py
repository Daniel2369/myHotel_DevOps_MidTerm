from functions import setup_rooms
from functions import show_rooms
from functions import add_new_room
from functions import remove_existing_room
from functions import update_room_details
from functions import assign_guest_to_room
from functions import check_out_guest
from functions import sort_rooms_by_status_and_number
from functions import display_room_availability

def main():
    """
     function to run the hotel room management system Main .
    """
    print("Welcome to the Hotel Room Management CRM System!")
    rooms = setup_rooms()

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
            show_rooms(rooms)
        elif choice == '2':
            add_new_room(rooms)
        elif choice == '3':
            remove_existing_room(rooms)
        elif choice == '4':
            update_room_details(rooms)
        elif choice == '5':
            assign_guest_to_room(rooms)
        elif choice == '6':
            check_out_guest(rooms)
        elif choice == '7':
            sort_rooms_by_status_and_number(rooms)
        elif choice == '8':
            display_room_availability(rooms)
        elif choice == '9':
            print("no problem Bye")
            break
        else:
            print("Please choose a number between 1 and or '9' or exit.")

if __name__ == "__main__":
    main()
