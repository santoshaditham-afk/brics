from datetime import datetime

from pydantic import BaseModel, EmailStr


class PlayerCreate(BaseModel):
    email: EmailStr
    username: str
    password: str


class PlayerLogin(BaseModel):
    email: EmailStr
    password: str


class PlayerOut(BaseModel):
    id: str
    email: str
    username: str
    created_at: datetime

    model_config = {"from_attributes": True}


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class TokenData(BaseModel):
    player_id: str
