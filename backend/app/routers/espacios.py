from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from app.database import get_db
from app.models import EspacioDeportivo
from app.schemas import EspacioOut

router = APIRouter(prefix="/api/v1/espacios", tags=["Espacios deportivos"])


def _consulta_espacios():
    return select(EspacioDeportivo).options(
        joinedload(EspacioDeportivo.sede), joinedload(EspacioDeportivo.deporte)
    )


@router.get(
    "",
    response_model=list[EspacioOut],
    summary="Listar espacios deportivos, con filtro por sede y por tipo",
)
def listar_espacios(
    sede_id: int | None = None,
    deporte_id: int | None = None,
    db: Session = Depends(get_db),
):
    consulta = _consulta_espacios().where(EspacioDeportivo.activo)
    if sede_id is not None:
        consulta = consulta.where(EspacioDeportivo.sede_id == sede_id)
    if deporte_id is not None:
        consulta = consulta.where(EspacioDeportivo.deporte_id == deporte_id)
    return db.scalars(consulta.order_by(EspacioDeportivo.id)).all()


@router.get(
    "/{espacio_id}",
    response_model=EspacioOut,
    summary="Ver un espacio deportivo",
    responses={404: {"description": "El espacio no existe"}},
)
def ver_espacio(espacio_id: int, db: Session = Depends(get_db)):
    espacio = db.scalar(_consulta_espacios().where(EspacioDeportivo.id == espacio_id))
    if espacio is None or not espacio.activo:
        raise HTTPException(status_code=404, detail="El espacio no existe")
    return espacio