"""Conexión con PostgreSQL usando SQLAlchemy."""
from sqlalchemy import URL, create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker

from app.config import settings


def _armar_url():
    # En Render: usamos la URL completa que nos da Render.
    if settings.database_url:
        url = settings.database_url
        # SQLAlchemy necesita saber que usamos el driver "psycopg"
        if url.startswith("postgres://"):
            url = "postgresql://" + url[len("postgres://"):]
        return url.replace("postgresql://", "postgresql+psycopg://", 1)

    # En tu compu: armamos la URL con los datos del .env.
    # URL.create se encarga de los caracteres especiales de la contraseña.
    return URL.create(
        drivername="postgresql+psycopg",
        username=settings.db_user,
        password=settings.db_password,
        host=settings.db_host,
        port=settings.db_port,
        database=settings.db_name,
    )


# El "engine" es la conexión principal con la base.
# pool_pre_ping revisa que la conexión siga viva antes de usarla.
engine = create_engine(_armar_url(), pool_pre_ping=True)

# Cada pedido a la API abre una "sesión" (una conversación con la base).
SessionLocal = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)


class Base(DeclarativeBase):
    """Clase base de la que heredan todas las tablas (models.py)."""


def get_db():
    """Abre una sesión para cada pedido y la cierra al terminar."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()