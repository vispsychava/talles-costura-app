import 'package:flutter/material.dart';
import 'package:talles_costura_app/services/recordatorio_service.dart';
import '../models/estante.dart';
import '../services/supabase_service.dart';
import '../widgets/selectores_personalizados.dart';

class NuevoPedidoScreen extends StatefulWidget {
  final List<Estante> estantes;
  final Function(Map<String, dynamic>) onGuardarPedido;

  const NuevoPedidoScreen({
    super.key,
    required this.estantes,
    required this.onGuardarPedido,
  });

  @override
  State<NuevoPedidoScreen> createState() => _NuevoPedidoScreenState();
}

class _NuevoPedidoScreenState extends State<NuevoPedidoScreen> {
  final _pedidoService = SupabaseService();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  final clienteNombreController = TextEditingController();
  final telefonoController = TextEditingController();
  final emailController = TextEditingController();
  final tallaController = TextEditingController();
  final descripcionController = TextEditingController();

  String? estanteAsignado;
  String tipoPrenda = "vestido";
  String prioridad = "Media";
  DateTime fechaEntrega = DateTime.now();

  double total = 0;
  double anticipo = 0;
  double saldo = 0;

  bool _showMeasurements = false;

  // ✅ Medidas dinámicas
  List<Map<String, dynamic>> _medidasDinamicas = [];
  Map<int, TextEditingController> _medidaControllers = {};
  bool _cargandoMedidas = false;

  List<Estante> get _estantesDisponibles {
    return widget.estantes.where((estante) {
      return estante.ocupados < estante.capacidad;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    if (_estantesDisponibles.isNotEmpty) {
      estanteAsignado = _estantesDisponibles.first.id;
    }
    final now = DateTime.now();
    fechaEntrega = DateTime(now.year, now.month, now.day);
    _cargarMedidasPorPrenda(tipoPrenda);
  }

  @override
  void dispose() {
    clienteNombreController.dispose();
    telefonoController.dispose();
    emailController.dispose();
    tallaController.dispose();
    descripcionController.dispose();
    for (var c in _medidaControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cargarMedidasPorPrenda(String tipo) async {
    setState(() => _cargandoMedidas = true);

    final idPrenda = SupabaseService.idPrendaPorTipo[tipo] ?? 3;
    final medidas = await _pedidoService.obtenerMedidasPorTipoPrenda(idPrenda);

    for (var c in _medidaControllers.values) {
      c.dispose();
    }

    final newControllers = <int, TextEditingController>{};
    for (var medida in medidas) {
      newControllers[medida['id_tipo_medida'] as int] = TextEditingController();
    }

    setState(() {
      _medidasDinamicas = medidas;
      _medidaControllers = newControllers;
      _cargandoMedidas = false;
    });
  }

  void calcularSaldo() {
    setState(() {
      saldo = (total - anticipo);
      if (saldo < 0) saldo = 0;
    });
  }

  InputDecoration _input(String label) {
    return inputDecoration(label);
  }

  Widget _seccionCard({
    required String titulo,
    required IconData icon,
    required Widget child,
  }) {
    return seccionCard(titulo: titulo, icon: icon, child: child);
  }

  String _formatearFecha(DateTime fecha) {
    return formatearFechaLarga(fecha);
  }

  @override
  Widget build(BuildContext context) {
    final estantesDisponibles = _estantesDisponibles;

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          "Registrar Nuevo Pedido",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Color(0xff102A43),
          ),
        ),
        centerTitle: false,
        // ✅ Botones en la AppBar (derecha)
        actions: [
          // Botón Cancelar
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
            child: const Text(
              "Cancelar",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 4),
          // Botón Guardar
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () async {
                    if (!_formKey.currentState!.validate()) return;

                    if (estanteAsignado == null || estanteAsignado!.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Selecciona un estante"),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    final fechaEntregaStr =
                        '${fechaEntrega.year}-'
                        '${fechaEntrega.month.toString().padLeft(2, '0')}-'
                        '${fechaEntrega.day.toString().padLeft(2, '0')}';

                    final timestamp = DateTime.now().millisecondsSinceEpoch;
                    final id = 'ORD-${timestamp.toString().substring(7)}';

                    final nuevoPedido = {
                      'id': id,
                      'clientName': clienteNombreController.text.trim(),
                      'clientPhone': telefonoController.text.trim(),
                      'clientEmail': emailController.text.trim(),
                      'shelfAssignment': estanteAsignado!,
                      'priority': prioridad,
                      'garmentType': tipoPrenda,
                      'title':
                          '${tipoPrenda.toUpperCase()} - ${clienteNombreController.text.trim()}',
                      'size': tallaController.text.trim(),
                      'description': descripcionController.text.trim(),
                      'deliveryDate': fechaEntregaStr,
                      'expectedDeliveryDate': fechaEntregaStr,
                      'totalAmount': total,
                      'advancePaid': anticipo,
                      'balanceDue': saldo,
                      'status': 'Sin empezar',
                      'statusDate': DateTime.now().toIso8601String(),
                    };

                    setState(() => _isLoading = true);
                    final idPedido = await _pedidoService.insertarPedido(
                      nuevoPedido,
                    );

                    if (idPedido != null) {
                      // ✅ Armar y guardar las medidas capturadas
                      final medidasParaGuardar = <Map<String, dynamic>>[];
                      for (var entry in _medidaControllers.entries) {
                        final valor = double.tryParse(entry.value.text.trim());
                        if (valor != null && valor > 0) {
                          medidasParaGuardar.add({
                            'idTipoMedida': entry.key,
                            'valor': valor,
                          });
                        }
                      }
                      await _pedidoService.insertarMedidasPedido(
                        idPedido,
                        medidasParaGuardar,
                      );
                    }
                    setState(() => _isLoading = false);

                    if (!context.mounted) return;

                    if (idPedido != null) {
                      await NotificationService().scheduleNotificacionPedido(
                        pedidoId: id,
                        titulo:
                            '${tipoPrenda.toUpperCase()} - ${clienteNombreController.text.trim()}',
                        fechaEntrega: fechaEntrega,
                      );
                      widget.onGuardarPedido(nuevoPedido);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Pedido guardado correctamente"),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Error al guardar. Revisa tu conexión"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff6D3EFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "Guardar",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              /// INFORMACIÓN DEL CLIENTE
              _seccionCard(
                titulo: "Información del Cliente",
                icon: Icons.person_outline,
                child: Column(
                  children: [
                    TextFormField(
                      controller: clienteNombreController,
                      decoration: _input("Nombre Completo"),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xff102A43),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "El nombre es obligatorio";
                        }
                        if (value.length < 3) {
                          return "Mínimo 3 caracteres";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: telefonoController,
                            decoration: _input("Teléfono"),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xff102A43),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Obligatorio";
                              }
                              if (!RegExp(r'^[0-9]{10,15}$').hasMatch(value)) {
                                return "10-15 dígitos";
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: emailController,
                            decoration: _input("Correo Electrónico"),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xff102A43),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              /// DETALLES DE LA PRENDA
              _seccionCard(
                titulo: "Detalles de la Prenda",
                icon: Icons.checkroom,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: tipoPrenda,
                      decoration: _input("Tipo de Prenda"),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xff102A43),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "vestido",
                          child: Text("Vestido"),
                        ),
                        DropdownMenuItem(
                          value: "pantalon",
                          child: Text("Pantalón"),
                        ),
                        DropdownMenuItem(value: "saco", child: Text("Saco")),
                        DropdownMenuItem(value: "falda", child: Text("Falda")),
                        DropdownMenuItem(value: "blusa", child: Text("Blusa")),
                        DropdownMenuItem(
                          value: "camisa",
                          child: Text("Camisa"),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => tipoPrenda = value!);
                        _cargarMedidasPorPrenda(value!);
                      },
                    ),
                    const SizedBox(height: 16),

                    /// TOGGLE MEDICIONES
                    InkWell(
                      onTap: () {
                        setState(() => _showMeasurements = !_showMeasurements);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _showMeasurements
                              ? const Color(0xff6D3EFF).withValues(alpha: 0.08)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _showMeasurements
                                ? const Color(0xff6D3EFF)
                                : Colors.grey.shade200,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.straighten,
                                  color: _showMeasurements
                                      ? const Color(0xff6D3EFF)
                                      : Colors.grey.shade600,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _showMeasurements
                                      ? "Ocultar Mediciones"
                                      : "Agregar Mediciones",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _showMeasurements
                                        ? const Color(0xff6D3EFF)
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              _showMeasurements
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: _showMeasurements
                                  ? const Color(0xff6D3EFF)
                                  : Colors.grey.shade600,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),

                    /// MEDIDAS DINÁMICAS
                    if (_showMeasurements)
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: _cargandoMedidas
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(
                                    color: Color(0xff6D3EFF),
                                  ),
                                ),
                              )
                            : _medidasDinamicas.isEmpty
                            ? const Text('No hay medidas disponibles')
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                      childAspectRatio: 3,
                                    ),
                                itemCount: _medidasDinamicas.length,
                                itemBuilder: (context, index) {
                                  final medida = _medidasDinamicas[index];
                                  final idTipoMedida =
                                      medida['id_tipo_medida'] as int;
                                  final nombre = medida['nombre'] as String;
                                  return _campoMedidaCompacto(
                                    nombre,
                                    _medidaControllers[idTipoMedida]!,
                                  );
                                },
                              ),
                      ),

                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descripcionController,
                      maxLines: 4,
                      minLines: 3,
                      decoration: _input(
                        "Descripción de la Modificación / Trabajo",
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xff102A43),
                      ),
                    ),
                    const SizedBox(height: 16),
                    /*TextFormField(
                      controller: tallaController,
                      decoration: _input("Talla / Medidas Clave"),
                      style: const TextStyle(
                          fontSize: 16, color: Color(0xff102A43)),
                    ),*/
                  ],
                ),
              ),
              const SizedBox(height: 20),

              /// UBICACIÓN EN TALLER
              _seccionCard(
                titulo: "Ubicación de estante",
                icon: Icons.location_on_outlined,
                child: Column(
                  children: [
                    if (estantesDisponibles.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "No hay estantes disponibles.",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: estanteAsignado,
                        decoration: _input("Asignación de Estante"),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xff102A43),
                        ),
                        items: estantesDisponibles.map((estante) {
                          final remaining =
                              estante.capacidad - estante.ocupados;
                          return DropdownMenuItem(
                            value: estante.id,
                            child: Text(
                              "${estante.id} (${estante.ocupados}/${estante.capacidad}) - $remaining disponibles",
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xff102A43),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => estanteAsignado = value!);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Selecciona un estante";
                          }
                          return null;
                        },
                      ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Prioridad del Trabajo",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _opcionPrioridad("Baja", Icons.arrow_downward),
                            const SizedBox(width: 16),
                            _opcionPrioridad("Media", Icons.remove),
                            const SizedBox(width: 16),
                            _opcionPrioridad("Alta", Icons.arrow_upward),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              /// ACUERDO FINANCIERO Y ENTREGA
              _seccionCard(
                titulo: "Acuerdo Financiero y Entrega",
                icon: Icons.payments_outlined,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () async {
                          // ✅ Ahora usa el mismo calendario personalizado
                          // compartido con la pantalla de Recordatorios.
                          final fecha = await mostrarSelectorFecha(
                            context,
                            fechaInicial: fechaEntrega,
                          );
                          if (fecha != null) {
                            setState(() => fechaEntrega = fecha);
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  color: Color(0xff6D3EFF),
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "Fecha de Entrega",
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xff6D3EFF,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _formatearFecha(fechaEntrega),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff6D3EFF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              "Costo Total",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: "\$0.00",
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                              onChanged: (value) {
                                total = double.tryParse(value) ?? 0;
                                calcularSaldo();
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Obligatorio";
                                }
                                final v = double.tryParse(value);
                                if (v == null || v <= 0) {
                                  return "Monto inválido";
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              "Anticipo / Depósito",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: "\$0.00",
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                              onChanged: (value) {
                                anticipo = double.tryParse(value) ?? 0;
                                calcularSaldo();
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Obligatorio";
                                }
                                final v = double.tryParse(value);
                                if (v == null || v < 0) {
                                  return "Monto inválido";
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Saldo Remanente",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            "\$ ${saldo.toStringAsFixed(2)} MXN",
                            style: const TextStyle(
                              color: Color(0xff6D3EFF),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ✅ Espacio extra al final para que el contenido no quede pegado
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campoMedidaCompacto(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
        hintText: 'cm',
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 11),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xff6D3EFF), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 13, color: Color(0xff102A43)),
    );
  }

  Widget _opcionPrioridad(String label, IconData icon) {
    final isSelected = prioridad == label;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => prioridad = label),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xff6D3EFF).withValues(alpha: 0.1)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xff6D3EFF)
                  : Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? const Color(0xff6D3EFF)
                    : Colors.grey.shade500,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? const Color(0xff6D3EFF)
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
