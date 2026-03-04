from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker

GAME_DB_URL = "sqlite:///./game.db"

engine = create_engine(GAME_DB_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class GameBase(DeclarativeBase):
    pass


def get_game_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
