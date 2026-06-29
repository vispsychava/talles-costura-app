import 'package:flutter/material.dart';
import 'package:talles_costura_app/services/recordatorio_service.dart';
import '../models/recordatorio.dart';
import '../models/pedido.dart';
import 'nuevo_pedido_screen.dart';
import '../models/estante.dart';
import 'detalle_pedido_screen.dart';

class RecordatoriosScreen extends StatefulWidget {
  final List<Recordatorio> recordatorios;
  final List<Pedido> pedidos;
  final Function(String, String) onAgregarRecordatorio;
  final Function(String) onCompletarRecordatorio;
  final List<Estante> estantes;
  final Function(Map<String, dynamic>) onGuardarPedido;

  const RecordatoriosScreen({
    super.key,
    required this.recordatorios,
    required this.pedidos,
    required this.onAgregarRecordatorio,
    required this.onCompletarRecordatorio,
    this.estantes = const [],
    required this.onGuardarPedido,
  });

  @override
  State<RecordatoriosScreen> createState() => _RecordatoriosScreenState();
}

class _RecordatoriosScreenState extends State<RecordatoriosScreen> {
  bool mostrarFormulario = false;

  final TextEditingController tareaController = TextEditingController();
  final TextEditingController clienteController = TextEditingController();
  final TextEditingController horaController = TextEditingController();
  final TextEditingController fechaController = TextEditingController();

  DateTime? _fechaSeleccionada;

  String _obtenerNombreMes(int mes) {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return meses[mes - 1];
  }

  String _formatearFecha(DateTime fecha) {
    const diasSemana = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return '${diasSemana[fecha.weekday - 1]}, ${fecha.day} de ${_obtenerNombreMes(fecha.month)}';
  }

  String _formatearFechaCorta(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  DateTime _parsearFecha(String fechaStr) {
    try {
      final parts = fechaStr.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (e) {}
    return DateTime.now().add(const Duration(days: 7));
  }

  List<Recordatorio> _obtenerTodosRecordatorios() {
    final List<Recordatorio> todosItems = [];

    todosItems.addAll(widget.recordatorios);

    for (var pedido in widget.pedidos) {
      if (pedido.estado != "Entregado") {
        final existe = widget.recordatorios.any((r) =>
            r.titulo == pedido.titulo && r.pedidoId == pedido.id);

        if (!existe) {
          final fechaEntrega = pedido.fechaEntrega ?? DateTime.now().add(const Duration(days: 7));

          todosItems.add(Recordatorio(
            id: 'pedido-${pedido.id}',
            pedidoId: pedido.id,
            titulo: '📦 ${pedido.titulo}',
            descripcion: 'Pedido #${pedido.id}',
            fechaRecordatorio: fechaEntrega,
            completado: false,
            fechaCreacion: DateTime.now(),
          ));
        }
      }
    }

    todosItems.sort((a, b) => a.fechaRecordatorio.compareTo(b.fechaRecordatorio));

    return todosItems;
  }

  void enviarRecordatorio() async {
    if (tareaController.text.trim().isEmpty ||
        clienteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_fechaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una fecha'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    widget.onAgregarRecordatorio(
      tareaController.text,
      clienteController.text,
    );

  final nuevoRecordatorio = Recordatorio(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    titulo: tareaController.text,
    pedidoId: clienteController.text,
    fechaRecordatorio: _fechaSeleccionada!,
    completado: false,
    fechaCreacion: DateTime.now(),
  );

    tareaController.clear();
    clienteController.clear();
    horaController.clear();
    fechaController.clear();
    _fechaSeleccionada = null;

    setState(() {
      mostrarFormulario = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Recordatorio creado con éxito!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _navegarANuevoPedido() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NuevoPedidoScreen(
          estantes: widget.estantes,
          onGuardarPedido: widget.onGuardarPedido,
        ),
      ),
    );
  }

  void _navegarADetallePedido(String pedidoId) {
    final pedido = widget.pedidos.firstWhere(
      (p) => p.id == pedidoId,
      orElse: () => widget.pedidos.first,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetallePedidoScreen(
          pedido: pedido,
          onPedidoActualizado: (pedidoActualizado) {
            widget.onGuardarPedido(pedidoActualizado.toJson());
          },
        ),
      ),
    );
  }

  Color _obtenerColorPorFecha(DateTime fecha) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final fechaOnly = DateTime(fecha.year, fecha.month, fecha.day);

    if (fechaOnly == today) return Colors.red;
    if (fechaOnly == tomorrow) return Colors.orange;
    return const Color(0xff6D3EFF);
  }

  @override
  Widget build(BuildContext context) {
    final todosItems = _obtenerTodosRecordatorios();

    final itemsActivos = todosItems.where((r) => !r.completado).toList();
    final itemsCompletados = todosItems.where((r) => r.completado).toList();

    final Map<String, List<Recordatorio>> recordatoriosAgrupados = {};
    for (var recordatorio in itemsActivos) {
      final fechaKey = _formatearFechaCorta(recordatorio.fechaRecordatorio);
      if (!recordatoriosAgrupados.containsKey(fechaKey)) {
        recordatoriosAgrupados[fechaKey] = [];
      }
      recordatoriosAgrupados[fechaKey]!.add(recordatorio);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Próximas Entregas',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xff102A43),
                fontSize: 22,
              ),
            ),
            Text(
              'Gestiona tu agenda de costura',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xff64748B),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FloatingActionButton.small(
              onPressed: () {
                setState(() {
                  mostrarFormulario = !mostrarFormulario;
                  if (!mostrarFormulario) {
                    tareaController.clear();
                    clienteController.clear();
                    horaController.clear();
                    fechaController.clear();
                    _fechaSeleccionada = null;
                  }
                });
              },
              backgroundColor: const Color(0xff6D3EFF),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// FORMULARIO PARA AGREGAR
            if (mostrarFormulario)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Nuevo Recordatorio',
                          style: TextStyle(
                            color: Color(0xff6D3EFF),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: tareaController,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.task),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: clienteController,
                        decoration: const InputDecoration(
                          labelText: 'Cliente',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: horaController,
                        decoration: const InputDecoration(
                          labelText: 'Hora (ej: 16:00)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            setState(() {
                              _fechaSeleccionada = date;
                              fechaController.text = _formatearFecha(date);
                            });
                          }
                        },
                        child: IgnorePointer(
                          child: TextField(
                            controller: fechaController,
                            decoration: const InputDecoration(
                              labelText: 'Fecha de Entrega',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                              suffixIcon: Icon(Icons.arrow_drop_down),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              onPressed: () {
                                setState(() {
                                  mostrarFormulario = false;
                                  tareaController.clear();
                                  clienteController.clear();
                                  horaController.clear();
                                  fechaController.clear();
                                  _fechaSeleccionada = null;
                                });
                              },
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff6D3EFF),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: enviarRecordatorio,
                              child: const Text('Añadir'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            if (mostrarFormulario) const SizedBox(height: 20),

            /// SIN RECORDATORIOS NI PEDIDOS
            if (itemsActivos.isEmpty && itemsCompletados.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Column(
                  children: const [
                    Icon(
                      Icons.inbox,
                      size: 70,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 15),
                    Text(
                      'No hay entregas pendientes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xff102A43),
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      '¡Buen trabajo!',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

            /// GRUPOS DE RECORDATORIOS + PEDIDOS
            if (itemsActivos.isNotEmpty)
              Column(
                children: [
                  for (var entry in recordatoriosAgrupados.entries)
                    _buildGroup(
                      _formatearFecha(entry.value.first.fechaRecordatorio),
                      entry.value,
                      _obtenerColorPorFecha(entry.value.first.fechaRecordatorio),
                    ),
                ],
              ),

            /// COMPLETADOS
            if (itemsCompletados.isNotEmpty)
              _buildGroup(
                "Completados ",
                itemsCompletados.toList(),
                Colors.green,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroup(
    String titulo,
    List<Recordatorio> recordatorios,
    Color color,
  ) {
    if (recordatorios.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                titulo,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: const Color(0xff102A43),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  recordatorios.length.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        ...recordatorios.map(
          (r) {
            final esPedido = r.titulo.contains('');

            return InkWell(
              onTap: () {
                if (esPedido) {
                  final pedidoId = r.pedidoId;
                  _navegarADetallePedido(pedidoId);
                } else {
                  if (!r.completado) {
                    widget.onCompletarRecordatorio(r.id);
                  }
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: r.completado ? Colors.green.shade200 : Colors.grey.shade100,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: r.completado
                            ? Colors.green.withOpacity(.12)
                            : color.withOpacity(.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        r.completado ? Icons.check :
                            (esPedido ? Icons.shopping_bag : Icons.event_note),
                        color: r.completado ? Colors.green : color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.titulo,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              decoration: r.completado ? TextDecoration.lineThrough : null,
                              color: r.completado ? Colors.grey : const Color(0xff102A43),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cliente: ${r.pedidoId}',
                            style: TextStyle(
                              fontSize: 14,
                              color: r.completado ? Colors.grey.shade500 : const Color(0xff64748B),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                _formatearFechaCorta(r.fechaRecordatorio),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: r.completado ? Colors.grey.shade400 : const Color(0xff829AB1),
                                ),
                              ),
                              if (esPedido && !r.completado)
                                const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Icon(
                                    Icons.chevron_right,
                                    size: 16,
                                    color: Color(0xff829AB1),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!r.completado && !esPedido)
                      InkWell(
                        onTap: () {
                          widget.onCompletarRecordatorio(r.id);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                            size: 28,
                          ),
                        ),
                      ),
                    if (r.completado)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 28,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}