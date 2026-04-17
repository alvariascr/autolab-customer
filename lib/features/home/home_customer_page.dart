import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/bloc/auth_bloc.dart';
import '../auth/bloc/auth_event.dart';
import '../navigation/navigation_handler.dart';
import '../navigation/widgets/custom_bottom_navbar.dart';
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
  final TextEditingController _searchController = TextEditingController();

  int _currentIndex = 0;
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    _workshopsFuture = _loadWorkshops();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Workshop>> _loadWorkshops() async {
    final client = Supabase.instance.client;

    final dataSource = WorkshopRemoteDataSourceImpl(client);

    final repository = WorkshopRepositoryImpl(
      remoteDataSource: dataSource,
    );

    return await repository.getWorkshops();
  }

  void _handleBottomNavigation(int index, List<Workshop> workshops) {
    if (index == 2) {
      setState(() {
        _currentIndex = 2;
        _showSearchBar = !_showSearchBar;
      });
      return;
    }

    setState(() {
      _currentIndex = index;
      _showSearchBar = false;
    });

    NavigationHandler.handle(
      context,
      index,
      workshops: workshops,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
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
      body: FutureBuilder<List<Workshop>>(
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

          return Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      const Text(
                        'Talleres cercanos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 320,
                        child: WorkshopsCarousel(workshops: workshops),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                top: _showSearchBar ? 16 : -100,
                left: 16,
                right: 16,
                child: Material(
                  elevation: 10,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: _showSearchBar,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.search),
                        hintText: 'Buscar talleres...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: FutureBuilder<List<Workshop>>(
        future: _workshopsFuture,
        builder: (context, snapshot) {
          final workshops = snapshot.data ?? [];

          return CustomBottomNavbar(
            currentIndex: _currentIndex,
            onTap: (index) => _handleBottomNavigation(index, workshops),
          );
        },
      ),
    );
  }
}