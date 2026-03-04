def test_register_creates_player_201(clean_client):
    resp = clean_client.post(
        "/auth/register",
        json={"email": "alice@example.com", "username": "alice", "password": "pass1234"},
    )
    assert resp.status_code == 201
    body = resp.json()
    assert "id" in body
    assert body["email"] == "alice@example.com"
    assert body["username"] == "alice"
    assert "created_at" in body
    assert "hashed_pw" not in body


def test_register_duplicate_email_409(clean_client):
    payload = {"email": "dup@example.com", "username": "user1", "password": "pass1234"}
    clean_client.post("/auth/register", json=payload)
    resp = clean_client.post(
        "/auth/register",
        json={"email": "dup@example.com", "username": "user2", "password": "pass1234"},
    )
    assert resp.status_code == 409


def test_register_duplicate_username_409(clean_client):
    clean_client.post(
        "/auth/register",
        json={"email": "a@example.com", "username": "samename", "password": "pass1234"},
    )
    resp = clean_client.post(
        "/auth/register",
        json={"email": "b@example.com", "username": "samename", "password": "pass1234"},
    )
    assert resp.status_code == 409


def test_login_success_returns_token(registered_player):
    client, _ = registered_player
    resp = client.post(
        "/auth/login",
        json={"email": "test@example.com", "password": "secret123"},
    )
    assert resp.status_code == 200
    body = resp.json()
    assert "access_token" in body
    assert body["access_token"]


def test_login_wrong_password_401(registered_player):
    client, _ = registered_player
    resp = client.post(
        "/auth/login",
        json={"email": "test@example.com", "password": "wrongpassword"},
    )
    assert resp.status_code == 401


def test_me_authenticated_200(auth_token):
    client, token = auth_token
    resp = client.get("/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    body = resp.json()
    assert body["email"] == "test@example.com"
    assert body["username"] == "testuser"
    assert "id" in body
    assert "created_at" in body


def test_me_no_token_403(clean_client):
    # HTTPBearer returns 403 when Authorization header is absent
    resp = clean_client.get("/auth/me")
    assert resp.status_code == 403


def test_me_bad_token_401(clean_client):
    resp = clean_client.get("/auth/me", headers={"Authorization": "Bearer invalidtoken"})
    assert resp.status_code == 401
