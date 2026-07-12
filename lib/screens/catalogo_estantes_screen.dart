import 'package:flutter/material.dart';
import '../models/pedido.dart';
import '../models/estante.dart';
import 'agregar_estante_screen.dart';

class CatalogoEstantesScreen extends StatefulWidget {
  final List<Estante> estantes;
  final List<Pedido> pedidos;
  final Function(String pedidoId) onNavigateToDetallePedido;
  final Function(List<Estante>) onEstantesActualizados;

  const CatalogoEstantesScreen({
    super.key,
    required this.estantes,
    required this.pedidos,
    required this.onNavigateToDetallePedido,
    required this.onEstantesActualizados,
  });

  @override
  State<CatalogoEstantesScreen> createState() => _CatalogoEstantesScreenState();
}

class _CatalogoEstantesScreenState extends State<CatalogoEstantesScreen> {
  late List<Estante> _estantes;
  late List<Pedido> _pedidos;

  @override
  void initState() {
    super.initState();
    _estantes = List.from(widget.estantes);
    _pedidos = List.from(widget.pedidos);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _actualizarConteoEstantes();
    });
  }

  @override
  void didUpdateWidget(CatalogoEstantesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pedidos != oldWidget.pedidos || widget.estantes != oldWidget.estantes) {
      _estantes = List.from(widget.estantes);
      _pedidos = List.from(widget.pedidos);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _actualizarConteoEstantes();
      });
    }
  }

  void _actualizarConteoEstantes() {
    final Map<String, int> conteoEstantes = {};

    for (var estante in _estantes) {
      conteoEstantes[estante.id] = 0;
    }

    for (var pedido in _pedidos) {
      if (pedido.estado != "Entregado") {
        final estanteId = pedido.estanteId;
        if (estanteId != null && conteoEstantes.containsKey(estanteId)) {
          conteoEstantes[estanteId] = (conteoEstantes[estanteId] ?? 0) + 1;
        }
      }
    }

    bool hayCambios = false;
    for (int i = 0; i < _estantes.length; i++) {
      final estante = _estantes[i];
      final count = conteoEstantes[estante.id] ?? 0;

      if (estante.ocupados != count) {
        hayCambios = true;
        _estantes[i] = Estante(
          id: estante.id,
          nombre: estante.nombre,
          ubicacion: estante.ubicacion,
          descripcion: estante.descripcion,
          capacidad: estante.capacidad,
          ocupados: count,
          fechaCreacion: estante.fechaCreacion,
          fechaActualizacion: DateTime.now(),
        );
      }
    }

    if (hayCambios) {
      widget.onEstantesActualizados(_estantes);
    }
  }

  String _obtenerEstado(int ocupados, int capacidad) {
    if (ocupados == 0) return "Abierto";
    final percentage = ocupados / capacidad;
    if (percentage >= 1.0) return "Lleno";
    if (percentage >= 0.75) return "Casi Lleno";
    return "Abierto";
  }

  void abrirEstante(Estante estante) {
    final pedidosActivos = _pedidos.where(
      (p) => p.estanteId == estante.id && p.estado != "Entregado",
    ).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Container(
          height: MediaQuery.of(context).size.height * .75,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Estante ${estante.nombre}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff102A43),
                        ),
                      ),
                      Text(
                        "${pedidosActivos.length} de ${estante.capacidad} prendas almacenadas",
                        style: const TextStyle(
                          color: Color(0xff64748B),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Expanded(
                child: pedidosActivos.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.layers,
                              size: 60,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Este estante está vacío",
                              style: TextStyle(
                                color: Color(0xff64748B),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: pedidosActivos.length,
                        itemBuilder: (context, index) {
                          final pedido = pedidosActivos[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: Text(
                                pedido.titulo ?? 'Sin título',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff102A43),
                                ),
                              ),
                              subtitle: Text(
                                "Cliente: ${pedido.clienteNombre}",
                                style: const TextStyle(
                                  color: Color(0xff64748B),
                                ),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Color(0xff829AB1),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                widget.onNavigateToDetallePedido(pedido.id);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _agregarEstante(Estante nuevoEstante) {
    setState(() {
      _estantes.add(nuevoEstante);
    });
    widget.onEstantesActualizados(_estantes);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Estante ${nuevoEstante.nombre} creado correctamente'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Color estadoColor(String estado) {
    switch (estado) {
      case "Abierto":
        return Colors.green;
      case "Casi Lleno":
        return Colors.orange;
      case "Lleno":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _chipEstadistica(String texto, Color colorTexto, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: colorTexto,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalEstantes = _estantes.length;
    final disponiblesCount = _estantes.where((e) => _obtenerEstado(e.ocupados, e.capacidad) == "Abierto").length;
    final casiLlenosCount = _estantes.where((e) => _obtenerEstado(e.ocupados, e.capacidad) == "Casi Lleno").length;
    final llenosCount = _estantes.where((e) => _obtenerEstado(e.ocupados, e.capacidad) == "Lleno").length;

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xff6D3EFF),
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AgregarEstanteScreen(
                onAgregarEstante: _agregarEstante,
              ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text(
          "Agregar Estante",
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            /// HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xffE5E7EB),
                  ),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Organizador de Estantes",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff0F172A),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Control de almacenamiento de prendas del taller",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xff94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    /// RESUMEN
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _chipEstadistica(
                          "ESTANTES TOTALES: $totalEstantes",
                          const Color(0xff6D3EFF),
                          const Color(0xffEEF2FF),
                        ),
                        _chipEstadistica(
                          "DISPONIBLES: $disponiblesCount",
                          const Color(0xff15803D),
                          const Color(0xffDCFCE7),
                        ),
                        _chipEstadistica(
                          "CASI LLENOS: $casiLlenosCount",
                          const Color(0xffD97706),
                          const Color(0xffFEF3C7),
                        ),
                        _chipEstadistica(
                          "SATURADOS: $llenosCount",
                          const Color(0xffDC2626),
                          const Color(0xffFEE2E2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xffE5E7EB),
                        ),
                      ),
                      child: const Text(
                        "💡 Puedes pulsar sobre cualquier estante del taller para visualizar las prendas asignadas.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xff64748B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _estantes.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.05,
                      ),
                      itemBuilder: (context, index) {
                        final estante = _estantes[index];
                        final estado = _obtenerEstado(estante.ocupados, estante.capacidad);
                        final usagePercent = estante.capacidad > 0
                            ? estante.ocupados / estante.capacidad
                            : 0.0;

                        return InkWell(
                          onTap: () => abrirEstante(estante),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: const Color(0xffE5E7EB),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    /// ✅ NOMBRE DEL ESTANTE CON 3 PUNTOS SI ES LARGO
                                    Expanded(
                                      child: Text(
                                        estante.nombre,
                                        style: const TextStyle(
                                          fontSize: 42,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xff0F172A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis, // ✅ 3 PUNTOS
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: estadoColor(estado).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Text(
                                        estado.toUpperCase(),
                                        style: TextStyle(
                                          color: estadoColor(estado),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 25),
                                Text(
                                  "Capacidad",
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const SizedBox(),
                                    Text(
                                      "${estante.ocupados}/${estante.capacidad} prendas",
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xff102A43),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: LinearProgressIndicator(
                                    value: usagePercent > 1.0 ? 1.0 : usagePercent,
                                    minHeight: 12,
                                    color: estadoColor(estado),
                                    backgroundColor: Colors.grey.shade200,
                                  ),
                                ),
                                const Spacer(),
                                Divider(
                                  color: Colors.grey.shade200,
                                ),
                                Text(
                                  estante.ocupados > 0
                                      ? '${estante.ocupados} prenda${estante.ocupados > 1 ? 's' : ''} en almacenamiento'
                                      : 'Estante vacío',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}