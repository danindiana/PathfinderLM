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


def test_ask_forwards_system_prompt(client):
    from tests.conftest import FakeClient

    resp = client.post("/ask", json={"question": "How do I start a new habit?"})
    assert resp.status_code == 200
    captured = FakeClient.last_generate_kwargs
    assert "life coach" in captured.get("system", "")


def test_index_page(client):
    response = client.get("/")
    assert response.status_code == 200
    assert response.get_json()["name"] == "PathfinderLM"


def test_console_page(client):
    response = client.get("/console")
    assert response.status_code == 200
    assert "text/html" in response.content_type
    assert b"Operator Console" in response.data


def test_activity_feed_records_requests(client):
    before = client.get("/api/activity").get_json()["stats"]["total"]
    client.post("/ask", json={"question": "How do I focus better?"})
    after = client.get("/api/activity").get_json()
    assert after["stats"]["total"] == before + 1
    assert after["recent"][0]["status"] == 200
    assert "focus" in after["recent"][0]["question"]
