import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from db.player_db import PlayerBase, get_player_db
from db.game_db import GameBase, get_game_db
from db.audit_db import AuditBase, get_audit_db
from main import app

# StaticPool ensures all connections share one in-memory DB so create_all tables persist
_player_engine = create_engine(
    "sqlite:///:memory:",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
_game_engine = create_engine(
    "sqlite:///:memory:",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
_audit_engine = create_engine(
    "sqlite:///:memory:",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)

_PlayerSession = sessionmaker(autocommit=False, autoflush=False, bind=_player_engine)
_GameSession = sessionmaker(autocommit=False, autoflush=False, bind=_game_engine)
_AuditSession = sessionmaker(autocommit=False, autoflush=False, bind=_audit_engine)


def _override_player_db():
    db = _PlayerSession()
    try:
        yield db
    finally:
        db.close()


def _override_game_db():
    db = _GameSession()
    try:
        yield db
    finally:
        db.close()


def _override_audit_db():
    db = _AuditSession()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_player_db] = _override_player_db
app.dependency_overrides[get_game_db] = _override_game_db
app.dependency_overrides[get_audit_db] = _override_audit_db


@pytest.fixture(autouse=True)
def reset_dbs():
    """Drop and recreate all tables before each test for isolation."""
    PlayerBase.metadata.drop_all(bind=_player_engine)
    PlayerBase.metadata.create_all(bind=_player_engine)
    GameBase.metadata.drop_all(bind=_game_engine)
    GameBase.metadata.create_all(bind=_game_engine)
    AuditBase.metadata.drop_all(bind=_audit_engine)
    AuditBase.metadata.create_all(bind=_audit_engine)
    yield


@pytest.fixture
def clean_client(reset_dbs):
    return TestClient(app)


@pytest.fixture
def registered_player(clean_client):
    resp = clean_client.post(
        "/auth/register",
        json={"email": "test@example.com", "username": "testuser", "password": "secret123"},
    )
    assert resp.status_code == 201
    return clean_client, resp.json()


@pytest.fixture
def auth_token(registered_player):
    client, _ = registered_player
    resp = client.post(
        "/auth/login",
        json={"email": "test@example.com", "password": "secret123"},
    )
    assert resp.status_code == 200
    return client, resp.json()["access_token"]
