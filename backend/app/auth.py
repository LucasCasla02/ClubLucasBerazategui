# verifica el token de firebase que manda la app en cada request
from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from firebase_admin import auth
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Usuario

esquema_bearer = HTTPBearer(auto_error=False, description="ID token de Firebase")


def _no_autorizado(mensaje):
    return HTTPException(status_code=401, detail=mensaje, headers={"WWW-Authenticate": "Bearer"})


def token_actual(credenciales: HTTPAuthorizationCredentials | None = Depends(esquema_bearer)):
    if credenciales is None:
        raise _no_autorizado("Falta el token de sesión")
    try:
        return auth.verify_id_token(credenciales.credentials)
    except auth.CertificateFetchError:
        raise HTTPException(status_code=503, detail="No se pudo validar la sesión, probá más tarde")
    except (auth.InvalidIdTokenError, ValueError):
        raise _no_autorizado("La sesión no es válida o venció")


def usuario_actual(token: dict = Depends(token_actual), db: Session = Depends(get_db)):
    usuario = db.scalar(select(Usuario).where(Usuario.firebase_uid == token["uid"]))
    if usuario is None:
        raise HTTPException(status_code=404, detail="El usuario no tiene perfil creado")
    return usuario