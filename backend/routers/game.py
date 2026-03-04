from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from core.dependencies import get_current_player
from db.game_db import get_game_db
from models.game import GameSession
from models.player import Player
from db.player_db import get_player_db
from models.player import Player
from schemas.game import GameSessionCreate, GameSessionOut, LeaderboardEntry

router = APIRouter(prefix="/game", tags=["game"])


@router.post(
    "/sessions",
    response_model=GameSessionOut,
    status_code=status.HTTP_201_CREATED,
    summary="Submit a completed game session",
    responses={
        401: {"description": "Missing, expired, or invalid Bearer token"},
        422: {"description": "score < 0, level_reached < 1, or duration_secs ≤ 0"},
    },
)
def create_session(
    body: GameSessionCreate,
    current_player: Player = Depends(get_current_player),
    db: Session = Depends(get_game_db),
):
    session = GameSession(
        id=str(uuid.uuid4()),
        player_id=current_player.id,
        score=body.score,
        level_reached=body.level_reached,
        duration_secs=body.duration_secs,
    )
    db.add(session)
    db.commit()
    db.refresh(session)
    return session


@router.get(
    "/sessions/me",
    response_model=list[GameSessionOut],
    summary="List all game sessions for the current player",
    responses={
        401: {"description": "Missing, expired, or invalid Bearer token"},
    },
)
def my_sessions(
    current_player: Player = Depends(get_current_player),
    db: Session = Depends(get_game_db),
):
    return db.query(GameSession).filter(GameSession.player_id == current_player.id).all()


@router.get(
    "/sessions/leaderboard",
    response_model=list[LeaderboardEntry],
    summary="Top 5 scores across all players",
    responses={
        401: {"description": "Missing, expired, or invalid Bearer token"},
    },
)
def leaderboard(
    _: Player = Depends(get_current_player),
    game_db: Session = Depends(get_game_db),
    player_db: Session = Depends(get_player_db),
):
    top5 = (
        game_db.query(GameSession)
        .order_by(GameSession.score.desc())
        .limit(5)
        .all()
    )
    result = []
    for rank, session in enumerate(top5, start=1):
        player = player_db.query(Player).filter(Player.id == session.player_id).first()
        result.append(LeaderboardEntry(
            rank=rank,
            username=player.username if player else "Unknown",
            score=session.score,
            level_reached=session.level_reached,
            duration_secs=session.duration_secs,
            played_at=session.played_at,
        ))
    return result
