import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Términos y Condiciones")),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            '''
TÉRMINOS Y CONDICIONES DE USO

Bienvenido a Autolab. Al acceder y utilizar esta aplicación, aceptas los siguientes términos y condiciones. Si no estás de acuerdo con alguno de ellos, te recomendamos no utilizar la app.

1. USO DE LA APLICACIÓN
Autolab es una plataforma que permite a los usuarios encontrar talleres mecánicos cercanos, consultar información y gestionar servicios relacionados con su vehículo.

El usuario se compromete a utilizar la aplicación de manera responsable, respetando las leyes vigentes y evitando cualquier uso indebido.

2. REGISTRO DE USUARIO
Para acceder a ciertas funcionalidades, es necesario registrarse proporcionando información veraz y actualizada. El usuario es responsable de mantener la confidencialidad de sus credenciales.

3. PRIVACIDAD Y DATOS
La aplicación puede recopilar datos como nombre, correo electrónico, ubicación y número telefónico con el fin de mejorar la experiencia del usuario.

Estos datos no serán compartidos con terceros sin consentimiento, salvo cuando sea requerido por ley.

4. GEOLOCALIZACIÓN
Autolab puede solicitar acceso a tu ubicación para mostrar talleres cercanos. El usuario puede aceptar o rechazar este permiso en cualquier momento desde la configuración del dispositivo.

5. RESPONSABILIDAD
Autolab actúa como intermediario entre el usuario y los talleres. No se hace responsable por la calidad del servicio brindado por terceros.

6. MODIFICACIONES
Nos reservamos el derecho de modificar estos términos en cualquier momento. Se recomienda revisar esta sección periódicamente.

7. ACEPTACIÓN
Al utilizar la aplicación, el usuario acepta estos términos y condiciones en su totalidad.

Última actualización: 2026
  ''',
            style: TextStyle(fontSize: 14),
          ),
        ),
      ),
    );
  }
}
