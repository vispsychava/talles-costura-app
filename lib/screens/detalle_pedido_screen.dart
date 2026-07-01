import 'package:flutter/material.dart';
import '../models/pedido.dart';
import '../services/pedido_service.dart';


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
  late String estadoSeleccionado;
  late Pedido _pedidoActual;
  final _pedidoService = PedidoService();

  @override
  void initState() {
    super.initState();
    _pedidoActual = widget.pedido;
    montoPago = _pedidoActual.saldo ?? 0;
    estadoSeleccionado = _pedidoActual.estado;
  }

  void _mostrarModalPago() {
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
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
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
                  montoPago = double.tryParse(value) ?? (_pedidoActual.saldo ?? 0);
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

void _registrarPago(double monto) async {
   print(' Registrando pago para pedido ID: ${_pedidoActual.id}');
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

  final exito = await _pedidoService.actualizarEstadoPago(
    _pedidoActual.id,
    nuevoSaldo,
  );

  if (!context.mounted) return;

  if (exito) {
    final pedidoActualizado = _pedidoActual.copyWith(
      saldo: nuevoSaldo,
      fechaActualizacion: DateTime.now(),
    );
    setState(() => _pedidoActual = pedidoActualizado);
    widget.onPedidoActualizado(pedidoActualizado);
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
}

  void _mostrarModalEstado() {
    final estados = ['Sin empezar', 'En proceso', 'Terminado', 'Entregado', 'Atrasado'];

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
                'Actualizar Estado',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xff102A43),
                ),
              ),
              const SizedBox(height: 16),
              ...estados.map((estado) {
                final isSelected = _pedidoActual.estado == estado;
                return ListTile(
                  leading: Radio<String>(
                    value: estado,
                    groupValue: _pedidoActual.estado,
                    activeColor: const Color(0xff6D3EFF),
                    onChanged: (value) {
                      if (value != null) {
                        _actualizarEstado(value);
                        Navigator.pop(context);
                      }
                    },
                  ),
                  title: Text(
                    estado,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xff6D3EFF) : const Color(0xff102A43),
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Color(0xff6D3EFF))
                      : null,
                );
              }).toList(),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _actualizarEstado(String nuevoEstado) async {
     print(' Actualizando pedido ID: ${_pedidoActual.id} → $nuevoEstado');
  if (nuevoEstado == _pedidoActual.estado) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('El estado ya es ese'),
        backgroundColor: Colors.blue,
      ),
    );
    return;
  }

  final exito = await _pedidoService.actualizarEstadoPedido(
    _pedidoActual.id,
    nuevoEstado,
  );

  if (!context.mounted) return;

  if (exito) {
    final pedidoActualizado = _pedidoActual.copyWith(
      estado: nuevoEstado,
      fechaActualizacion: DateTime.now(),
    );
    setState(() => _pedidoActual = pedidoActualizado);
    widget.onPedidoActualizado(pedidoActualizado);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Estado actualizado a: $nuevoEstado'),
        backgroundColor: Colors.green,
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error al actualizar estado'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  void _mostrarModalHistorial() {
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
                'Historial de Actividad',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xff102A43),
                ),
              ),
              const SizedBox(height: 16),
              if (_pedidoActual.prendas == null || _pedidoActual.prendas!.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.history, size: 50, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'No hay actividad registrada',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _pedidoActual.prendas!.length,
                  itemBuilder: (context, index) {
                    final prenda = _pedidoActual.prendas![index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xff6D3EFF).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.checkroom,
                              color: Color(0xff6D3EFF),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  prenda.nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff102A43),
                                  ),
                                ),
                                Text(
                                  'Talla: ${prenda.talla ?? 'N/A'} • Estado: ${prenda.estado ?? 'Pendiente'}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '${prenda.fechaCreacion.day}/${prenda.fechaCreacion.month}/${prenda.fechaCreacion.year}',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
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
                    backgroundColor: isPaid ? Colors.green : const Color(0xff6D3EFF),
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
                  onPressed: _mostrarModalEstado,
                  icon: const Icon(Icons.sync),
                  label: const Text(
                    "Estado",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
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
                      color: _getEstadoColor(pedido.estado).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      pedido.estado.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getEstadoColor(pedido.estado),
                        fontSize: 13,
                      ),
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
                        style: const TextStyle(
                          color: Color(0xff64748B),
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
                    backgroundColor: const Color(0xff6D3EFF).withValues(alpha: 0.1),
                    child: Text(
                      pedido.clienteNombre.isNotEmpty ? pedido.clienteNombre[0].toUpperCase() : '?',
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
                          style: const TextStyle(
                            color: Color(0xff64748B),
                          ),
                        ),
                        Text(
                          pedido.clienteEmail ?? '',
                          style: const TextStyle(
                            color: Color(0xff64748B),
                          ),
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
                    style: const TextStyle(
                      color: Color(0xff64748B),
                    ),
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

            /// PRENDAS (Actividad Reciente)
            tarjetaInfo(
              titulo: "Actividad Reciente",
              icon: Icons.history,
              child: (pedido.prendas == null || pedido.prendas!.isEmpty)
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox,
                            size: 40,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "No hay actividad registrada",
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pedido.prendas!.length > 3 ? 3 : pedido.prendas!.length,
                      itemBuilder: (context, index) {
                        final prenda = pedido.prendas![index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xff6D3EFF).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.checkroom,
                                  color: Color(0xff6D3EFF),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      prenda.nombre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Color(0xff102A43),
                                      ),
                                    ),
                                    Text(
                                      'Talla: ${prenda.talla ?? 'N/A'}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${prenda.fechaCreacion.day}/${prenda.fechaCreacion.month}',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),

            /// BOTÓN VER HISTORIAL COMPLETO
            if (pedido.prendas != null && pedido.prendas!.length > 3)
              Center(
                child: TextButton(
                  onPressed: _mostrarModalHistorial,
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
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xff829AB1),
            ),
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