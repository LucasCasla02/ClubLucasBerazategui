from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.database import get_db
from app.models import EspacioDeportivo, Sede
from app.schemas import SedeOut

router = APIRouter(prefix="/api/v1/sedes", tags=["Sedes"])


def _a_sede_out(sede):
    activos = [e for e in sede.espacios if e.activo]
    # deportes sin repetir, en el orden en que aparecen
    deportes = list(dict.fromkeys(e.deporte.nombre for e in activos))
    return SedeOut(
        id=sede.id,
        nombre=sede.nombre,
        direccion=sede.direccion,
        hora_apertura=sede.hora_apertura,
        hora_cierre=sede.hora_cierre,
        cantidad_espacios=len(activos),
        deportes=deportes,
    )


def _consulta_sedes():
    # trae los espacios y sus deportes en la misma consulta
    return select(Sede).options(
        selectinload(Sede.espacios).selectinload(EspacioDeportivo.deporte)
    )


@router.get("", response_model=list[SedeOut], summary="Listar las sedes con sus horarios")
def listar_sedes(db: Session = Depends(get_db)):
    sedes = db.scalars(_consulta_sedes().order_by(Sede.id)).all()
    return [_a_sede_out(s) for s in sedes]


@router.get(
    "/{sede_id}",
    response_model=SedeOut,
    summary="Ver una sede",
    responses={404: {"description": "La sede no existe"}},
)
def ver_sede(sede_id: int, db: Session = Depends(get_db)):
    sede = db.scalar(_consulta_sedes().where(Sede.id == sede_id))
    if sede is None:
        raise HTTPException(status_code=404, detail="La sede no existe")
    return _a_sede_out(sede)