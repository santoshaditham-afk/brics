from datetime import datetime, timezone

from sqlalchemy import DateTime, Float, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from db.game_db import GameBase


class GameSession(GameBase):
    __tablename__ = "game_sessions"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    player_id: Mapped[str] = mapped_column(String, nullable=False, index=True)
    score: Mapped[int] = mapped_column(Integer, nullable=False)
    level_reached: Mapped[int] = mapped_column(Integer, nullable=False)
    duration_secs: Mapped[float] = mapped_column(Float, nullable=False)
    played_at: Mapped[datetime] = mapped_column(
        DateTime, default=lambda: datetime.now(timezone.utc)
    )
