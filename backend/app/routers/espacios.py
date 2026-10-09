from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from app.database import get_db
from app.models import EspacioDeportivo
from app.reglas import (
    DURACION_MAXIMA_HORAS,
    ErrorDeRegla,
    ahora_argentina,
    franjas_del_dia,
    ocupados_por_espacio,
    validar_fecha,
)
from app.schemas import EspacioOut, HorariosOut

router = APIRouter(prefix="/api/v1/espacios", tags=["Espacios deportivos"])


def _consulta_espacios():
    return select(EspacioDeportivo).options(
        joinedload(EspacioDeportivo.sede), joinedload(EspacioDeportivo.deporte)
    )


def _buscar_espacio(db, espacio_id):
    espacio = db.scalar(_consulta_espacios().where(EspacioDeportivo.id == espacio_id))
    if espacio is None or not espacio.activo:
        raise HTTPException(status_code=404, detail="El espacio no existe")
    return espacio


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
    return _buscar_espacio(db, espacio_id)


@router.get(
    "/{espacio_id}/horarios",
    response_model=HorariosOut,
    summary="Ver los horarios libres y ocupados de un espacio en una fecha",
    responses={
        400: {"description": "La fecha ya pasó"},
        404: {"description": "El espacio no existe"},
    },
)
def ver_horarios(
    espacio_id: int,
    fecha: date,
    duracion: int = Query(1, ge=1, le=DURACION_MAXIMA_HORAS, description="Duración en horas"),
    db: Session = Depends(get_db),
):
    espacio = _buscar_espacio(db, espacio_id)
    ahora = ahora_argentina()
    try:
        validar_fecha(fecha, ahora)
    except ErrorDeRegla as e:
        raise HTTPException(status_code=400, detail=str(e))

    ocupados = ocupados_por_espacio(db, [espacio.id], fecha)[espacio.id]
    return HorariosOut(
        espacio_id=espacio.id,
        fecha=fecha,
        duracion=duracion,
        precio_por_hora=espacio.precio_por_hora,
        franjas=franjas_del_dia(espacio, fecha, duracion, ocupados, ahora),
    )