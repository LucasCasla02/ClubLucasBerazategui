// direccion de la api: por defecto la publicada en render.
// para usar el backend de la pc: --dart-define=URL_API=http://10.0.2.2:8000/api/v1
// (en el emulador, 10.0.2.2 es la pc)
const String urlApi = String.fromEnvironment(
  'URL_API',
  defaultValue: 'https://clublucasberazategui.onrender.com/api/v1',
);