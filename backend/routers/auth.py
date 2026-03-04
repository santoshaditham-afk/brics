import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from core.dependencies import get_current_player
from core.security import create_access_token, hash_password, verify_password
from db.player_db import get_player_db
from models.player import Player
from schemas.player import PlayerCreate, PlayerLogin, PlayerOut, Token

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post(
    "/register",
    response_model=PlayerOut,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new player account",
    responses={
        409: {"description": "Email or username already registered"},
    },
)
def register(body: PlayerCreate, db: Session = Depends(get_player_db)):
    if db.query(Player).filter(Player.email == body.email).first():
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already registered")
    if db.query(Player).filter(Player.username == body.username).first():
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Username already taken")
    player = Player(
        id=str(uuid.uuid4()),
        email=body.email,
        username=body.username,
        hashed_pw=hash_password(body.password),
    )
    db.add(player)
    db.commit()
    db.refresh(player)
    return player


@router.post(
    "/login",
    response_model=Token,
    summary="Authenticate and receive a JWT",
    responses={
        401: {"description": "Invalid email or password"},
    },
)
def login(body: PlayerLogin, db: Session = Depends(get_player_db)):
    player = db.query(Player).filter(Player.email == body.email).first()
    if not player or not verify_password(body.password, player.hashed_pw):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
        )
    return Token(access_token=create_access_token(player.id))


@router.get(
    "/me",
    response_model=PlayerOut,
    summary="Get the current authenticated player's profile",
    responses={
        401: {"description": "Missing, expired, or invalid Bearer token"},
    },
)
def me(current_player: Player = Depends(get_current_player)):
    return current_player
