# herramienta de prueba: crea (o loguea) un usuario en firebase y muestra su token
# para pegarlo en el boton "Authorize" de swagger
# uso: python obtener_token.py email contraseña
import json
import sys
import urllib.error
import urllib.request

from app.config import settings

URL = "https://identitytoolkit.googleapis.com/v1/accounts:{}?key={}"


def pedir(accion, email, contrasena):
    cuerpo = json.dumps({"email": email, "password": contrasena, "returnSecureToken": True})
    pedido = urllib.request.Request(
        URL.format(accion, settings.firebase_api_key),
        data=cuerpo.encode(),
        headers={"Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(pedido) as respuesta:
            return json.load(respuesta), None
    except urllib.error.HTTPError as e:
        return None, json.load(e)["error"]["message"]


def main():
    if len(sys.argv) != 3:
        print("Uso: python obtener_token.py email contraseña")
        return
    if not settings.firebase_api_key:
        print("Falta FIREBASE_API_KEY en el .env")
        return

    email, contrasena = sys.argv[1], sys.argv[2]
    datos, error = pedir("signUp", email, contrasena)
    if error == "EMAIL_EXISTS":
        datos, error = pedir("signInWithPassword", email, contrasena)
    if error:
        print("Error de Firebase:", error)
        return

    print("uid:", datos["localId"])
    print("token (dura 1 hora):")
    print(datos["idToken"])


if __name__ == "__main__":
    main()