from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker

PLAYER_DB_URL = "sqlite:///./player.db"

engine = create_engine(PLAYER_DB_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class PlayerBase(DeclarativeBase):
    pass


def get_player_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
