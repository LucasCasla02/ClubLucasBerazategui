# reglas de horarios que se usan en disponibilidad y en reservas
from datetime import datetime, time
from zoneinfo import ZoneInfo

from sqlalchemy import select

from app.config import settings
from app.models import Reserva


# duracion maxima de una reserva, igual que en el figma (1 o 2 horas)
DURACION_MAXIMA_HORAS = 2


class ErrorDeRegla(Exception):
    pass


def ahora_argentina():
    return datetime.now(ZoneInfo(settings.zona_horaria))


def horario_efectivo(espacio):
    # el horario de la cancha recortado al de la sede
    apertura = max(espacio.hora_apertura, espacio.sede.hora_apertura)
    cierre = min(espacio.hora_cierre, espacio.sede.hora_cierre)
    return apertura, cierre


def es_futuro(fecha, hora_inicio, ahora):
    inicio = datetime.combine(fecha, hora_inicio, tzinfo=ahora.tzinfo)
    return inicio > ahora


def se_superpone(inicio, fin, ocupados):
    # dos rangos se pisan si uno empieza antes de que termine el otro
    return any(inicio < f and i < fin for i, f in ocupados)


def ocupados_por_espacio(db, espacio_ids, fecha):
    # {espacio_id: [(inicio, fin), ...]} con las reservas activas de ese dia
    filas = db.execute(
        select(Reserva.espacio_id, Reserva.hora_inicio, Reserva.hora_fin).where(
            Reserva.espacio_id.in_(espacio_ids),
            Reserva.fecha == fecha,
            Reserva.estado == "activa",
        )
    ).all()
    ocupados = {i: [] for i in espacio_ids}
    for espacio_id, inicio, fin in filas:
        ocupados[espacio_id].append((inicio, fin))
    return ocupados


def validar_fecha(fecha, ahora):
    if fecha < ahora.date():
        raise ErrorDeRegla("La fecha ya pasó")


def validar_rango(hora_inicio, hora_fin):
    if hora_inicio.minute or hora_inicio.second or hora_fin.minute or hora_fin.second:
        raise ErrorDeRegla("Los horarios tienen que ser en punto (por ejemplo 18:00)")
    if hora_fin <= hora_inicio:
        raise ErrorDeRegla("La hora de fin tiene que ser posterior a la de inicio")
    if hora_fin.hour - hora_inicio.hour > DURACION_MAXIMA_HORAS:
        raise ErrorDeRegla(f"La reserva puede durar como máximo {DURACION_MAXIMA_HORAS} horas")


def validar_dentro_del_horario(espacio, hora_inicio, hora_fin):
    apertura, cierre = horario_efectivo(espacio)
    if hora_inicio < apertura or hora_fin > cierre:
        raise ErrorDeRegla(
            f"El horario tiene que estar entre las {apertura:%H:%M} y las {cierre:%H:%M}"
        )


def franjas_del_dia(espacio, fecha, duracion, ocupados, ahora):
    # todas las horas de inicio posibles para esa duracion, marcando si estan libres
    apertura, cierre = horario_efectivo(espacio)
    franjas = []
    for hora in range(apertura.hour, cierre.hour - duracion + 1):
        inicio, fin = time(hora), time(hora + duracion)
        libre = es_futuro(fecha, inicio, ahora) and not se_superpone(inicio, fin, ocupados)
        franjas.append({"hora_inicio": inicio, "hora_fin": fin, "disponible": libre})
    return franjas