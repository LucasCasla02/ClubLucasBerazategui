# ClubLucasBerazategui

Aplicación móvil para la gestión de espacios deportivos.
Trabajo Práctico de Electiva General, Universidad de Morón.

Los usuarios pueden registrarse, consultar las sedes y sus canchas, ver la disponibilidad de horarios, reservar, cancelar, consultar su historial de reservas y recibir notificaciones push antes de cada reserva.

## Tecnologías

| Parte | Tecnología |
|---|---|
| App móvil | Flutter |
| API REST | Python con FastAPI |
| Base de datos | PostgreSQL |
| Autenticación | Firebase Authentication |
| Notificaciones push | Firebase Cloud Messaging |
| Documentación de la API | Swagger / OpenAPI |
| Nube | Render (API y base de datos): https://clublucasberazategui.onrender.com/docs |

## Estructura del repositorio

- `backend/`: API REST. Ver [backend/README.md](backend/README.md).
- `app/`: aplicación móvil en Flutter.
- [MODELO_DE_DATOS.md](MODELO_DE_DATOS.md): entidades, atributos y relaciones, con el diagrama entidad-relación.

Cada carpeta tiene su propio README con los pasos para configurar, ejecutar y desplegar el proyecto.
