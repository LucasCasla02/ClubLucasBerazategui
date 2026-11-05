"""Notificaciones push con Firebase Cloud Messaging (CU-24).

La API no le habla directo al celular: le pide a Firebase que mande el aviso
al token que la app guardó en usuarios.token_fcm.
"""
from datetime import datetime, timedelta

from firebase_admin import exceptions, messaging
from sqlalchemy import select
from sqlalchemy.orm import joinedload

from app.models import EspacioDeportivo, Reserva, Usuario
from app.reglas import ahora_argentina

UNA_HORA = timedelta(hours=1)
UN_DIA = timedelta(hours=24)


def enviar(token, titulo, cuerpo):
    """Manda un aviso a un celular. Devuelve "ok", "token_invalido" o "error"."""
    mensaje = messaging.Message(
        token=token,
        notification=messaging.Notification(title=titulo, body=cuerpo),
        # prioridad alta para que llegue aunque el celular este en reposo
        android=messaging.AndroidConfig(priority="high"),
    )
    try:
        messaging.send(mensaje)
        return "ok"
    except messaging.UnregisteredError:
        # la app se desinstalo o el token vencio: ese token ya no sirve
        return "token_invalido"
    except (exceptions.FirebaseError, ValueError):
        return "error"


def _detalle(reserva):
    espacio = reserva.espacio
    return (
        f"Sede {espacio.sede.nombre} · {espacio.variante} · Cancha {espacio.numero} · "
        f"{reserva.fecha:%d/%m} de {reserva.hora_inicio:%H:%M} a {reserva.hora_fin:%H:%M}"
    )


def procesar_recordatorios(db, ahora=None):
    """Manda los recordatorios de 24 h y 1 h que falten. Se puede llamar muchas veces:
    cada reserva guarda si ya se le mando cada aviso, asi nunca se repite."""
    ahora = ahora or ahora_argentina()
    hoy = ahora.date()

    # reservas activas de hoy y mañana, de usuarios con celular registrado,
    # a las que todavia les falta algun aviso
    reservas = db.scalars(
        select(Reserva)
        .join(Reserva.usuario)
        .where(
            Reserva.estado == "activa",
            Reserva.fecha.between(hoy, hoy + timedelta(days=1)),
            Usuario.token_fcm.is_not(None),
            Reserva.recordatorio_1h_enviado.is_(False),
        )
        .options(
            joinedload(Reserva.usuario),
            joinedload(Reserva.espacio).joinedload(EspacioDeportivo.sede),
        )
    ).all()

    enviados = {"24h": 0, "1h": 0}
    for reserva in reservas:
        inicio = datetime.combine(reserva.fecha, reserva.hora_inicio, tzinfo=ahora.tzinfo)
        falta = inicio - ahora
        if falta <= timedelta(0):
            continue  # ya empezo, no tiene sentido avisar

        if falta <= UNA_HORA:
            tipo, titulo = "1h", "Tu reserva comienza en 1 hora"
        elif falta <= UN_DIA and not reserva.recordatorio_24h_enviado:
            tipo = "24h"
            titulo = "Tenés una reserva hoy" if reserva.fecha == hoy else "Tenés una reserva mañana"
        else:
            continue

        resultado = enviar(reserva.usuario.token_fcm, titulo, _detalle(reserva))
        if resultado == "token_invalido":
            reserva.usuario.token_fcm = None
            continue
        if resultado == "error":
            continue  # se reintenta en la proxima revision

        # el de 1 h tambien cuenta como el de 24 h (no tiene sentido mandarlo despues)
        reserva.recordatorio_24h_enviado = True
        if tipo == "1h":
            reserva.recordatorio_1h_enviado = True
        enviados[tipo] += 1

    db.commit()
    return enviados