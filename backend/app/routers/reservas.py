from datetime import datetime
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from app.auth import usuario_actual
from app.database import get_db
from app.models import EspacioDeportivo, Reserva, Usuario
from app.reglas import (
    ErrorDeRegla,
    ahora_argentina,
    es_futuro,
    ocupados_por_espacio,
    se_superpone,
    validar_dentro_del_horario,
    validar_fecha,
    validar_rango,
)
from app.schemas import ReservaCrear, ReservaOut

router = APIRouter(prefix="/api/v1/reservas", tags=["Reservas"])


def _termino(reserva, ahora):
    fin = datetime.combine(reserva.fecha, reserva.hora_fin, tzinfo=ahora.tzinfo)
    return fin <= ahora


def _a_reserva_out(reserva, ahora):
    if reserva.estado == "cancelada":
        estado_actual = "cancelada"
    elif _termino(reserva, ahora):
        estado_actual = "completada"
    else:
        estado_actual = "activa"
    datos = {c: getattr(reserva, c) for c in ReservaOut.model_fields if c != "estado_actual"}
    return ReservaOut(**datos, estado_actual=estado_actual)


def _consulta_reservas(usuario_id):
    return (
        select(Reserva)
        .where(Reserva.usuario_id == usuario_id)
        .options(
            joinedload(Reserva.espacio).joinedload(EspacioDeportivo.sede),
            joinedload(Reserva.espacio).joinedload(EspacioDeportivo.deporte),
        )
    )


def _buscar_reserva_propia(db, reserva_id, usuario):
    # si la reserva es de otro usuario respondemos 404, como si no existiera
    reserva = db.scalar(_consulta_reservas(usuario.id).where(Reserva.id == reserva_id))
    if reserva is None:
        raise HTTPException(status_code=404, detail="La reserva no existe")
    return reserva


@router.post(
    "",
    response_model=ReservaOut,
    status_code=201,
    summary="Reservar un espacio deportivo",
    responses={
        400: {"description": "Fecha u horario inválido"},
        401: {"description": "Sin sesión"},
        404: {"description": "El espacio no existe"},
        409: {"description": "El horario ya está ocupado o ya tenés otra reserva a esa hora"},
    },
)
def crear_reserva(
    datos: ReservaCrear,
    usuario: Usuario = Depends(usuario_actual),
    db: Session = Depends(get_db),
):
    # bloquea la fila de la cancha hasta el commit: si dos personas reservan
    # al mismo tiempo, la segunda espera y despues ve la reserva de la primera
    espacio = db.scalar(
        select(EspacioDeportivo)
        .where(EspacioDeportivo.id == datos.espacio_id)
        .with_for_update()
    )
    if espacio is None or not espacio.activo:
        raise HTTPException(status_code=404, detail="El espacio no existe")

    ahora = ahora_argentina()
    try:
        validar_fecha(datos.fecha, ahora)
        validar_rango(datos.hora_inicio, datos.hora_fin)
        validar_dentro_del_horario(espacio, datos.hora_inicio, datos.hora_fin)
        if not es_futuro(datos.fecha, datos.hora_inicio, ahora):
            raise ErrorDeRegla("Solo se puede reservar un horario futuro")
    except ErrorDeRegla as e:
        raise HTTPException(status_code=400, detail=str(e))

    ocupados = ocupados_por_espacio(db, [espacio.id], datos.fecha)[espacio.id]
    if se_superpone(datos.hora_inicio, datos.hora_fin, ocupados):
        raise HTTPException(
            status_code=409,
            detail="El horario seleccionado ya no está disponible. Elegí otro horario.",
        )

    # el usuario tampoco puede tener otra reserva a la misma hora (en ninguna cancha).
    # se bloquea su fila para que dos pedidos suyos al mismo tiempo no pasen los dos
    db.execute(select(Usuario.id).where(Usuario.id == usuario.id).with_for_update())
    mias = db.execute(
        select(Reserva.hora_inicio, Reserva.hora_fin).where(
            Reserva.usuario_id == usuario.id,
            Reserva.fecha == datos.fecha,
            Reserva.estado == "activa",
        )
    ).all()
    if se_superpone(datos.hora_inicio, datos.hora_fin, mias):
        raise HTTPException(
            status_code=409, detail="Ya tenés otra reserva en ese horario."
        )

    horas = datos.hora_fin.hour - datos.hora_inicio.hour
    reserva = Reserva(
        usuario_id=usuario.id,
        espacio_id=espacio.id,
        fecha=datos.fecha,
        hora_inicio=datos.hora_inicio,
        hora_fin=datos.hora_fin,
        estado="activa",
        monto_total=espacio.precio_por_hora * horas,
    )
    db.add(reserva)
    db.commit()
    return _a_reserva_out(_buscar_reserva_propia(db, reserva.id, usuario), ahora)


@router.get(
    "/mis-reservas",
    response_model=list[ReservaOut],
    summary="Listar mis reservas: próximas o historial completo",
    responses={401: {"description": "Sin sesión"}},
)
def mis_reservas(
    tipo: Literal["proximas", "historial"] = "proximas",
    usuario: Usuario = Depends(usuario_actual),
    db: Session = Depends(get_db),
):
    ahora = ahora_argentina()
    reservas = db.scalars(_consulta_reservas(usuario.id)).all()

    if tipo == "proximas":
        lista = [r for r in reservas if r.estado == "activa" and not _termino(r, ahora)]
        lista.sort(key=lambda r: (r.fecha, r.hora_inicio))
    else:
        # todas, de la mas nueva a la mas vieja
        lista = sorted(reservas, key=lambda r: (r.fecha, r.hora_inicio), reverse=True)
    return [_a_reserva_out(r, ahora) for r in lista]


@router.get(
    "/{reserva_id}",
    response_model=ReservaOut,
    summary="Ver el detalle de una reserva propia",
    responses={401: {"description": "Sin sesión"}, 404: {"description": "No existe"}},
)
def ver_reserva(
    reserva_id: int,
    usuario: Usuario = Depends(usuario_actual),
    db: Session = Depends(get_db),
):
    return _a_reserva_out(_buscar_reserva_propia(db, reserva_id, usuario), ahora_argentina())


@router.delete(
    "/{reserva_id}",
    response_model=ReservaOut,
    summary="Cancelar una reserva propia (el horario vuelve a quedar libre)",
    responses={
        400: {"description": "La reserva ya empezó o terminó"},
        401: {"description": "Sin sesión"},
        404: {"description": "No existe"},
        409: {"description": "Ya estaba cancelada"},
    },
)
def cancelar_reserva(
    reserva_id: int,
    usuario: Usuario = Depends(usuario_actual),
    db: Session = Depends(get_db),
):
    reserva = _buscar_reserva_propia(db, reserva_id, usuario)
    ahora = ahora_argentina()

    if reserva.estado == "cancelada":
        raise HTTPException(status_code=409, detail="La reserva ya estaba cancelada")
    if not es_futuro(reserva.fecha, reserva.hora_inicio, ahora):
        raise HTTPException(
            status_code=400, detail="No se pueden cancelar reservas pasadas o en curso"
        )

    reserva.estado = "cancelada"
    reserva.cancelada_en = ahora
    db.commit()
    return _a_reserva_out(reserva, ahora)