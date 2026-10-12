// direccion de la api
// en el emulador 10.0.2.2 es tu pc. cuando este en render se cambia con --dart-define
const String urlApi = String.fromEnvironment(
  'URL_API',
  defaultValue: 'http://10.0.2.2:8000/api/v1',
);