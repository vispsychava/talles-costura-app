import 'package:flutter/material.dart';
import '../models/pedido.dart';
import 'nuevo_pedido_screen.dart';
import '../models/estante.dart';
import 'detalle_pedido_screen.dart';
import '../services/supabase_service.dart';

class PedidosScreen extends StatefulWidget {
  final List<Pedido> pedidos;
  final Function(String pantalla, [String? pedidoId]) onNavigate;
  final String? filtroInicial;
  final List<Estante> estantes;
  final Function(Map<String, dynamic>) onGuardarPedido;
  final VoidCallback onRefresh;

  const PedidosScreen({
    super.key,
    required this.pedidos,
    required this.onNavigate,
    this.filtroInicial,
    this.estantes = const [],
    required this.onGuardarPedido,
    required this.onRefresh,
  });

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  final _supabaseService = SupabaseService();
  String searchQuery = '';
  late String selectedStatusFilter;
  List<Pedido> _localPedidos = [];
  int _refreshCounter = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    selectedStatusFilter = widget.filtroInicial ?? 'Todos';
    _cargarPedidosDesdeSupabase();
  }

  Future<void> _cargarPedidosDesdeSupabase() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Cargando pedidos desde Supabase...');
      final pedidos = await _supabaseService.obtenerPedidos();
      print('Pedidos cargados: ${pedidos.length}');
      
      setState(() {
        _localPedidos = pedidos;
        _isLoading = false;
        _refreshCounter++;
      });
    } catch (e) {
      print('Error al cargar pedidos: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      
      if (widget.pedidos.isNotEmpty) {
        setState(() {
          _localPedidos = List.from(widget.pedidos);
        });
      }
    }
  }

  Future<void> _recargarPedidos() async {
    await _cargarPedidosDesdeSupabase();
    widget.onRefresh();
  }

  List<Pedido> get filteredPedidos {
    return _localPedidos.where((pedido) {
      final cliente = pedido.clienteNombre.toLowerCase();
      final id = pedido.id.toLowerCase();
      final titulo = pedido.titulo?.toLowerCase() ?? '';
      final query = searchQuery.toLowerCase();

      final matchQuery = cliente.contains(query) ||
          id.contains(query) ||
          titulo.contains(query);

      if (selectedStatusFilter == 'Todos') {
        return matchQuery;
      }

      return matchQuery && pedido.estado == selectedStatusFilter;
    }).toList();
  }

  void showToast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Color estadoColor(String estado) {
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

  String estadoIcon(String estado) {
    switch (estado) {
      case 'En proceso':
        return '⏳';
      case 'Terminado':
        return '✅';
      case 'Entregado':
        return '📦';
      case 'Atrasado':
        return '⚠️';
      default:
        return '📋';
    }
  }

  @override
  Widget build(BuildContext context) {
    final chips = [
      {'label': 'Todos', 'count': _localPedidos.length},
      {
        'label': 'En proceso',
        'count': _localPedidos.where((o) => o.estado == 'En proceso').length,
      },
      {
        'label': 'Terminado',
        'count': _localPedidos.where((o) => o.estado == 'Terminado').length,
      },
      {
        'label': 'Atrasado',
        'count': _localPedidos.where((o) => o.estado == 'Atrasado').length,
      },
      {
        'label': 'Entregado',
        'count': _localPedidos.where((o) => o.estado == 'Entregado').length,
      },
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 900 ? 4 : 2;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          "Pedidos",
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _recargarPedidos,
            icon: const Icon(
              Icons.refresh,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF6D3EFF),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Cargando pedidos...',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            )
          : _errorMessage != null && _localPedidos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar pedidos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _recargarPedidos,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6D3EFF),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      /// HEADER
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
                                  )
                                ],
                              ),
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: "Buscar cliente o pedido...",
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                  ),
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    searchQuery = value;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            height: 55,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF6366F1),
                                  Color(0xFF8B5CF6),
                                ],
                              ),
                            ),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () {
                                showToast("¡Exportación CSV iniciada!");
                              },
                              icon: const Icon(Icons.download),
                              label: const Text(
                                "Exportar",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      /// TÍTULO
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Lista de Órdenes",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF102A43),
                              ),
                            ),
                            Text(
                              "Administra las fichas técnicas y estados de entrega",
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      /// FILTROS
                      if (_localPedidos.isNotEmpty)
                        SizedBox(
                          height: 45,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: chips.length,
                            itemBuilder: (context, index) {
                              final chip = chips[index];
                              final isSelected = selectedStatusFilter == chip['label'];
                              final count = chip['count'] as int;

                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  selected: isSelected,
                                  label: Text(
                                    "${chip['label']} $count",
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      fontSize: 14,
                                      color: isSelected ? Colors.white : const Color(0xFF475569),
                                    ),
                                  ),
                                  selectedColor: const Color(0xFF6D3EFF),
                                  backgroundColor: Colors.white,
                                  side: BorderSide(
                                    color: isSelected ? const Color(0xFF6D3EFF) : Colors.grey.shade300,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  onSelected: (_) {
                                    setState(() {
                                      selectedStatusFilter = chip['label'] as String;
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 18),

                    
                      Expanded(
                        child: GridView.builder(
                          key: ValueKey('$_refreshCounter-${_localPedidos.length}'),
                         
                          itemCount: filteredPedidos.length + 1,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                          itemBuilder: (context, index) {
                            /// TARJETA NUEVO PEDIDO (SIEMPRE PRIMERO)
                            if (index == 0) {
                              return InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => NuevoPedidoScreen(
                                        estantes: widget.estantes,
                                        onGuardarPedido: widget.onGuardarPedido,
                                      ),
                                    ),
                                  ).then((_) {
                                    _recargarPedidos();
                                    widget.onRefresh();
                                  });
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 2,
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF6D3EFF).withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          color: Color(0xFF6D3EFF),
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        "Nuevo Pedido",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color(0xFF102A43),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Registrar cliente",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            
                            final pedidoIndex = index - 1;
                            if (pedidoIndex >= filteredPedidos.length) {
                              return const SizedBox.shrink();
                            }
                            
                            final pedido = filteredPedidos[pedidoIndex];
                            final isAtrasado = pedido.estado == 'Atrasado';
                            final isPaid = (pedido.saldo ?? 0) == 0;
                            final isEnProceso = pedido.estado == 'En proceso';

                            /// TARJETA DE PEDIDO
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetallePedidoScreen(
                                      pedido: pedido,
                                      onPedidoActualizado: (pedidoActualizado) {
                                        setState(() {
                                          final index = _localPedidos.indexWhere((o) => o.id == pedidoActualizado.id);
                                          if (index != -1) {
                                            _localPedidos[index] = pedidoActualizado;
                                          }
                                          _refreshCounter++;
                                        });
                                        widget.onGuardarPedido(pedidoActualizado.toJson());
                                        widget.onRefresh();
                                      },
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    /// HEADER
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: estadoColor(pedido.estado).withValues(alpha: 0.08),
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(16),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            pedido.id,
                                            style: const TextStyle(
                                              color: Color(0xFF102A43),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 11,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: estadoColor(pedido.estado),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  estadoIcon(pedido.estado),
                                                  style: const TextStyle(fontSize: 10),
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  pedido.estado.toUpperCase(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 8,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    /// CONTENIDO
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              pedido.clienteNombre,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: Color(0xFF102A43),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              pedido.titulo ?? 'Sin título',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 11,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade50,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.person_outline,
                                                        size: 12,
                                                        color: Color(0xFF64748B),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        pedido.clienteTelefono,
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          color: Color(0xFF64748B),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        width: 2,
                                                        height: 2,
                                                        decoration: const BoxDecoration(
                                                          color: Color(0xFF64748B),
                                                          shape: BoxShape.circle,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      const Icon(
                                                        Icons.shelves,
                                                        size: 12,
                                                        color: Color(0xFF64748B),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        pedido.estanteId ?? 'Sin asignar',
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          color: Color(0xFF64748B),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.calendar_today,
                                                        size: 12,
                                                        color: Color(0xFF64748B),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        isAtrasado
                                                            ? "Vencido: ${pedido.fechaEntrega?.toLocal().toString().substring(0, 10) ?? 'N/A'}"
                                                            : "Entrega: ${pedido.fechaEntrega?.toLocal().toString().substring(0, 10) ?? 'N/A'}",
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: isAtrasado
                                                              ? Colors.red
                                                              : const Color(0xFF64748B),
                                                          fontWeight: isAtrasado
                                                              ? FontWeight.w600
                                                              : FontWeight.normal,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Spacer(),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isPaid
                                                        ? Colors.green.withValues(alpha: 0.12)
                                                        : Colors.orange.withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    isPaid
                                                        ? "Pagado"
                                                        : "\$${pedido.saldo?.toStringAsFixed(2) ?? '0.00'}",
                                                    style: TextStyle(
                                                      color: isPaid ? Colors.green : Colors.orange,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                                if (isAtrasado)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 3,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red.withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: const Text(
                                                      "Vencido",
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 9,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    /// FOOTER
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                             onPressed: () {
  print('🔍 Navegando con pedidoId: ${pedido.id}');
  if (pedido.estado == 'Terminado') {
    showToast(
      "Notificación enviada a ${pedido.clienteNombre}",
    );
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetallePedidoScreen(
          pedido: pedido,
          onPedidoActualizado: (pedidoActualizado) {
            setState(() {
              final index = _localPedidos.indexWhere((o) => o.id == pedidoActualizado.id);
              if (index != -1) {
                _localPedidos[index] = pedidoActualizado;
                _refreshCounter++;
              }
            });
            widget.onGuardarPedido(pedidoActualizado.toJson());
            widget.onRefresh();
          },
        ),
      ),
    );
  }
},
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: isEnProceso
                                                    ? const Color(0xFF8B5CF6)
                                                    : pedido.estado == 'Atrasado'
                                                        ? Colors.red
                                                        : const Color(0xFF10B981),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                padding: const EdgeInsets.symmetric(
                                                  vertical: 6,
                                                ),
                                                minimumSize: const Size(0, 30),
                                              ),
                                              child: Text(
                                                pedido.estado == 'Terminado'
                                                    ? 'Notificar'
                                                    : isAtrasado
                                                        ? 'Prioridad'
                                                        : 'Actualizar',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}