import 'package:flutter/material.dart';
import '../models/pedido.dart';
import '../services/pedido_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DetallePedidoScreen extends StatefulWidget {
  final Pedido pedido;
  final Function(Pedido) onPedidoActualizado;

  const DetallePedidoScreen({
    super.key,
    required this.pedido,
    required this.onPedidoActualizado,
  });

  @override
  State<DetallePedidoScreen> createState() => _DetallePedidoScreenState();
}

class _DetallePedidoScreenState extends State<DetallePedidoScreen> {
  late double montoPago;
  late String prioridadSeleccionada;
  late Pedido _pedidoActual;
  final _pedidoService = PedidoService();
  final _screenshotController = ScreenshotController();
  List<Map<String, dynamic>> _historial = [];
  bool _cargandoHistorial = false;

  @override
  void initState() {
    super.initState();
    _pedidoActual = widget.pedido;
    montoPago = _pedidoActual.saldo ?? 0;
    prioridadSeleccionada = _pedidoActual.prioridad ?? 'Media';
    _cargarHistorial();
  }

  /// 📋 Cargar historial de actividad
  Future<void> _cargarHistorial() async {
    print('📋 ===== CARGANDO HISTORIAL =====');
    print('📋 Pedido ID: ${_pedidoActual.id}');
    setState(() => _cargandoHistorial = true);
    
    final historial = await _pedidoService.obtenerHistorialPedido(_pedidoActual.id);
    print('📋 Historial obtenido: ${historial.length} registros');
    
    if (historial.isNotEmpty) {
      print('📋 Primer registro: ${historial.first}');
    }
    
    setState(() {
      _historial = historial;
      _cargandoHistorial = false;
    });
    print('📋 ===== FIN CARGAR HISTORIAL =====');
  }

  void _mostrarModalPago() {
    final pagoController = TextEditingController();
    montoPago = 0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Registrar Pago',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xff102A43),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cliente: ${_pedidoActual.clienteNombre}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: pagoController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Monto a pagar',
                  hintText: '\$0.00',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                onChanged: (value) {
                  montoPago = double.tryParse(value) ?? 0;
                },
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xff6D3EFF).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Saldo pendiente:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xff102A43),
                      ),
                    ),
                    Text(
                      '\$${(_pedidoActual.saldo ?? 0).toStringAsFixed(2)} MXN',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xff6D3EFF),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _registrarPago(montoPago);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff6D3EFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Confirmar Pago'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _compartirEtiqueta() async {
    final imagen = await _screenshotController.capture();
    if (imagen == null) return;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/etiqueta_${_pedidoActual.id}.png');
    await file.writeAsBytes(imagen);

    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Etiqueta del pedido ${_pedidoActual.id}');
  }

  void _registrarPago(double monto) async {
    print('💰 ===== INICIANDO REGISTRO DE PAGO =====');
    print('💰 Pedido ID: ${_pedidoActual.id}');
    print('💰 Monto: $monto');
    print('💰 Saldo actual: ${_pedidoActual.saldo}');
    
    if (monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El monto debe ser mayor a 0'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final saldoActual = _pedidoActual.saldo ?? 0;
    if (monto > saldoActual) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El monto no puede ser mayor al saldo pendiente'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final nuevoSaldo = (saldoActual - monto).clamp(0.0, double.infinity);
    print('💰 Nuevo saldo calculado: $nuevoSaldo');

    // Actualizar pago
    print('💰 Actualizando pago en Supabase...');
    final exito = await _pedidoService.actualizarEstadoPago(
      _pedidoActual.id,
      nuevoSaldo,
    );
    print('💰 Resultado actualización pago: $exito');

    if (!context.mounted) return;

    if (exito) {
      print('📝 Registrando actividad de pago...');
      final registroExito = await _pedidoService.registrarActividad(
        pedidoId: _pedidoActual.id,
        tipoAccion: 'pago',
        descripcion: 'Pago registrado de \$${monto.toStringAsFixed(2)}',
        valorAnterior: '\$${saldoActual.toStringAsFixed(2)}',
        valorNuevo: '\$${nuevoSaldo.toStringAsFixed(2)}',
      );
      print('📝 Resultado registro actividad: $registroExito');

      final pedidoActualizado = _pedidoActual.copyWith(
        saldo: nuevoSaldo,
        fechaActualizacion: DateTime.now(),
      );
      setState(() {
        _pedidoActual = pedidoActualizado;
      });
      widget.onPedidoActualizado(pedidoActualizado);
      await _cargarHistorial();
      print('✅ Historial recargado, cantidad: ${_historial.length}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pago registrado: \$${monto.toStringAsFixed(2)}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al registrar pago'),
          backgroundColor: Colors.red,
        ),
      );
    }
    print('💰 ===== FIN REGISTRO DE PAGO =====');
  }

  /// Modal para cambiar PRIORIDAD
  void _mostrarModalPrioridad() {
    final prioridades = [
      'Alta',
      'Media',
      'Baja',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Cambiar Prioridad',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xff102A43),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cliente: ${_pedidoActual.clienteNombre}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              ...prioridades.map((prioridad) {
                final isSelected = _pedidoActual.prioridad == prioridad;
                final colorPrioridad = _getPrioridadColor(prioridad);
                
                return ListTile(
                  leading: Radio<String>(
                    value: prioridad,
                    groupValue: _pedidoActual.prioridad,
                    activeColor: colorPrioridad,
                    onChanged: (value) {
                      if (value != null) {
                        _actualizarPrioridad(value);
                        Navigator.pop(context);
                      }
                    },
                  ),
                  title: Row(
                    children: [
                      Text(
                        _getPrioridadIcon(prioridad),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        prioridad,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? colorPrioridad : const Color(0xff102A43),
                        ),
                      ),
                    ],
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: colorPrioridad)
                      : null,
                  onTap: () {
                    _actualizarPrioridad(prioridad);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff6D3EFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Cerrar'),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  /// Actualizar prioridad
  void _actualizarPrioridad(String nuevaPrioridad) async {
    print('🔄 ===== ACTUALIZANDO PRIORIDAD =====');
    print('🔄 Pedido ID: ${_pedidoActual.id}');
    print('🔄 Prioridad actual: ${_pedidoActual.prioridad}');
    print('🔄 Nueva prioridad: $nuevaPrioridad');
    
    if (nuevaPrioridad == _pedidoActual.prioridad) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La prioridad ya es esa'),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    final prioridadAnterior = _pedidoActual.prioridad ?? 'Media';

    final exito = await _pedidoService.actualizarPrioridadPedido(
      _pedidoActual.id,
      nuevaPrioridad,
    );
    print('🔄 Resultado actualización prioridad: $exito');

    if (!context.mounted) return;

    if (exito) {
      print('📝 Registrando actividad de cambio de prioridad...');
      final registroExito = await _pedidoService.registrarActividad(
        pedidoId: _pedidoActual.id,
        tipoAccion: 'cambio_prioridad',
        descripcion: 'Prioridad cambiada de $prioridadAnterior a $nuevaPrioridad',
        valorAnterior: prioridadAnterior,
        valorNuevo: nuevaPrioridad,
      );
      print('📝 Resultado registro actividad: $registroExito');

      final pedidoActualizado = _pedidoActual.copyWith(
        prioridad: nuevaPrioridad,
        fechaActualizacion: DateTime.now(),
      );
      setState(() {
        _pedidoActual = pedidoActualizado;
      });
      widget.onPedidoActualizado(pedidoActualizado);
      await _cargarHistorial();
      print('✅ Historial recargado, cantidad: ${_historial.length}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Prioridad actualizada a: $nuevaPrioridad'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al actualizar prioridad'),
          backgroundColor: Colors.red,
        ),
      );
    }
    print('🔄 ===== FIN ACTUALIZAR PRIORIDAD =====');
  }

  Color _getPrioridadColor(String prioridad) {
    switch (prioridad) {
      case 'Alta':
        return const Color(0xFFEF4444);
      case 'Media':
        return const Color(0xFFF59E0B);
      case 'Baja':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  String _getPrioridadIcon(String prioridad) {
    switch (prioridad) {
      case 'Alta':
        return '🔴';
      case 'Media':
        return '🟠';
      case 'Baja':
        return '🟢';
      default:
        return '⚪';
    }
  }

  /// Mostrar historial completo
  void _mostrarHistorialCompleto() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Historial de Actividad',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color(0xff102A43),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cliente: ${_pedidoActual.clienteNombre}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _cargandoHistorial
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xff6D3EFF),
                            ),
                          )
                        : _historial.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.history,
                                      size: 60,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'No hay actividad registrada',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Los cambios de prioridad y pagos\nse registrarán aquí automáticamente',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: _historial.length,
                                itemBuilder: (context, index) {
                                  final actividad = _historial[index];
                                  return _buildActividadItem(actividad);
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Construir item de actividad
  Widget _buildActividadItem(Map<String, dynamic> actividad) {
    final tipoAccion = actividad['tipo_accion'] as String? ?? '';
    final descripcion = actividad['descripcion'] as String? ?? '';
    final fecha = actividad['fecha_creacion'] != null
        ? DateTime.parse(actividad['fecha_creacion'])
        : DateTime.now();

    IconData icono;
    Color color;
    String emoji;

    switch (tipoAccion) {
      case 'cambio_prioridad':
        icono = Icons.trending_up;
        color = const Color(0xFF8B5CF6);
        emoji = '🔄';
        break;
      case 'pago':
        icono = Icons.attach_money;
        color = const Color(0xFF10B981);
        emoji = '💰';
        break;
      case 'cambio_estado':
        icono = Icons.sync;
        color = const Color(0xFF3B82F6);
        emoji = '📋';
        break;
      default:
        icono = Icons.info;
        color = Colors.grey;
        emoji = '📌';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  descripcion,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xff102A43),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatearFecha(fecha),
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                  ),
                ),
                if (actividad['valor_anterior'] != null ||
                    actividad['valor_nuevo'] != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${actividad['valor_anterior'] ?? ''} → ${actividad['valor_nuevo'] ?? ''}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inMinutes < 1) {
      return 'Hace un momento';
    } else if (diferencia.inMinutes < 60) {
      return 'Hace ${diferencia.inMinutes} min';
    } else if (diferencia.inHours < 24) {
      return 'Hace ${diferencia.inHours} h';
    } else if (diferencia.inDays < 7) {
      return 'Hace ${diferencia.inDays} d';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget tarjetaInfo({
    required String titulo,
    required Widget child,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xff6D3EFF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xff6D3EFF), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff102A43),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pedido = _pedidoActual;
    final isPaid = (pedido.saldo ?? 0) == 0;
    final String clienteEncoded = Uri.encodeComponent(pedido.clienteNombre);

    final String entregaFormateada = pedido.fechaEntrega != null
        ? pedido.fechaEntrega!.toLocal().toString().substring(0, 10)
        : 'N/A';

    final String qrData =
        'tallercostura://pedido/${pedido.id}?cliente=$clienteEncoded&entrega=$entregaFormateada';

    final colorPrioridad = _getPrioridadColor(pedido.prioridad ?? 'Media');
    final iconPrioridad = _getPrioridadIcon(pedido.prioridad ?? 'Media');

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Ficha Técnica',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Color(0xff102A43),
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xff6D3EFF)),
            onPressed: _cargarHistorial,
            tooltip: 'Recargar historial',
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isPaid ? null : _mostrarModalPago,
                  icon: Icon(
                    isPaid ? Icons.check_circle : Icons.attach_money,
                    color: Colors.white,
                  ),
                  label: Text(
                    isPaid ? "Cobro Completado" : "Registrar Pago",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPaid
                        ? Colors.green
                        : const Color(0xff6D3EFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _mostrarModalPrioridad,
                  icon: Text(
                    iconPrioridad,
                    style: const TextStyle(fontSize: 18),
                  ),
                  label: Text(
                    pedido.prioridad ?? 'Media',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colorPrioridad,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colorPrioridad.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// CABECERA
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorPrioridad.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colorPrioridad.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          iconPrioridad,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'PRIORIDAD ${pedido.prioridad?.toUpperCase() ?? 'MEDIA'}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorPrioridad,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    pedido.id,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff102A43),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Color(0xff829AB1),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Entrega: ${pedido.fechaEntrega?.toLocal().toString().substring(0, 10) ?? 'N/A'}",
                        style: const TextStyle(color: Color(0xff64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.trending_up,
                        size: 14,
                        color: Color(0xff829AB1),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Estado: ${pedido.estado}",
                        style: const TextStyle(
                          color: Color(0xff64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            /// CLIENTE
            tarjetaInfo(
              titulo: "Información del Cliente",
              icon: Icons.person_outline,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(
                      0xff6D3EFF,
                    ).withValues(alpha: 0.1),
                    child: Text(
                      pedido.clienteNombre.isNotEmpty
                          ? pedido.clienteNombre[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff6D3EFF),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pedido.clienteNombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xff102A43),
                          ),
                        ),
                        Text(
                          pedido.clienteTelefono,
                          style: const TextStyle(color: Color(0xff64748B)),
                        ),
                        Text(
                          pedido.clienteEmail ?? '',
                          style: const TextStyle(color: Color(0xff64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            /// PRENDA
            tarjetaInfo(
              titulo: "Detalles de la Prenda",
              icon: Icons.checkroom,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pedido.titulo ?? 'Sin título',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xff102A43),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pedido.descripcion ?? 'Sin descripción',
                    style: const TextStyle(color: Color(0xff64748B)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Total: \$${(pedido.total ?? 0).toStringAsFixed(2)} MXN",
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xff64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            /// MEDIDAS
            if (pedido.medidas != null && pedido.medidas!.isNotEmpty)
              tarjetaInfo(
                titulo: "Mediciones",
                icon: Icons.straighten,
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.2,
                  children: pedido.medidas!.map((medida) {
                    return _medidaItem(
                      medida.tipoMedida,
                      medida.valor.toString(),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 16),

            /// HISTORIAL DE ACTIVIDAD
            tarjetaInfo(
              titulo: "Actividad Reciente",
              icon: Icons.history,
              child: _cargandoHistorial
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: SizedBox(
                          height: 30,
                          width: 30,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xff6D3EFF),
                          ),
                        ),
                      ),
                    )
                  : _historial.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Column(
                            children: [
                              Icon(Icons.inbox, size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                "No hay actividad reciente",
                                style: TextStyle(color: Colors.grey),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Cambia prioridad o registra un pago",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            ..._historial.take(3).map((actividad) {
                              return _buildActividadItem(actividad);
                            }).toList(),
                            if (_historial.length > 3)
                              Center(
                                child: TextButton(
                                  onPressed: _mostrarHistorialCompleto,
                                  child: const Text(
                                    "Ver historial completo →",
                                    style: TextStyle(
                                      color: Color(0xff6D3EFF),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
            ),
            const SizedBox(height: 16),

            /// QR CODE
            Screenshot(
              controller: _screenshotController,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xff6D3EFF,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.qr_code,
                            color: Color(0xff6D3EFF),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Código QR',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff102A43),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _pedidoActual.id,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff102A43),
                      ),
                    ),
                    Text(
                      _pedidoActual.clienteNombre,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      'Entrega: $entregaFormateada',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _compartirEtiqueta,
                      icon: const Icon(Icons.share),
                      label: const Text('Compartir / Imprimir etiqueta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff6D3EFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'Sin empezar':
        return Colors.grey;
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

  Widget _medidaItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontSize: 11, color: Color(0xff829AB1)),
          ),
          const SizedBox(height: 2),
          Text(
            '$value cm',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xff102A43),
            ),
          ),
        ],
      ),
    );
  }
}