"""Crea las tablas y carga los datos de prueba del Figma (4 sedes y 22 canchas).

Uso (desde la carpeta backend, con el .venv activado):
    python cargar_datos.py

Se puede ejecutar varias veces sin problema: lo que ya existe no se duplica
y NUNCA borra datos (ni usuarios ni reservas).
"""
import unicodedata
from datetime import time
from decimal import Decimal

from sqlalchemy import select

from app.database import Base, SessionLocal, engine
from app.models import Deporte, EspacioDeportivo, Sede

DEPORTES = ["Fútbol", "Tenis", "Hockey", "Vóley", "Golf"]

# Datos tomados del Figma del grupo (CU-16 Consultar sedes)
SEDES = [
    {"nombre": "Morón", "direccion": "Av. Rivadavia 17500", "apertura": time(8), "cierre": time(23)},
    {"nombre": "Ramos Mejía", "direccion": "Calle Belgrano 1240", "apertura": time(8), "cierre": time(23)},
    {"nombre": "San Justo", "direccion": "Av. Casanova 320", "apertura": time(8), "cierre": time(23)},
    {"nombre": "Castelar", "direccion": "Av. Rivadavia 22500", "apertura": time(8), "cierre": time(23)},
]

# (sede, deporte, variante, código para el nombre, ambiente, iluminada, precio, apertura, cierre)
ESPACIOS = [
    ("Morón", "Fútbol", "Fútbol 5", "F5", "Outdoor", True, 3800, 8, 23),
    ("Morón", "Fútbol", "Fútbol 5", "F5", "Indoor", False, 4200, 8, 23),
    ("Morón", "Fútbol", "Fútbol 7", "F7", "Outdoor", True, 5500, 8, 22),
    ("Morón", "Fútbol", "Fútbol 11", "F11", "Outdoor", True, 9000, 9, 21),
    ("Morón", "Tenis", "Polvo de Ladrillo", "Polvo", "Outdoor", True, 2500, 8, 23),
    ("Morón", "Tenis", "Polvo de Ladrillo", "Polvo", "Outdoor", False, 2500, 8, 22),
    ("Morón", "Tenis", "Cemento", "Cemento", "Indoor", True, 3000, 8, 23),
    ("Ramos Mejía", "Fútbol", "Fútbol 5", "F5", "Indoor", False, 4000, 9, 22),
    ("Ramos Mejía", "Fútbol", "Fútbol 11", "F11", "Outdoor", True, 8000, 9, 22),
    ("Ramos Mejía", "Hockey", "Hockey 7", "H7", "Outdoor", True, 3500, 8, 22),
    ("Ramos Mejía", "Vóley", "Indoor Parquet", "Indoor", "Indoor", True, 2800, 8, 23),
    ("San Justo", "Fútbol", "Fútbol 5", "F5", "Indoor", False, 4200, 8, 23),
    ("San Justo", "Fútbol", "Fútbol 5", "F5", "Outdoor", True, 3600, 8, 22),
    ("San Justo", "Fútbol", "Fútbol 8", "F8", "Outdoor", True, 6500, 9, 21),
    ("San Justo", "Tenis", "Sintético", "Sintetico", "Indoor", True, 3200, 8, 23),
    ("San Justo", "Golf", "Driving Range", "DrivingRange", "Outdoor", True, 1500, 8, 20),
    ("San Justo", "Golf", "9 Hoyos", "9Hoyos", "Outdoor", False, 4500, 8, 18),
    ("Castelar", "Tenis", "Polvo de Ladrillo", "Polvo", "Outdoor", True, 2700, 8, 23),
    ("Castelar", "Tenis", "Cemento", "Cemento", "Indoor", False, 3100, 8, 23),
    ("Castelar", "Vóley", "Vóley Playa", "Playa", "Outdoor", True, 2200, 9, 21),
    ("Castelar", "Vóley", "Indoor Parquet", "Indoor", "Indoor", True, 2600, 9, 22),
    ("Castelar", "Hockey", "Hockey 11", "H11", "Outdoor", True, 5000, 8, 22),
]


def limpiar(texto):
    """Saca tildes, puntos y espacios: 'Ramos Mejía' -> 'RamosMejia'."""
    sin_tildes = unicodedata.normalize("NFKD", texto).encode("ascii", "ignore").decode()
    return sin_tildes.replace(".", "").replace(" ", "")


def armar_nombre(sede, deporte, codigo, numero):
    """Nombre compuesto de la consigna: Sede_Calle_Altura_Deporte_Tipo_Numero.

    Ejemplo: Moron_Rivadavia_17500_Futbol_F5_1
    """
    palabras = sede.direccion.split()
    if palabras[0] in ("Av.", "Calle"):  # "Av." y "Calle" no aportan al nombre
        palabras = palabras[1:]
    direccion = "_".join(limpiar(p) for p in palabras)
    return f"{limpiar(sede.nombre)}_{direccion}_{limpiar(deporte.nombre)}_{codigo}_{numero}"


def obtener_o_crear(db, modelo, filtro, **datos):
    """Busca un registro; si no existe, lo crea. Devuelve (registro, fue_creado)."""
    existente = db.scalar(select(modelo).filter_by(**filtro))
    if existente:
        return existente, False
    nuevo = modelo(**filtro, **datos)
    db.add(nuevo)
    db.flush()  # le pide a la base que le asigne un id ya mismo
    return nuevo, True


def main():
    print("Creando las tablas que falten...")
    Base.metadata.create_all(engine)

    with SessionLocal() as db:
        deportes = {}
        for nombre in DEPORTES:
            deportes[nombre], _ = obtener_o_crear(db, Deporte, {"nombre": nombre})

        sedes = {}
        for s in SEDES:
            sedes[s["nombre"]], _ = obtener_o_crear(
                db, Sede, {"nombre": s["nombre"]},
                direccion=s["direccion"], hora_apertura=s["apertura"], hora_cierre=s["cierre"],
            )

        creados = 0
        contador = {}  # para numerar las canchas iguales: F5 1, F5 2...
        for sede_n, dep_n, variante, codigo, ambiente, iluminada, precio, ap, ci in ESPACIOS:
            sede, deporte = sedes[sede_n], deportes[dep_n]
            clave = (sede_n, dep_n, variante)
            contador[clave] = contador.get(clave, 0) + 1
            numero = contador[clave]

            apertura, cierre = time(ap), time(ci)
            # La cancha nunca puede abrir antes ni cerrar después que su sede
            if apertura < sede.hora_apertura or cierre > sede.hora_cierre:
                raise ValueError(f"{sede_n} {variante} {numero}: horario fuera del de la sede")

            _, creado = obtener_o_crear(
                db, EspacioDeportivo, {"nombre": armar_nombre(sede, deporte, codigo, numero)},
                sede_id=sede.id, deporte_id=deporte.id, variante=variante, numero=numero,
                ambiente=ambiente, iluminada=iluminada, precio_por_hora=Decimal(precio),
                hora_apertura=apertura, hora_cierre=cierre,
            )
            creados += creado

        db.commit()
        total = db.query(EspacioDeportivo).count()
        print(f"Listo: {len(sedes)} sedes, {len(deportes)} deportes, {total} espacios "
              f"({creados} nuevos en esta ejecución).")


if __name__ == "__main__":
    main()