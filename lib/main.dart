import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';  // ✅ Importar la configuración
import 'screens/panel_principal_screen.dart';
import 'services/supabase_service.dart';
import 'models/pedido.dart';
import 'models/recordatorio.dart';
import 'models/estante.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Usar SupabaseConfig en lugar de inicializar directamente
  await SupabaseConfig.initialize();

  runApp(const TallerCosturaApp());
}

class TallerCosturaApp extends StatelessWidget {
  const TallerCosturaApp({super.key});

  static final supabaseService = SupabaseService();

  Future<Map<String, List<dynamic>>> _cargarDatos() async {
    try {
      final listas = await Future.wait([
        supabaseService.obtenerPedidos(),
        supabaseService.obtenerRecordatorios(),
        supabaseService.obtenerEstantes(),
      ]);

      return {
        'pedidos': listas[0],
        'recordatorios': listas[1],
        'estantes': listas[2],
      };
    } catch (e) {
      debugPrint('Error al cargar datos: $e');
      return {
        'pedidos': <Pedido>[],
        'recordatorios': <Recordatorio>[],
        'estantes': <Estante>[],
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Talles Costura',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        fontFamily: 'Roboto',
      ),
      home: FutureBuilder<Map<String, List<dynamic>>>(
        future: _cargarDatos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: Colors.indigo,
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error al conectar con la base de datos',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TallerCosturaApp(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final datos = snapshot.data!;
          
          final pedidos = datos['pedidos'] as List<Pedido>? ?? [];
          final recordatorios = datos['recordatorios'] as List<Recordatorio>? ?? [];
          final estantes = datos['estantes'] as List<Estante>? ?? [];

          return PanelPrincipalScreen(
            pedidos: pedidos,
            recordatorios: recordatorios,
            estantes: estantes,
          );
        },
      ),
    );
  }
}