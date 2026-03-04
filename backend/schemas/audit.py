from __future__ import annotations

from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class PRRecordCreate(BaseModel):
    commit_hash: str
    pr_number: int
    title: str
    description: str
    author: str
    merged_at: datetime


class PRRecordOut(BaseModel):
    id: str
    commit_hash: str
    pr_number: int
    title: str
    description: str
    author: str
    merged_at: datetime

    model_config = {"from_attributes": True}


class MergeRecordCreate(BaseModel):
    merge_commit_hash: str
    prev_main_hash: str
    pr_record_id: str
    merged_at: datetime
    notes: Optional[str] = None


class MergeRecordOut(BaseModel):
    id: str
    merge_commit_hash: str
    prev_main_hash: str
    pr_record_id: str
    merged_at: datetime
    notes: Optional[str]

    model_config = {"from_attributes": True}
