import 'package:flutter/material.dart';
import 'package:talles_costura_app/screens/escanear_qr_screen.dart';
import '../models/pedido.dart';
import '../models/recordatorio.dart';
import 'nuevo_pedido_screen.dart';
import '../models/estante.dart';
import 'pedidos_screen.dart';
import 'catalogo_estantes_screen.dart';
import 'configuracion_screen.dart';
import 'recordatorios_screen.dart';
import 'detalle_pedido_screen.dart';
import '../models/medida.dart';
import '../services/supabase_service.dart';
import '../services/recordatorio_service.dart';

class PanelPrincipalScreen extends StatefulWidget {
  final List<Pedido> pedidos;
  final List<Recordatorio> recordatorios;
  final List<Estante> estantes;

  const PanelPrincipalScreen({
    super.key,
    required this.pedidos,
    required this.recordatorios,
    required this.estantes,
  });

  @override
  State<PanelPrincipalScreen> createState() => _PanelPrincipalScreenState();
}

class _PanelPrincipalScreenState extends State<PanelPrincipalScreen> {
  int notificacionesCount = 3;
  late List<Pedido> _pedidos;
  late List<Estante> _estantes;
  late List<Recordatorio> _recordatorios;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showSuggestions = false;
  List<Pedido> _sugerencias = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _pedidos = List.from(widget.pedidos);
    _estantes = List.from(widget.estantes);
    _recordatorios = List.from(widget.recordatorios);
    _actualizarEstantesDesdePedidos();
    _searchController.addListener(_onSearchChanged);
    _cargarDatosYActualizar();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _sugerencias = [];
        _showSuggestions = false;
        _searchQuery = '';
      });
      return;
    }

    setState(() {
      _searchQuery = query;
      _sugerencias = _pedidos.where((pedido) {
        final titulo = pedido.titulo?.toLowerCase() ?? '';
        final id = pedido.id.toLowerCase();
        final cliente = pedido.clienteNombre.toLowerCase();
        return titulo.contains(query) ||
            id.contains(query) ||
            cliente.contains(query);
      }).toList();
      _showSuggestions = true;
    });
  }

  void _performSearch() {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return;

    final results = _pedidos.where((pedido) {
      final titulo = pedido.titulo?.toLowerCase() ?? '';
      final id = pedido.id.toLowerCase();
      final cliente = pedido.clienteNombre.toLowerCase();
      return titulo.contains(query) ||
          id.contains(query) ||
          cliente.contains(query);
    }).toList();

    setState(() {
      _showSuggestions = false;
      _searchController.text = '';
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PedidosScreen(
          pedidos: results.isEmpty ? _pedidos : results,
          onNavigate: (pantalla, [pedidoId]) {
            if (pantalla == 'status_management' && pedidoId != null) {
              final pedido = _pedidos.firstWhere(
                (p) => p.id == pedidoId,
                orElse: () => _pedidos.first,
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetallePedidoScreen(
                    pedido: pedido,
                    onPedidoActualizado: (pedidoActualizado) {
                      _guardarPedido(pedidoActualizado.toJson());
                    },
                  ),
                ),
              );
            }
          },
          filtroInicial: 'Todos',
          estantes: _estantes,
          onGuardarPedido: _guardarPedido,
          onRefresh: () {
            setState(() {
              _pedidos = List.from(_pedidos);
              _actualizarEstantesDesdePedidos();
            });
          },
        ),
      ),
    );
  }

  void _selectSuggestion(Pedido pedido) {
    setState(() {
      _showSuggestions = false;
      _searchController.text = '';
      _sugerencias = [];
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetallePedidoScreen(
          pedido: pedido,
          onPedidoActualizado: (pedidoActualizado) {
            _guardarPedido(pedidoActualizado.toJson());
          },
        ),
      ),
    );
  }

  List<MapEntry<String, dynamic>> get proximosEventos {
    List<MapEntry<String, dynamic>> eventos = [];

    for (var recordatorio in widget.recordatorios) {
      if (!recordatorio.completado) {
        eventos.add(MapEntry('recordatorio', recordatorio));
      }
    }

    for (var pedido in _pedidos) {
      if (pedido.estado != "Entregado") {
        eventos.add(MapEntry('pedido', pedido));
      }
    }

    eventos.sort((a, b) {
      DateTime dateA;
      DateTime dateB;

      if (a.key == 'recordatorio') {
        dateA = (a.value as Recordatorio).fechaRecordatorio;
      } else {
        dateA =
            (a.value as Pedido).fechaEntrega ??
            DateTime.now().add(const Duration(days: 7));
      }

      if (b.key == 'recordatorio') {
        dateB = (b.value as Recordatorio).fechaRecordatorio;
      } else {
        dateB =
            (b.value as Pedido).fechaEntrega ??
            DateTime.now().add(const Duration(days: 7));
      }

      return dateA.compareTo(dateB);
    });

    return eventos.take(3).toList();
  }

  void _actualizarEstantesDesdePedidos() {
    final Map<String, int> estanteCounts = {};
    for (var estante in _estantes) {
      estanteCounts[estante.id] = 0;
    }
    for (var pedido in _pedidos) {
      if (pedido.estado != "Entregado") {
        final estanteId = pedido.estanteId;
        if (estanteId != null && estanteCounts.containsKey(estanteId)) {
          estanteCounts[estanteId] = (estanteCounts[estanteId] ?? 0) + 1;
        }
      }
    }

    for (int i = 0; i < _estantes.length; i++) {
      final estante = _estantes[i];
      final count = estanteCounts[estante.id] ?? 0;
      _estantes[i] = Estante(
        id: estante.id,
        nombre: estante.nombre,
        capacidad: estante.capacidad,
        ocupados: count,
        ubicacion: estante.ubicacion,
        descripcion: estante.descripcion,
        fechaCreacion: estante.fechaCreacion,
        fechaActualizacion: DateTime.now(),
      );
    }
  }

  Future<void> _cargarDatosYActualizar() async {
    try {
      final supabaseService = SupabaseService();
      final pedidosSupabase = await supabaseService.obtenerPedidos();
      final recordatoriosSupabase = await supabaseService.obtenerRecordatorios();
      setState(() {
        if (pedidosSupabase.isNotEmpty) {
          _pedidos = pedidosSupabase;
        }
        _recordatorios = recordatoriosSupabase;
        _actualizarEstantesDesdePedidos();
      });
    } catch (e) {
      print('Error al cargar datos: $e');
    }
  }

  Future<void> _agregarRecordatorio(String titulo, String cliente, DateTime fecha) async {
    final nuevo = Recordatorio(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      pedidoId: null,
      clienteNombre: cliente,
      titulo: titulo,
      descripcion: null,
      fechaRecordatorio: fecha,
      completado: false,
      fechaCreacion: DateTime.now(),
    );

    final exito = await SupabaseService().insertarRecordatorio(nuevo);

    if (exito) {
      await _cargarDatosYActualizar();
      NotificationService().scheduleReminderNotification(nuevo);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo guardar el recordatorio'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _completarRecordatorio(String id) async {
    final exito = await SupabaseService().completarRecordatorio(id);
    if (exito) {
      await _cargarDatosYActualizar();
      NotificationService().cancelNotification(id);
    }
  }

  void _guardarPedido(Map<String, dynamic> pedidoData) {
    setState(() {
      final existingIndex = _pedidos.indexWhere(
        (o) => o.id == pedidoData['id'],
      );

      Medida medidas;
      if (pedidoData['medidas'] != null) {
        medidas = Medida.fromJson(pedidoData['medidas']);
      } else {
        medidas = Medida(
          id: '',
          clienteNombre: pedidoData['clientName']?.toString() ?? '',
          tipoMedida: '',
          valor: 0,
          fechaCreacion: DateTime.now(),
        );
      }

      final String id = pedidoData['id']?.toString() ?? '';
      final String clienteNombre = pedidoData['clientName']?.toString() ?? '';
      final String clienteTelefono = pedidoData['clientPhone']?.toString() ?? '';
      final String clienteEmail = pedidoData['clientEmail']?.toString() ?? '';
      final String estado = pedidoData['status']?.toString() ?? 'Sin empezar';
      final String descripcion = pedidoData['description']?.toString() ?? '';
      final double total = (pedidoData['totalAmount'] ?? 0.0).toDouble();
      final DateTime fechaPedido = pedidoData['fechaPedido'] != null
          ? DateTime.parse(pedidoData['fechaPedido'].toString())
          : DateTime.now();
      final DateTime? fechaEntrega = pedidoData['deliveryDate'] != null
          ? DateTime.parse(pedidoData['deliveryDate'].toString())
          : null;
      final String titulo = pedidoData['title']?.toString() ?? 'Pedido';
      final String? estanteId = pedidoData['shelfAssignment']?.toString();
      final String prioridad = pedidoData['priority']?.toString() ?? 'Media';
      final String tipoPrenda = pedidoData['garmentType']?.toString() ?? 'vestido';
      final String talla = pedidoData['size']?.toString() ?? 'M';
      final double anticipo = (pedidoData['advancePaid'] ?? 0.0).toDouble();
      final double saldo = (pedidoData['balanceDue'] ?? 0.0).toDouble();

      if (existingIndex != -1) {
        final pedidoActualizado = Pedido(
          id: id,
          clienteNombre: clienteNombre,
          clienteTelefono: clienteTelefono,
          clienteEmail: clienteEmail,
          estado: estado,
          descripcion: descripcion,
          total: total,
          fechaPedido: fechaPedido,
          fechaEntrega: fechaEntrega,
          fechaActualizacion: DateTime.now(),
          medidas: [medidas],
          prendas: [],
          titulo: titulo,
          estanteId: estanteId,
          prioridad: prioridad,
          tipoPrenda: tipoPrenda,
          talla: talla,
          anticipo: anticipo,
          saldo: saldo,
        );
        _pedidos[existingIndex] = pedidoActualizado;
      } else {
        final nuevoPedido = Pedido(
          id: id,
          clienteNombre: clienteNombre,
          clienteTelefono: clienteTelefono,
          clienteEmail: clienteEmail,
          estado: estado,
          descripcion: descripcion,
          total: total,
          fechaPedido: fechaPedido,
          fechaEntrega: fechaEntrega,
          fechaActualizacion: DateTime.now(),
          medidas: [medidas],
          prendas: [],
          titulo: titulo,
          estanteId: estanteId,
          prioridad: prioridad,
          tipoPrenda: tipoPrenda,
          talla: talla,
          anticipo: anticipo,
          saldo: saldo,
        );
        _pedidos.add(nuevoPedido);
      }

      _actualizarEstantesDesdePedidos();
    });
  }

  void _actualizarEstantes(List<Estante> estantesActualizados) {
    setState(() {
      _estantes = estantesActualizados;
    });
  }

  void _navigateToOrdersWithFilter(String filtro) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PedidosScreen(
          pedidos: _pedidos,
          onNavigate: (pantalla, [pedidoId]) {
            if (pantalla == 'status_management' && pedidoId != null) {
              final pedido = _pedidos.firstWhere(
                (p) => p.id == pedidoId,
                orElse: () => _pedidos.first,
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetallePedidoScreen(
                    pedido: pedido,
                    onPedidoActualizado: (pedidoActualizado) {
                      _guardarPedido(pedidoActualizado.toJson());
                    },
                  ),
                ),
              );
            }
          },
          filtroInicial: filtro,
          estantes: _estantes,
          onGuardarPedido: _guardarPedido,
          onRefresh: () {
            setState(() {
              _pedidos = List.from(_pedidos);
              _actualizarEstantesDesdePedidos();
            });
          },
        ),
      ),
    );
  }

  void _navigateToOrdersWithPriority(String prioridad) {
    final pedidosFiltrados = _pedidos.where((pedido) =>
      pedido.prioridad == prioridad
    ).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PedidosScreen(
          pedidos: pedidosFiltrados,
          onNavigate: (pantalla, [pedidoId]) {
            if (pantalla == 'status_management' && pedidoId != null) {
              final pedido = _pedidos.firstWhere(
                (p) => p.id == pedidoId,
                orElse: () => _pedidos.first,
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetallePedidoScreen(
                    pedido: pedido,
                    onPedidoActualizado: (pedidoActualizado) {
                      _guardarPedido(pedidoActualizado.toJson());
                    },
                  ),
                ),
              );
            }
          },
          filtroInicial: 'Todos',
          estantes: _estantes,
          onGuardarPedido: _guardarPedido,
          onRefresh: () {
            setState(() {
              _pedidos = List.from(_pedidos);
              _actualizarEstantesDesdePedidos();
            });
          },
        ),
      ),
    );
  }

  int _contarPorPrioridad(String prioridad) {
    return _pedidos.where((pedido) =>
      pedido.prioridad == prioridad &&
      pedido.estado != 'Entregado'
    ).length;
  }

  void _navigateToRecordatorios() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordatoriosScreen(
          recordatorios: _recordatorios,
          pedidos: _pedidos,
          onAgregarRecordatorio: _agregarRecordatorio,
          onCompletarRecordatorio: _completarRecordatorio,
          estantes: _estantes,
          onGuardarPedido: _guardarPedido,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final altaCount = _contarPorPrioridad('Alta');
    final mediaCount = _contarPorPrioridad('Media');
    final bajaCount = _contarPorPrioridad('Baja');

    final eventos = proximosEventos;

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Buenos días, Tere",
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Color(0xff102A43),
                        ),
                      ),
                      Text(
                        "¡Lista para un día creativo en el taller!",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xff64748B),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_none,
                              size: 28,
                            ),
                            onPressed: () {},
                          ),
                          Positioned(
                            right: 10,
                            top: 10,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Color(0xff8B5CF6),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, size: 28),
                        color: const Color(0xff64748B),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ConfiguracionScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              /// BARRA DE BÚSQUEDA
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: "Buscar cliente o pedido...",
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xff829AB1),
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _sugerencias = [];
                                      _showSuggestions = false;
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onSubmitted: (_) => _performSearch(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: const Color(0xff6D3EFF),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.qr_code_scanner,
                        size: 28,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EscanearQrScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              /// SUGERENCIAS DE BÚSQUEDA
              if (_showSuggestions && _sugerencias.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: _sugerencias.length > 5
                        ? 5
                        : _sugerencias.length,
                    itemBuilder: (context, index) {
                      final pedido = _sugerencias[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.receipt_long,
                          size: 18,
                          color: Color(0xff6D3EFF),
                        ),
                        title: Text(
                          pedido.clienteNombre,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff102A43),
                          ),
                        ),
                        subtitle: Text(
                          '${pedido.id} • ${pedido.titulo ?? 'Sin título'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        trailing: Chip(
                          label: Text(
                            pedido.estado,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor: _estadoColor(
                            pedido.estado,
                          ).withValues(alpha: 0.12),
                          labelStyle: TextStyle(
                            color: _estadoColor(pedido.estado),
                          ),
                        ),
                        onTap: () => _selectSuggestion(pedido),
                      );
                    },
                  ),
                ),

              if (_showSuggestions &&
                  _sugerencias.isEmpty &&
                  _searchQuery.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 40,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No se encontraron pedidos para "$_searchQuery"',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: _performSearch,
                        child: const Text(
                          'Ver todos los resultados',
                          style: TextStyle(
                            color: Color(0xff6D3EFF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              /// MÉTRICAS DE PRIORIDAD
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _metricCard(
                    "Prioridad Alta",
                    altaCount.toString(),
                    Icons.priority_high,
                    const Color(0xffEF4444),
                    () => _navigateToOrdersWithPriority('Alta'),
                  ),
                  _metricCard(
                    "Prioridad Media",
                    mediaCount.toString(),
                    Icons.remove,
                    const Color(0xffF59E0B),
                    () => _navigateToOrdersWithPriority('Media'),
                  ),
                  _metricCard(
                    "Prioridad Baja",
                    bajaCount.toString(),
                    Icons.arrow_downward,
                    const Color(0xff10B981),
                    () => _navigateToOrdersWithPriority('Baja'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              /// PANEL DE CONTROL
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Panel de Control",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff102A43),
                        ),
                      ),
                      const SizedBox(height: 20),

                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.4,
                        children: [
                          /// 1. Nuevo Pedido - ✅ CORREGIDO
                          _actionButton(
                            "Nuevo Pedido",
                            Icons.add,
                            const Color(0xff6D3EFF),
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NuevoPedidoScreen(
                                    estantes: _estantes,
                                    onGuardarPedido: _guardarPedido,
                                  ),
                                ),
                              );
                            },
                            true,
                          ),

                          /// 2. Ver Pedidos
                          _actionButton(
                            "Ver Pedidos",
                            Icons.list_alt,
                            const Color(0xff475569),
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PedidosScreen(
                                    pedidos: _pedidos,
                                    onNavigate: (pantalla, [pedidoId]) {
                                      if (pantalla == 'status_management' &&
                                          pedidoId != null) {
                                        final pedido = _pedidos.firstWhere(
                                          (p) => p.id == pedidoId,
                                          orElse: () => _pedidos.first,
                                        );
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => DetallePedidoScreen(
                                              pedido: pedido,
                                              onPedidoActualizado:
                                                  (pedidoActualizado) {
                                                    _guardarPedido(
                                                      pedidoActualizado
                                                          .toJson(),
                                                    );
                                                  },
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    estantes: _estantes,
                                    onGuardarPedido: _guardarPedido,
                                    onRefresh: () {
                                      setState(() {
                                        _pedidos = List.from(_pedidos);
                                        _actualizarEstantesDesdePedidos();
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                            false,
                          ),

                          /// 3. Estantes Taller
                          _actionButton(
                            "Estantes Taller",
                            Icons.grid_view,
                            const Color(0xff6D3EFF),
                            () {
                              _cargarDatosYActualizar().then((_) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CatalogoEstantesScreen(
                                      estantes: _estantes,
                                      pedidos: _pedidos,
                                      onNavigateToDetallePedido: (pedidoId) {
                                        final pedido = _pedidos.firstWhere(
                                          (p) => p.id == pedidoId,
                                          orElse: () => _pedidos.first,
                                        );
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => DetallePedidoScreen(
                                              pedido: pedido,
                                              onPedidoActualizado:
                                                  (pedidoActualizado) {
                                                    _guardarPedido(
                                                      pedidoActualizado
                                                          .toJson(),
                                                    );
                                                  },
                                            ),
                                          ),
                                        );
                                      },
                                      onEstantesActualizados:
                                          _actualizarEstantes,
                                    ),
                                  ),
                                );
                              });
                            },
                            false,
                          ),

                          /// 4. Recordatorios
                          _actionButton(
                            "Recordatorios",
                            Icons.calendar_today,
                            const Color(0xffF59E0B),
                            () {
                              _navigateToRecordatorios();
                            },
                            false,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'En proceso':
        return const Color(0xFF8B5CF6);
      case 'Terminado':
        return const Color(0xFF10B981);
      case 'Entregado':
        return const Color(0xFF3B82F6);
      case 'Atrasado':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  Widget _metricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: MediaQuery.of(context).size.width / 2 - 24,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: Colors.blueGrey.shade300,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff102A43),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isPrimary,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [Color(0xff6D3EFF), Color(0xff4F2FFF)],
                )
              : null,
          color: isPrimary ? null : Colors.white,
          border: Border.all(
            color: isPrimary ? Colors.transparent : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: isPrimary ? Colors.white : color),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.white : const Color(0xff23395B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}