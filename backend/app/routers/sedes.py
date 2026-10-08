from datetime import date, time

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.database import get_db
from app.models import EspacioDeportivo, Sede
from app.reglas import (
    ErrorDeRegla,
    ahora_argentina,
    es_futuro,
    horario_efectivo,
    ocupados_por_espacio,
    se_superpone,
    validar_fecha,
    validar_rango,
)
from app.schemas import EspacioDisponibleOut, EspacioOut, SedeOut

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


def _buscar_sede(db, sede_id):
    sede = db.scalar(_consulta_sedes().where(Sede.id == sede_id))
    if sede is None:
        raise HTTPException(status_code=404, detail="La sede no existe")
    return sede


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
    return _a_sede_out(_buscar_sede(db, sede_id))


@router.get(
    "/{sede_id}/disponibilidad",
    response_model=list[EspacioDisponibleOut],
    summary="Ver qué espacios de una sede están libres en una fecha y rango horario",
    responses={
        400: {"description": "Fecha u horario inválido"},
        404: {"description": "La sede no existe"},
    },
)
def ver_disponibilidad(
    sede_id: int,
    fecha: date,
    hora_inicio: time,
    hora_fin: time,
    deporte_id: int | None = None,
    db: Session = Depends(get_db),
):
    sede = _buscar_sede(db, sede_id)
    ahora = ahora_argentina()
    try:
        validar_fecha(fecha, ahora)
        validar_rango(hora_inicio, hora_fin)
        if hora_inicio < sede.hora_apertura or hora_fin > sede.hora_cierre:
            raise ErrorDeRegla(
                f"La sede abre de {sede.hora_apertura:%H:%M} a {sede.hora_cierre:%H:%M}"
            )
        if not es_futuro(fecha, hora_inicio, ahora):
            raise ErrorDeRegla("El horario ya pasó")
    except ErrorDeRegla as e:
        raise HTTPException(status_code=400, detail=str(e))

    espacios = [
        e for e in sede.espacios
        if e.activo and (deporte_id is None or e.deporte_id == deporte_id)
    ]
    ocupados = ocupados_por_espacio(db, [e.id for e in espacios], fecha)
    horas = hora_fin.hour - hora_inicio.hour

    libres = []
    for espacio in sorted(espacios, key=lambda e: e.id):
        apertura, cierre = horario_efectivo(espacio)
        if hora_inicio < apertura or hora_fin > cierre:
            continue  # la cancha no abre en ese horario
        if se_superpone(hora_inicio, hora_fin, ocupados[espacio.id]):
            continue
        datos = EspacioOut.model_validate(espacio).model_dump()
        libres.append(
            EspacioDisponibleOut(**datos, monto_total=espacio.precio_por_hora * horas)
        )
    return libres