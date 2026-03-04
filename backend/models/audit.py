from __future__ import annotations

from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import DateTime, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from db.audit_db import AuditBase


class PRRecord(AuditBase):
    __tablename__ = "pr_records"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    commit_hash: Mapped[str] = mapped_column(String, nullable=False)
    pr_number: Mapped[int] = mapped_column(Integer, unique=True, nullable=False)
    title: Mapped[str] = mapped_column(String, nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    author: Mapped[str] = mapped_column(String, nullable=False)
    merged_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)


class MergeRecord(AuditBase):
    __tablename__ = "merge_records"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    merge_commit_hash: Mapped[str] = mapped_column(String, unique=True, nullable=False)
    prev_main_hash: Mapped[str] = mapped_column(String, nullable=False)
    pr_record_id: Mapped[str] = mapped_column(String, nullable=False)
    merged_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
