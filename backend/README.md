# Backend ClubLucasBerazategui

API REST de la app de reservas de espacios deportivos.

- **Python 3.13** con **FastAPI**
- **PostgreSQL 18** con **SQLAlchemy**
- **Firebase Authentication** para el login (las contraseñas las maneja Firebase, no esta base)
- Documentación automática con **Swagger / OpenAPI** en `/docs`

## Requisitos

- Python 3.13
- PostgreSQL (local o en la nube)
- Un proyecto de Firebase con Authentication habilitado (proveedor Email/Contraseña)

## 1. Instalación

Desde la carpeta `backend`:

```
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

En Linux o macOS, el entorno se activa con `source .venv/bin/activate`.

## 2. Base de datos

Crear una base vacía en PostgreSQL, por ejemplo `club_db` (desde pgAdmin o con `CREATE DATABASE club_db;`).

## 3. Credencial de Firebase

En la consola de Firebase: **Configuración del proyecto → Cuentas de servicio → Generar nueva clave privada**.

El archivo `.json` que se descarga es secreto. Se guarda **fuera** de la carpeta del repositorio, por ejemplo en `C:/dev/secretos/firebase-credenciales.json`. Nunca se sube a GitHub.

## 4. Configuración (`.env`)

Copiar `.env.example` con el nombre `.env` y completar:

| Variable | Descripción |
|---|---|
| `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` | Datos de la base local |
| `DATABASE_URL` | URL completa de la base. Si está cargada, se usa en lugar de las variables anteriores (es lo que se usa en Render) |
| `FIREBASE_CREDENCIALES` | Ruta al `.json` de la cuenta de servicio |
| `FIREBASE_CREDENCIALES_JSON` | Contenido del `.json`, como alternativa a la ruta (para la nube) |
| `FIREBASE_API_KEY` | Clave web de Firebase. Solo la usa el script de prueba `obtener_token.py` |

El `.env` está en el `.gitignore` y no se sube al repositorio.

## 5. Crear las tablas y cargar los datos

```
python cargar_datos.py
```

Crea las tablas y carga las 4 sedes, los 5 deportes y las 22 canchas del diseño. Se puede ejecutar más de una vez: no duplica ni borra datos.

## 6. Ejecutar

```
uvicorn app.main:app --reload
```

- API: http://127.0.0.1:8000
- Swagger: http://127.0.0.1:8000/docs
- Estado: http://127.0.0.1:8000/api/v1/salud

## 7. Probar endpoints protegidos

Los endpoints de usuarios y reservas necesitan el token de Firebase del usuario (header `Authorization: Bearer <token>`). Para obtener uno sin la app:

```
python obtener_token.py prueba@test.com Prueba123
```

Crea el usuario en Firebase si no existe (o inicia sesión si ya existe) y muestra el token. En Swagger se pega en el botón **Authorize**. El token dura una hora.

## Endpoints

| Método | Ruta | Auth | Descripción |
|---|---|---|---|
| GET | `/api/v1/sedes` | No | Sedes con horario, cantidad de canchas y deportes |
| GET | `/api/v1/sedes/{id}` | No | Una sede |
| GET | `/api/v1/sedes/{id}/disponibilidad` | No | Canchas libres de la sede en una fecha y rango horario |
| GET | `/api/v1/deportes` | No | Tipos de espacio deportivo |
| GET | `/api/v1/espacios` | No | Canchas, con filtro por `sede_id` y `deporte_id` |
| GET | `/api/v1/espacios/{id}` | No | Una cancha |
| GET | `/api/v1/espacios/{id}/horarios` | No | Grilla de horarios libres y ocupados de una fecha |
| POST | `/api/v1/usuarios` | Sí | Crear el perfil después de registrarse en Firebase |
| GET | `/api/v1/usuarios/me` | Sí | Ver mi perfil |
| PUT | `/api/v1/usuarios/me` | Sí | Editar mi perfil (el email no se puede cambiar) |
| DELETE | `/api/v1/usuarios/me` | Sí | Eliminar mi cuenta y mis reservas |
| POST | `/api/v1/reservas` | Sí | Reservar |
| GET | `/api/v1/reservas/mis-reservas` | Sí | Mis reservas (`tipo=proximas` o `tipo=historial`) |
| GET | `/api/v1/reservas/{id}` | Sí | Detalle de una reserva propia |
| DELETE | `/api/v1/reservas/{id}` | Sí | Cancelar una reserva propia |
| GET | `/api/v1/salud` | No | Estado de la API y la base |

## Reglas de las reservas

- Horas completas (18:00, no 18:30), con una duración de 1 o 2 horas.
- Dentro del horario de la sede y de la cancha.
- Solo horarios futuros, con la hora de Argentina (`America/Argentina/Buenos_Aires`).
- Sin superposición con otra reserva activa de la misma cancha. Al reservar se bloquea la fila de la cancha para que dos pedidos simultáneos no puedan reservar el mismo horario.
- Un mismo usuario no puede tener dos reservas activas que se superpongan, aunque sean en canchas distintas.
- Al cancelar, la reserva queda en el historial como cancelada y el horario vuelve a estar libre. No se pueden cancelar reservas que ya empezaron.

## Códigos de error

| Código | Cuándo |
|---|---|
| 400 | Fecha u horario inválido según las reglas |
| 401 | Falta el token o no es válido |
| 404 | No existe (o no es del usuario) |
| 409 | Conflicto: usuario ya registrado, horario ocupado, otra reserva propia a la misma hora, reserva ya cancelada |
| 422 | Datos con formato inválido |
| 503 | Sin conexión con la base de datos |

## Estructura

```
backend/
├── app/
│   ├── main.py          # arranque de la API y documentación
│   ├── config.py        # lectura del .env
│   ├── database.py      # conexión a PostgreSQL
│   ├── models.py        # tablas
│   ├── schemas.py       # formato de entrada y salida de la API
│   ├── reglas.py        # reglas de horarios y disponibilidad
│   ├── firebase.py      # inicio del Admin SDK de Firebase
│   ├── auth.py          # verificación del token
│   └── routers/         # endpoints por recurso
├── cargar_datos.py      # crea tablas y carga sedes y canchas
├── obtener_token.py     # token de prueba para Swagger
├── requirements.txt
└── .env.example
```

## Despliegue en Render

Pendiente.

## Posibles mejoras a futuro

- Limitar la cantidad de pedidos por minuto (rate limiting) en el registro y en las reservas.
- Pruebas automáticas con pytest dentro del repo.
- Migraciones de base de datos con Alembic en lugar de create_all.
- Documentar en Swagger las respuestas de error 400, 401, 404 y 409.
- Agregar la imagen del DER al repo.