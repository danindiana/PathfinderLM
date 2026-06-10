"""Endpoint-level tests for the Flask app."""

from __future__ import annotations


def test_health_endpoint(client):
    response = client.get("/health")
    assert response.status_code == 200
    body = response.get_json()
    assert body["status"] == "ok"
    assert "model" in body


def test_ask_endpoint(client):
    response = client.post(
        "/ask",
        json={
            "question": "How can I improve my productivity?",
            "context": "I struggle with time management.",
        },
    )
    assert response.status_code == 200
    body = response.get_json()
    assert "answer" in body
    # The deepseek-r1 <think> block must be stripped from the answer.
    assert "<think>" not in body["answer"]
    assert body["answer"] == "This is a coached answer."


def test_ask_requires_question(client):
    response = client.post("/ask", json={"context": "no question here"})
    assert response.status_code == 400
    assert "error" in response.get_json()


def test_index_page(client):
    response = client.get("/")
    assert response.status_code == 200
    assert response.get_json()["name"] == "PathfinderLM"
