from datetime import date, datetime, time, timedelta
from typing import Annotated

from pydantic import BaseModel, ConfigDict, StringConstraints, field_validator


class DeporteOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    nombre: str


class SedeResumen(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    nombre: str
    direccion: str


class SedeOut(SedeResumen):
    hora_apertura: time
    hora_cierre: time
    cantidad_espacios: int
    deportes: list[str]


class EspacioOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    nombre: str
    variante: str
    numero: int
    ambiente: str
    iluminada: bool
    precio_por_hora: float
    hora_apertura: time
    hora_cierre: time
    deporte: DeporteOut
    sede: SedeResumen


class EspacioDisponibleOut(EspacioOut):
    monto_total: float


class FranjaHoraria(BaseModel):
    hora_inicio: time
    hora_fin: time
    disponible: bool


class HorariosOut(BaseModel):
    espacio_id: int
    fecha: date
    duracion: int
    precio_por_hora: float
    franjas: list[FranjaHoraria]


Texto = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=100)]
Dni = Annotated[str, StringConstraints(strip_whitespace=True, pattern=r"^\d{7,8}$")]


class UsuarioDatos(BaseModel):
    model_config = ConfigDict(
        json_schema_extra={
            "examples": [
                {
                    "nombre": "Lucas",
                    "apellido": "Berazategui",
                    "dni": "40123456",
                    "fecha_nacimiento": "2000-05-10",
                }
            ]
        }
    )

    nombre: Texto
    apellido: Texto
    dni: Dni
    fecha_nacimiento: date

    @field_validator("fecha_nacimiento")
    @classmethod
    def fecha_valida(cls, valor):
        if valor >= date.today() or valor.year < 1900:
            raise ValueError("fecha de nacimiento inválida")
        return valor


class UsuarioOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    email: str
    nombre: str
    apellido: str
    dni: str
    fecha_nacimiento: date
    creado_en: datetime


class ReservaCrear(BaseModel):
    # el ejemplo usa la fecha de mañana para que se pueda probar directo
    model_config = ConfigDict(
        json_schema_extra={
            "examples": [
                {
                    "espacio_id": 1,
                    "fecha": (date.today() + timedelta(days=1)).isoformat(),
                    "hora_inicio": "18:00",
                    "hora_fin": "20:00",
                }
            ]
        }
    )

    espacio_id: int
    fecha: date
    hora_inicio: time
    hora_fin: time


class ReservaOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    fecha: date
    hora_inicio: time
    hora_fin: time
    # activa / cancelada (lo que esta guardado)
    estado: str
    # activa / completada / cancelada (calculado con la hora actual)
    estado_actual: str
    monto_total: float
    creada_en: datetime
    cancelada_en: datetime | None
    espacio: EspacioOut


class ErrorValidacion(BaseModel):
    detail: str
    campos: list[str]
