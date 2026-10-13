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
from app.schemas import ErrorValidacion


@asynccontextmanager
async def ciclo_de_vida(app):
    iniciar_firebase()  # al arrancar la api
    yield


DESCRIPCION = """
API REST de **ClubLucasBerazategui** para la gestión de reservas de espacios deportivos.

**Autenticación:** los endpoints de *Usuarios* y *Reservas* necesitan el ID token de
Firebase del usuario. Para probarlos acá:

1. Obtené un token con `python obtener_token.py email contraseña` (ver README del backend).
2. Tocá **Authorize** y pegá el token (sin escribir "Bearer").

Sedes, deportes, espacios y horarios son públicos.
"""

GRUPOS = [
    {"name": "Sedes", "description": "Sedes del club, sus horarios y la disponibilidad por rango horario."},
    {"name": "Deportes", "description": "Tipos de espacio deportivo, usados para filtrar."},
    {"name": "Espacios deportivos", "description": "Canchas de cada sede y su grilla de horarios libres."},
    {"name": "Usuarios", "description": "Perfil del usuario logueado. Requiere token."},
    {"name": "Reservas", "description": "Reservar, ver mis reservas y cancelar. Requiere token."},
    {"name": "Salud", "description": "Estado de la API y de la base de datos."},
]

app = FastAPI(
    title="API ClubLucasBerazategui",
    description=DESCRIPCION,
    version="0.4.2",
    openapi_tags=GRUPOS,
    lifespan=ciclo_de_vida,
)

app.include_router(sedes.router)
app.include_router(deportes.router)
app.include_router(espacios.router)
app.include_router(usuarios.router)
app.include_router(reservas.router)


# en la documentacion, cambia el formato de error 422 de fastapi por el nuestro
def _documentacion():
    if app.openapi_schema:
        return app.openapi_schema
    esquema = FastAPI.openapi(app)
    for ruta in esquema["paths"].values():
        for operacion in ruta.values():
            error = operacion.get("responses", {}).get("422")
            if error:
                error["description"] = "Datos inválidos"
                error["content"]["application/json"]["schema"] = {
                    "$ref": "#/components/schemas/ErrorValidacion"
                }
    modelos = esquema["components"]["schemas"]
    modelos.pop("HTTPValidationError", None)
    modelos.pop("ValidationError", None)
    modelos["ErrorValidacion"] = ErrorValidacion.model_json_schema()
    app.openapi_schema = esquema
    return esquema


app.openapi = _documentacion


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
