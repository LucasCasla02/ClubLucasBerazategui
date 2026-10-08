from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Deporte
from app.schemas import DeporteOut

router = APIRouter(prefix="/api/v1/deportes", tags=["Deportes"])


@router.get("", response_model=list[DeporteOut], summary="Listar los tipos de espacio deportivo")
def listar_deportes(db: Session = Depends(get_db)):
    return db.scalars(select(Deporte).order_by(Deporte.nombre)).all()