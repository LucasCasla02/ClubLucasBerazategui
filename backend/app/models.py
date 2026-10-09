"""Modelo de datos

Entidades: Usuario, Sede, Deporte, EspacioDeportivo y Reserva.
"""
from datetime import date, datetime, time
from decimal import Decimal

from sqlalchemy import (
    CheckConstraint,
    Date,
    DateTime,
    ForeignKey,
    Index,
    Numeric,
    String,
    Time,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Usuario(Base):
    """Persona registrada en la app. La contraseña NO se guarda acá: la maneja Firebase."""

    __tablename__ = "usuarios"

    id: Mapped[int] = mapped_column(primary_key=True)
    # Identificador que Firebase le da a la cuenta. Une esta tabla con Firebase.
    firebase_uid: Mapped[str] = mapped_column(String(128), unique=True)
    email: Mapped[str] = mapped_column(String(255), unique=True)
    nombre: Mapped[str] = mapped_column(String(100))
    apellido: Mapped[str] = mapped_column(String(100))
    dni: Mapped[str] = mapped_column(String(10), unique=True)
    fecha_nacimiento: Mapped[date] = mapped_column(Date)
    # Token del celular para mandarle notificaciones push (puede no tenerlo todavía)
    token_fcm: Mapped[str | None] = mapped_column(String(512))
    creado_en: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    # Un usuario tiene muchas reservas. Si se elimina la cuenta, se eliminan sus reservas.
    reservas: Mapped[list["Reserva"]] = relationship(
        back_populates="usuario", cascade="all, delete-orphan"
    )


class Sede(Base):
    """Predio del club, con su horario de funcionamiento (igual todos los días)."""

    __tablename__ = "sedes"
    __table_args__ = (
        CheckConstraint("hora_apertura < hora_cierre", name="ck_sede_horario_valido"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    nombre: Mapped[str] = mapped_column(String(100), unique=True)
    direccion: Mapped[str] = mapped_column(String(200))
    hora_apertura: Mapped[time] = mapped_column(Time)
    hora_cierre: Mapped[time] = mapped_column(Time)

    # Una sede tiene muchos espacios deportivos.
    espacios: Mapped[list["EspacioDeportivo"]] = relationship(back_populates="sede")


class Deporte(Base):
    """Tipo de espacio deportivo (Fútbol, Tenis...). Es el filtro que pide la consigna."""

    __tablename__ = "deportes"

    id: Mapped[int] = mapped_column(primary_key=True)
    nombre: Mapped[str] = mapped_column(String(50), unique=True)

    espacios: Mapped[list["EspacioDeportivo"]] = relationship(back_populates="deporte")


class EspacioDeportivo(Base):
    """Cancha concreta dentro de una sede."""

    __tablename__ = "espacios"
    __table_args__ = (
        UniqueConstraint(
            "sede_id", "deporte_id", "variante", "numero", name="uq_espacio_por_sede"
        ),
        CheckConstraint("hora_apertura < hora_cierre", name="ck_espacio_horario_valido"),
        CheckConstraint("precio_por_hora > 0", name="ck_espacio_precio_positivo"),
        CheckConstraint("ambiente IN ('Indoor', 'Outdoor')", name="ck_espacio_ambiente"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    sede_id: Mapped[int] = mapped_column(ForeignKey("sedes.id"))
    deporte_id: Mapped[int] = mapped_column(ForeignKey("deportes.id"))
    # Modalidad dentro del deporte: "Fútbol 5", "Polvo de Ladrillo", etc.
    variante: Mapped[str] = mapped_column(String(50))
    numero: Mapped[int]
    # Nombre compuesto que pide la consigna, ej: Moron_Rivadavia_17500_Futbol_F5_1
    nombre: Mapped[str] = mapped_column(String(150), unique=True)
    ambiente: Mapped[str] = mapped_column(String(10))
    iluminada: Mapped[bool]
    # Numeric (y no float) porque es dinero: evita errores de redondeo.
    precio_por_hora: Mapped[Decimal] = mapped_column(Numeric(10, 2))
    # Franja propia de la cancha. Siempre dentro del horario de su sede.
    hora_apertura: Mapped[time] = mapped_column(Time)
    hora_cierre: Mapped[time] = mapped_column(Time)
    activo: Mapped[bool] = mapped_column(default=True)

    sede: Mapped["Sede"] = relationship(back_populates="espacios")
    deporte: Mapped["Deporte"] = relationship(back_populates="espacios")
    reservas: Mapped[list["Reserva"]] = relationship(back_populates="espacio")


class Reserva(Base):
    """Reserva de un espacio deportivo para una fecha y un rango de horas completas."""

    __tablename__ = "reservas"
    __table_args__ = (
        CheckConstraint("hora_inicio < hora_fin", name="ck_reserva_fin_despues_inicio"),
        CheckConstraint(
            "EXTRACT(MINUTE FROM hora_inicio) = 0 AND EXTRACT(MINUTE FROM hora_fin) = 0",
            name="ck_reserva_horas_completas",
        ),
        CheckConstraint("estado IN ('activa', 'cancelada')", name="ck_reserva_estado"),
        # Acelera la búsqueda de reservas de una cancha en un día (disponibilidad)
        Index("ix_reservas_espacio_fecha", "espacio_id", "fecha"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    usuario_id: Mapped[int] = mapped_column(ForeignKey("usuarios.id", ondelete="CASCADE"))
    espacio_id: Mapped[int] = mapped_column(ForeignKey("espacios.id"))
    fecha: Mapped[date] = mapped_column(Date)
    hora_inicio: Mapped[time] = mapped_column(Time)
    hora_fin: Mapped[time] = mapped_column(Time)
    estado: Mapped[str] = mapped_column(String(20), default="activa")
    # Se guarda el monto al reservar: si después cambia el precio, la reserva conserva el suyo.
    monto_total: Mapped[Decimal] = mapped_column(Numeric(10, 2))
    creada_en: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    cancelada_en: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    # Marcas para no mandar dos veces el mismo recordatorio push (CU-24)
    recordatorio_24h_enviado: Mapped[bool] = mapped_column(default=False)
    recordatorio_1h_enviado: Mapped[bool] = mapped_column(default=False)

    usuario: Mapped["Usuario"] = relationship(back_populates="reservas")
    espacio: Mapped["EspacioDeportivo"] = relationship(back_populates="reservas")