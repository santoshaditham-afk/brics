from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker

AUDIT_DB_URL = "sqlite:///./audit.db"

engine = create_engine(AUDIT_DB_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class AuditBase(DeclarativeBase):
    pass


def get_audit_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
