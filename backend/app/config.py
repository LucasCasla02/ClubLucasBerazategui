"""Configuración de la API.

Lee los valores del archivo .env (en tu compu) o de las variables de
entorno (en Render). Así las contraseñas nunca quedan escritas en el código.
"""
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # Datos de la base local
    db_host: str = "localhost"
    db_port: int = 5432
    db_name: str = "club_db"
    db_user: str = "postgres"
    db_password: str = ""

    # URL completa que entrega Render. Si tiene valor, tiene prioridad.
    database_url: str = ""

    # Zona horaria del club: las reservas se validan con la hora de Argentina
    zona_horaria: str = "America/Argentina/Buenos_Aires"

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")


settings = Settings()