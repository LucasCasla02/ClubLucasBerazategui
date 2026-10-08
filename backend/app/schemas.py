from datetime import date, time

from pydantic import BaseModel, ConfigDict


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