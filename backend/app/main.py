from fastapi import Depends, FastAPI, HTTPException
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from app.database import get_db
from app.routers import deportes, espacios, sedes

app = FastAPI(
    title="API ClubLucasBerazategui",
    description="API REST para la gestión de reservas de espacios deportivos.",
    version="0.2.0",
)

app.include_router(sedes.router)
app.include_router(deportes.router)
app.include_router(espacios.router)


@app.get(
    "/api/v1/salud",
    tags=["Salud"],
    summary="Verifica que la API y la base de datos funcionan",
)
def salud(db: Session = Depends(get_db)):
    try:
        db.execute(text("SELECT 1"))
    except SQLAlchemyError:
        raise HTTPException(status_code=503, detail="No hay conexión con la base de datos")
    return {"estado": "ok", "base_de_datos": "conectada"}
