"""Configuración de la API.

Lee los valores del archivo .env o de las variables de
entorno (en Render). Así las contraseñas nunca quedan escritas en el código.
"""
from pydantic_settings import BaseSettings, SettingsConfigDict


# lee la configuracion del .env (en render salen de las variables de entorno)
class Settings(BaseSettings):
    db_host: str = "localhost"
    db_port: int = 5432
    db_name: str = "club_db"
    db_user: str = "postgres"
    db_password: str = ""

    # si esta cargada se usa esta en vez de los datos de arriba
    database_url: str = ""

    zona_horaria: str = "America/Argentina/Buenos_Aires"

    # firebase: ruta al json (local) o el contenido del json (render)
    firebase_credenciales: str = ""
    firebase_credenciales_json: str = ""
    # solo para el script de prueba obtener_token.py
    firebase_api_key: str = ""

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")


settings = Settings()
