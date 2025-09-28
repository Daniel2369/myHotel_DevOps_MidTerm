import backend as backend
import pytest

def test_backend_initialization():
    backend.setup_rooms()
    assert isinstance(backend.room_db, dict)
    assert len(backend.room_db) == 20
    
