import secrets

from fastapi import APIRouter, Depends, Header, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.models import Usuario
from app.notificaciones import enviar, procesar_recordatorios

router = APIRouter(prefix="/api/v1/admin", tags=["Notificaciones"])


# estos endpoints son para el administrador: se protegen con una clave propia (CLAVE_ADMIN)
def clave_admin(x_clave_admin: str | None = Header(default=None, description="Clave de administrador")):
    if not settings.clave_admin:
        raise HTTPException(status_code=503, detail="Falta configurar CLAVE_ADMIN en el servidor")
    # compare_digest compara sin dar pistas por el tiempo que tarda
    if not x_clave_admin or not secrets.compare_digest(x_clave_admin, settings.clave_admin):
        raise HTTPException(status_code=403, detail="Clave de administrador incorrecta")


@router.post(
    "/notificaciones/probar",
    summary="Enviar una notificación de prueba al celular de un usuario",
    dependencies=[Depends(clave_admin)],
    responses={
        403: {"description": "Clave incorrecta"},
        404: {"description": "No existe un usuario con ese email"},
        409: {"description": "El usuario no tiene un celular registrado"},
    },
)
def probar(email: str = Query(description="Email del usuario"), db: Session = Depends(get_db)):
    usuario = db.scalar(select(Usuario).where(Usuario.email == email.strip()))
    if usuario is None:
        raise HTTPException(status_code=404, detail="No existe un usuario con ese email")
    if not usuario.token_fcm:
        raise HTTPException(
            status_code=409,
            detail="El usuario no tiene un celular registrado: tiene que iniciar sesión en la app",
        )

    resultado = enviar(
        usuario.token_fcm,
        "Club Lucas Berazategui",
        f"Hola {usuario.nombre}, las notificaciones funcionan.",
    )
    if resultado == "token_invalido":
        usuario.token_fcm = None
        db.commit()
        raise HTTPException(status_code=409, detail="El token del celular ya no es válido")
    if resultado == "error":
        raise HTTPException(status_code=502, detail="Firebase no pudo enviar la notificación")
    return {"enviado": True}


@router.post(
    "/recordatorios/ejecutar",
    summary="Ejecutar ahora los recordatorios (sin esperar la revisión automática de 5 minutos)",
    dependencies=[Depends(clave_admin)],
    responses={403: {"description": "Clave incorrecta"}},
)
def ejecutar_recordatorios(db: Session = Depends(get_db)):
    return {"enviados": procesar_recordatorios(db)}