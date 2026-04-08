import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/bloc/auth_bloc.dart';
import '../auth/bloc/auth_event.dart';
import '../workshops/data/datasources/workshop_remote_data_source_impl.dart';
import '../workshops/data/repositories/workshop_repository_impl.dart';
import '../workshops/domain/entities/workshop.dart';
import '../workshops/presentation/widgets/workshops_carousel.dart';

class HomeCustomerPage extends StatefulWidget {
  const HomeCustomerPage({super.key});

  @override
  State<HomeCustomerPage> createState() => _HomeCustomerPageState();
}

class _HomeCustomerPageState extends State<HomeCustomerPage> {
  late Future<List<Workshop>> _workshopsFuture;

  @override
  void initState() {
    super.initState();
    _workshopsFuture = _loadWorkshops();
  }

  Future<List<Workshop>> _loadWorkshops() async {
    final client = Supabase.instance.client;

    final dataSource = WorkshopRemoteDataSourceImpl(client);

    final repository = WorkshopRepositoryImpl(
      remoteDataSource: dataSource,
    );

    return await repository.getWorkshops();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            onPressed: () {
              context.read<AuthBloc>().add(const LogoutRequested());
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Talleres cercanos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<Workshop>>(
                future: _workshopsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Error al cargar talleres: ${snapshot.error}',
                      ),
                    );
                  }

                  final workshops = snapshot.data ?? [];

                  return SizedBox(
                    height: 320,
                    child: WorkshopsCarousel(workshops: workshops),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}