from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_health():

    response = client.get("/health")
    # added the comments
    # This is a health check endpoint
    # It should return a 200 status code and a healthy status
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"