# autolab_customer

Aplicación cliente del ecosistema Autolab.

Este proyecto implementa la base estructural del lado cliente utilizando Clean Architecture e integrándose con el paquete foundation `autolab_core`.

---

## Arquitectura

El proyecto está organizado por capas:

- domain → reglas de negocio y contratos.
- data → implementaciones concretas.
- presentation → interfaz de usuario.
- common → estado global (BLoC/Cubit).
- core → navegación e inyección de dependencias.

Se utiliza:

- flutter_bloc para manejo de estado.
- go_router para navegación protegida.
- get_it para inyección de dependencias.
- autolab_core como capa foundation.

---

## Funcionalidades Implementadas

- Rutas públicas y privadas diferenciadas.
- Redirección automática si el usuario no está autenticado.
- Estado global de autenticación.
- Estructura lista para escalar nuevas features.

---

## Instalación

Clonar el repositorio:

```
git clone <url-del-repo>
cd autolab_customer
```

Instalar dependencias:

```
flutter pub get
```

Ejecutar proyecto:

```
flutter run
```

---

## Dependencias Principales

- go_router
- flutter_bloc
- get_it
- equatable
- autolab_core (paquete foundation local)

---

## Estado del Proyecto

Versión actual: 1.0.0+1

Proyecto base listo para iniciar desarrollo de nuevas funcionalidades sin necesidad de refactor estructural.