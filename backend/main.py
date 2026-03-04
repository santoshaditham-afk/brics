from fastapi import FastAPI
from fastapi.openapi.utils import get_openapi

from db.audit_db import AuditBase, engine as audit_engine
from db.game_db import GameBase, engine as game_engine
from db.player_db import PlayerBase, engine as player_engine

# Import models so SQLAlchemy registers them before create_all
import models.player  # noqa: F401
import models.game  # noqa: F401
import models.audit  # noqa: F401

from routers import auth, audit, game

_TAGS_METADATA = [
    {
        "name": "auth",
        "description": "Player registration and JWT-based login. Protected routes require `Authorization: Bearer <token>`.",
    },
    {
        "name": "game",
        "description": "Submit and retrieve game sessions. All endpoints require a valid JWT.",
    },
    {
        "name": "audit",
        "description": (
            "Internal devops endpoints for recording PR merges and main-branch merges. "
            "**No authentication required** — local-only MVP. Auth is v2 scope."
        ),
    },
    {
        "name": "health",
        "description": "Liveness probe. No auth required.",
    },
]

app = FastAPI(
    title="Brics Backend API",
    description=(
        "Player auth, game stat recording, and audit trail for the Brics iOS game.\n\n"
        "## Authentication\n"
        "Protected endpoints use **HTTP Bearer (JWT/HS256)**. "
        "Obtain a token via `POST /auth/login`, then include it as:\n"
        "```\nAuthorization: Bearer <access_token>\n```\n\n"
        "## Policy Notes\n"
        "- Passwords are hashed with **bcrypt** — plain-text passwords are never stored.\n"
        "- JWTs expire after **7 days** (mobile UX trade-off).\n"
        "- Duplicate email/username and duplicate audit records return **409 Conflict**.\n"
        "- Audit endpoints are unauthenticated (internal/local-only)."
    ),
    version="1.0.0",
    openapi_tags=_TAGS_METADATA,
)

# Auto-create tables on startup
PlayerBase.metadata.create_all(bind=player_engine)
GameBase.metadata.create_all(bind=game_engine)
AuditBase.metadata.create_all(bind=audit_engine)

# Register routers
app.include_router(auth.router)
app.include_router(game.router)
app.include_router(audit.router)


@app.get("/health", tags=["health"], summary="Liveness check")
def health():
    return {"status": "ok"}


def custom_openapi():
    if app.openapi_schema:
        return app.openapi_schema
    schema = get_openapi(
        title=app.title,
        version=app.version,
        description=app.description,
        routes=app.routes,
        tags=_TAGS_METADATA,
    )
    # Declare HTTPBearer security scheme
    schema.setdefault("components", {}).setdefault("securitySchemes", {})["BearerAuth"] = {
        "type": "http",
        "scheme": "bearer",
        "bearerFormat": "JWT",
        "description": "JWT obtained from POST /auth/login. Valid for 7 days.",
    }
    # Apply BearerAuth to all operations that already carry a security requirement
    for path_item in schema.get("paths", {}).values():
        for operation in path_item.values():
            if isinstance(operation, dict) and operation.get("security"):
                operation["security"] = [{"BearerAuth": []}]
    app.openapi_schema = schema
    return schema


app.openapi = custom_openapi  # type: ignore[method-assign]


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
