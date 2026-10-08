import json

import firebase_admin
from firebase_admin import credentials

from app.config import settings


def iniciar_firebase():
    try:
        firebase_admin.get_app()
        return  # ya estaba iniciado
    except ValueError:
        pass

    if settings.firebase_credenciales_json:
        cred = credentials.Certificate(json.loads(settings.firebase_credenciales_json))
    elif settings.firebase_credenciales:
        cred = credentials.Certificate(settings.firebase_credenciales)
    else:
        raise RuntimeError("Faltan las credenciales de Firebase en el .env")
    firebase_admin.initialize_app(cred)