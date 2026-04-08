import 'package:flutter/material.dart';

import 'widgets/home_scaffold.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeScaffold(
      title: 'Panel administrativo',
      subtitle: 'Vista inicial para coordinación interna de Autolab.',
      heroLabel: 'Operación del día',
      heroValue: 'Supervisa ingresos, agenda y seguimiento del taller desde un solo lugar.',
      highlights: buildHomeInfoItems([
        (
          title: 'Agenda operativa',
          description:
              'Aquí podremos mostrar entradas programadas, vehículos en proceso y entregas pendientes.',
          icon: Icons.calendar_month_outlined,
        ),
        (
          title: 'Seguimiento del taller',
          description:
              'El diseño ya separa el espacio donde luego conectaremos estados de servicio, técnicos y tiempos de atención.',
          icon: Icons.build_circle_outlined,
        ),
        (
          title: 'Relación con clientes',
          description:
              'También queda listo para incorporar alertas de aprobación, historial y comunicación post-servicio.',
          icon: Icons.people_alt_outlined,
        ),
      ]),
      quickActions: buildHomeInfoItems([
        (
          title: 'Registrar ingreso',
          description: 'Crear una nueva recepción de vehículo.',
          icon: Icons.add_road_outlined,
        ),
        (
          title: 'Ver órdenes abiertas',
          description: 'Consultar trabajos que siguen en ejecución.',
          icon: Icons.receipt_long_outlined,
        ),
        (
          title: 'Revisar entregas',
          description: 'Identificar unidades listas para salida.',
          icon: Icons.local_shipping_outlined,
        ),
      ]),
      statusCards: buildHomeStatusItems([
        (
          label: 'Capacidad del taller',
          value: '76%',
          caption: 'Carga saludable',
          tone: const Color(0xFF0F8A5F),
        ),
        (
          label: 'Entregas críticas',
          value: '03',
          caption: 'Revisión prioritaria',
          tone: const Color(0xFFB54708),
        ),
        (
          label: 'Aprobaciones pendientes',
          value: '08',
          caption: 'Esperando respuesta',
          tone: const Color(0xFF9B3D24),
        ),
      ]),
    );
  }
}
