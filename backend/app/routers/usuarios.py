from fastapi import APIRouter, Depends, HTTPException, Response
from firebase_admin import auth
from pydantic import BaseModel, Field
from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app.auth import token_actual, usuario_actual
from app.database import get_db
from app.models import Usuario
from app.schemas import UsuarioDatos, UsuarioOut

router = APIRouter(prefix="/api/v1/usuarios", tags=["Usuarios"])


def _dni_en_uso(db, dni, salvo_id=None):
    consulta = select(Usuario.id).where(Usuario.dni == dni)
    if salvo_id is not None:
        consulta = consulta.where(Usuario.id != salvo_id)
    return db.scalar(consulta) is not None


@router.post(
    "",
    response_model=UsuarioOut,
    status_code=201,
    summary="Crear el perfil del usuario recién registrado en Firebase",
    responses={
        401: {"description": "Falta el token o no es válido"},
        409: {"description": "El usuario ya está registrado (email o DNI)"},
    },
)
def crear_perfil(datos: UsuarioDatos, token: dict = Depends(token_actual), db: Session = Depends(get_db)):
    uid, email = token["uid"], token.get("email")
    if not email:
        raise HTTPException(status_code=400, detail="La cuenta de Firebase no tiene email")

    if db.scalar(select(Usuario.id).where(Usuario.firebase_uid == uid)):
        raise HTTPException(status_code=409, detail="El usuario ya está registrado")

    if db.scalar(select(Usuario.id).where(Usuario.email == email)) or _dni_en_uso(db, datos.dni):
        # la cuenta de firebase recien creada queda sin perfil, se borra
        # para que pueda volver a registrarse con otros datos
        try:
            auth.delete_user(uid)
        except Exception:
            pass
        raise HTTPException(status_code=409, detail="Ya existe un usuario registrado con ese email o DNI")

    usuario = Usuario(firebase_uid=uid, email=email, **datos.model_dump())
    db.add(usuario)
    db.commit()
    db.refresh(usuario)
    return usuario


@router.get(
    "/me",
    response_model=UsuarioOut,
    summary="Ver el perfil del usuario logueado",
    responses={401: {"description": "Sin sesión"}, 404: {"description": "Sin perfil"}},
)
def ver_perfil(usuario: Usuario = Depends(usuario_actual)):
    return usuario


@router.put(
    "/me",
    response_model=UsuarioOut,
    summary="Editar el perfil (el email no se puede cambiar)",
    responses={401: {"description": "Sin sesión"}, 409: {"description": "DNI en uso"}},
)
def editar_perfil(
    datos: UsuarioDatos,
    usuario: Usuario = Depends(usuario_actual),
    db: Session = Depends(get_db),
):
    if _dni_en_uso(db, datos.dni, salvo_id=usuario.id):
        raise HTTPException(status_code=409, detail="Ya existe un usuario con ese DNI")
    for campo, valor in datos.model_dump().items():
        setattr(usuario, campo, valor)
    db.commit()
    db.refresh(usuario)
    return usuario


class TokenFcm(BaseModel):
    # null al cerrar sesion: ese celular deja de recibir avisos de esta cuenta
    token: str | None = Field(default=None, max_length=512)


@router.put(
    "/me/token-fcm",
    status_code=204,
    summary="Guardar el token del celular para las notificaciones push",
    responses={401: {"description": "Sin sesión"}},
)
def guardar_token_fcm(
    datos: TokenFcm,
    usuario: Usuario = Depends(usuario_actual),
    db: Session = Depends(get_db),
):
    if datos.token:
        # si otra cuenta usaba este celular, deja de recibir avisos en el
        db.execute(
            update(Usuario)
            .where(Usuario.token_fcm == datos.token, Usuario.id != usuario.id)
            .values(token_fcm=None)
        )
    usuario.token_fcm = datos.token
    db.commit()
    return Response(status_code=204)


@router.delete(
    "/me",
    status_code=204,
    summary="Eliminar la cuenta y todas sus reservas",
    responses={401: {"description": "Sin sesión"}, 502: {"description": "Falló Firebase"}},
)
def eliminar_cuenta(usuario: Usuario = Depends(usuario_actual), db: Session = Depends(get_db)):
    db.delete(usuario)
    db.flush()
    try:
        auth.delete_user(usuario.firebase_uid)
    except auth.UserNotFoundError:
        pass  # ya no estaba en firebase
    except Exception:
        db.rollback()
        raise HTTPException(status_code=502, detail="No se pudo eliminar la cuenta, probá más tarde")
    db.commit()
    return Response(status_code=204)