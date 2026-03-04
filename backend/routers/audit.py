from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

# NOTE: Audit endpoints have no authentication — intentional for local-only MVP.
# Adding an admin token is v2 scope.
from db.audit_db import get_audit_db
from models.audit import MergeRecord, PRRecord
from schemas.audit import (
    MergeRecordCreate,
    MergeRecordOut,
    PRRecordCreate,
    PRRecordOut,
)

router = APIRouter(prefix="/audit", tags=["audit"])


# ── PR Records ────────────────────────────────────────────────────────────────

@router.post(
    "/prs",
    response_model=PRRecordOut,
    status_code=status.HTTP_201_CREATED,
    summary="Record a merged PR",
    responses={
        409: {"description": "PR number already recorded"},
    },
)
def create_pr(body: PRRecordCreate, db: Session = Depends(get_audit_db)):
    if db.query(PRRecord).filter(PRRecord.pr_number == body.pr_number).first():
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="PR number already recorded")
    record = PRRecord(id=str(uuid.uuid4()), **body.model_dump())
    db.add(record)
    db.commit()
    db.refresh(record)
    return record


@router.get(
    "/prs",
    response_model=list[PRRecordOut],
    summary="List all recorded PRs",
)
def list_prs(db: Session = Depends(get_audit_db)):
    return db.query(PRRecord).order_by(PRRecord.pr_number).all()


@router.get(
    "/prs/{pr_number}",
    response_model=PRRecordOut,
    summary="Get a single PR record by PR number",
    responses={
        404: {"description": "PR not found"},
    },
)
def get_pr(pr_number: int, db: Session = Depends(get_audit_db)):
    record = db.query(PRRecord).filter(PRRecord.pr_number == pr_number).first()
    if not record:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="PR not found")
    return record


# ── Merge Records ─────────────────────────────────────────────────────────────

@router.post(
    "/merges",
    response_model=MergeRecordOut,
    status_code=status.HTTP_201_CREATED,
    summary="Record a main-branch merge",
    responses={
        409: {"description": "Merge commit hash already recorded"},
    },
)
def create_merge(body: MergeRecordCreate, db: Session = Depends(get_audit_db)):
    if db.query(MergeRecord).filter(MergeRecord.merge_commit_hash == body.merge_commit_hash).first():
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Merge commit already recorded")
    record = MergeRecord(id=str(uuid.uuid4()), **body.model_dump())
    db.add(record)
    db.commit()
    db.refresh(record)
    return record


@router.get(
    "/merges",
    response_model=list[MergeRecordOut],
    summary="List all merge records (includes prev_main_hash for rollback reference)",
)
def list_merges(db: Session = Depends(get_audit_db)):
    return db.query(MergeRecord).order_by(MergeRecord.merged_at.desc()).all()


@router.get(
    "/merges/{merge_commit_hash}",
    response_model=MergeRecordOut,
    summary="Get a single merge record by merge commit hash",
    responses={
        404: {"description": "Merge record not found"},
    },
)
def get_merge(merge_commit_hash: str, db: Session = Depends(get_audit_db)):
    record = db.query(MergeRecord).filter(MergeRecord.merge_commit_hash == merge_commit_hash).first()
    if not record:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Merge record not found")
    return record
