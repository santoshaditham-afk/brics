from datetime import datetime

from pydantic import BaseModel, Field


class GameSessionCreate(BaseModel):
    score: int = Field(..., ge=0)
    level_reached: int = Field(..., ge=1)
    duration_secs: float = Field(..., gt=0)


class GameSessionOut(BaseModel):
    id: str
    player_id: str
    score: int
    level_reached: int
    duration_secs: float
    played_at: datetime

    model_config = {"from_attributes": True}


class LeaderboardEntry(BaseModel):
    rank: int
    username: str
    score: int
    level_reached: int
    duration_secs: float
    played_at: datetime
