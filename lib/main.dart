import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:talles_costura_app/services/recordatorio_service.dart';
import 'config/supabase_config.dart';
import 'screens/panel_principal_screen.dart';
import 'screens/detalle_pedido_screen.dart';
import 'services/supabase_service.dart';
import 'services/pedido_service.dart';
import 'models/pedido.dart';
import 'models/recordatorio.dart';
import 'models/estante.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  await NotificationService().init();
  runApp(const TallerCosturaApp());
}

class TallerCosturaApp extends StatefulWidget {
  const TallerCosturaApp({super.key});

  @override
  State<TallerCosturaApp> createState() => _TallerCosturaAppState();
}

class _TallerCosturaAppState extends State<TallerCosturaApp> {
  static final supabaseService = SupabaseService();
  final _pedidoService = PedidoService();
  final _appLinks = AppLinks();
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _iniciarDeepLinks();
  }

  void _iniciarDeepLinks() {
    _appLinks.uriLinkStream.listen((uri) {
      _manejarDeepLink(uri);
    });

    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _manejarDeepLink(uri);
      }
    });
  }

void _manejarDeepLink(Uri uri) async {
  if (uri.scheme == 'tallercostura' && uri.host == 'pedido') {
    final codigoPedido = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    if (codigoPedido == null) return;

    print('🔗 Deep link recibido: $codigoPedido');

    // Extraemos los datos que vienen directamente en el QR por si falla Supabase o no hay internet
    final clienteNombreQr = uri.queryParameters['cliente'] ?? 'Cliente Desconocido';
    final fechaEntregaStr = uri.queryParameters['entrega'];

    DateTime? fechaEntregaQr;
    if (fechaEntregaStr != null) {
      fechaEntregaQr = DateTime.tryParse(fechaEntregaStr);
    }

    // 1. Intentamos obtener el pedido completo desde Supabase
    Pedido? pedido = await _pedidoService.obtenerPedidoPorId(codigoPedido);

    // 2. Fallback: Si no lo encuentra en internet, armamos el pedido con los datos del QR
  pedido ??= Pedido(
  id: codigoPedido,
  clienteNombre: clienteNombreQr,
  clienteTelefono: '', // <-- Agrega esta línea con un texto vacío o por defecto
  fechaEntrega: fechaEntregaQr,
  prendas: [],
  estado: 'Escaneado',
 fechaPedido: DateTime.now(),
  
  // Si tu modelo te pide algún otro parámetro obligatorio (ej. fechaCreacion, total, etc.), 
  // agrégalos aquí también con valores por defecto.
);

    // 3. Pequeño retardo para asegurar que el Navigator y MaterialApp ya se dibujaron
    await Future.delayed(const Duration(milliseconds: 300));

    // 4. Abrimos la pantalla de detalle
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => DetallePedidoScreen(
          pedido: pedido!,
          onPedidoActualizado: (_) {},
        ),
      ),
    );
  }
}

  Future<Map<String, List<dynamic>>> _cargarDatos() async {
    try {
      print('🔄 Recalculando estantes...');
      await supabaseService.recalcularTodosLosEstantes();
      print('✅ Estantes recalculados');

      final listas = await Future.wait([
        supabaseService.obtenerPedidos(),
        supabaseService.obtenerRecordatorios(),
        supabaseService.obtenerEstantes(),
      ]);

      final pedidos = listas[0] as List<Pedido>;
      await NotificationService().reprogramarDesdePedidos(pedidos);

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
      navigatorKey: _navigatorKey,
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
                    const Icon(Icons.error_outline, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error al conectar con la base de datos',
                      style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const TallerCosturaApp()),
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