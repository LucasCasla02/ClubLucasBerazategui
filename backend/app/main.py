from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from app.database import get_db
from app.firebase import iniciar_firebase
from app.routers import deportes, espacios, reservas, sedes, usuarios

@asynccontextmanager
async def ciclo_de_vida(app):
    iniciar_firebase()  # al arrancar la api
    yield


app = FastAPI(
    title="API ClubLucasBerazategui",
    description="API REST para la gestión de reservas de espacios deportivos.",
    version="0.4.0",
    lifespan=ciclo_de_vida,
)

app.include_router(sedes.router)
app.include_router(deportes.router)
app.include_router(espacios.router)
app.include_router(usuarios.router)
app.include_router(reservas.router)


# errores de validacion en castellano
@app.exception_handler(RequestValidationError)
async def datos_invalidos(request: Request, exc: RequestValidationError):
    campos = sorted({str(e["loc"][-1]) for e in exc.errors()})
    return JSONResponse(
        status_code=422,
        content={"detail": f"Datos inválidos en: {', '.join(campos)}", "campos": campos},
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
        raise HTTPException(status_code=503, detail="No hay conexión con la base de datos")
    return {"estado": "ok", "base_de_datos": "conectada"}