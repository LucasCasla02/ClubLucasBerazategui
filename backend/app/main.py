"""Punto de entrada de la API REST de ClubLucasBerazategui."""
from fastapi import Depends, FastAPI, HTTPException
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from app.database import get_db

app = FastAPI(
    title="API ClubLucasBerazategui",
    description="API REST para la gestión de reservas de espacios deportivos.",
    version="0.1.0",
)


@app.get(
    "/api/v1/salud",
    tags=["Salud"],
    summary="Verifica que la API y la base de datos funcionan",
)
def salud(db: Session = Depends(get_db)):
    try:
        db.execute(text("SELECT 1"))
    except SQLAlchemyError:
        # 503 = servicio no disponible (la base no responde)
        raise HTTPException(status_code=503, detail="No hay conexión con la base de datos")
    return {"estado": "ok", "base_de_datos": "conectada"}