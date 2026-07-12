import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:talles_costura_app/services/recordatorio_service.dart';
import '../models/estante.dart';
import '../services/supabase_service.dart';

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

  final TextEditingController bustoController = TextEditingController();
  final TextEditingController cinturaController = TextEditingController();
  final TextEditingController caderaController = TextEditingController();
  final TextEditingController largoController = TextEditingController();

  String? estanteAsignado;
  String tipoPrenda = "vestido";
  String prioridad = "Media";
  DateTime fechaEntrega = DateTime.now();

  double total = 0;
  double anticipo = 0;
  double saldo = 0;

  bool _showMeasurements = false;

  List<Estante> get _estantesDisponibles {
    return widget.estantes.where((estante) {
      return estante.ocupados < estante.capacidad;
    }).toList();
  }

  List<Map<String, dynamic>> get _camposMedida {
    switch (tipoPrenda) {
      case 'vestido':
        return [
          {'label': 'Busto', 'controller': bustoController},
          {'label': 'Cintura', 'controller': cinturaController},
          {'label': 'Cadera', 'controller': caderaController},
          {'label': 'Largo', 'controller': largoController},
        ];
      case 'pantalon':
        return [
          {'label': 'Cintura', 'controller': cinturaController},
          {'label': 'Cadera', 'controller': caderaController},
          {'label': 'Largo', 'controller': largoController},
        ];
      case 'falda':
        return [
          {'label': 'Cintura', 'controller': cinturaController},
          {'label': 'Cadera', 'controller': caderaController},
          {'label': 'Largo', 'controller': largoController},
        ];
      case 'saco':
        return [
          {'label': 'Cintura', 'controller': cinturaController},
          {'label': 'Cadera', 'controller': caderaController},
          {'label': 'Largo', 'controller': largoController},
        ];
      case 'ajuste':
        return [
          {'label': 'Busto', 'controller': bustoController},
          {'label': 'Cintura', 'controller': cinturaController},
          {'label': 'Cadera', 'controller': caderaController},
          {'label': 'Largo', 'controller': largoController},
        ];
      default:
        return [
          {'label': 'Busto', 'controller': bustoController},
          {'label': 'Cintura', 'controller': cinturaController},
          {'label': 'Cadera', 'controller': caderaController},
          {'label': 'Largo', 'controller': largoController},
        ];
    }
  }

  @override
  void initState() {
    super.initState();

    if (_estantesDisponibles.isNotEmpty) {
      estanteAsignado = _estantesDisponibles.first.id;
    }

    final now = DateTime.now();
    fechaEntrega = DateTime(
      now.year,
      now.month,
      now.day,
    );
  }

  void calcularSaldo() {
    setState(() {
      saldo = (total - anticipo);
      if (saldo < 0) saldo = 0;
    });
  }

  InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xff6D3EFF),
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }

  Widget _seccionCard({
    required String titulo,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
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
          )
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
                child: Icon(
                  icon,
                  color: const Color(0xff6D3EFF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff102A43),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _calendarioPersonalizado({
    required DateTime mesActual,
    required Function(DateTime) onDateSelected,
    required DateTime fechaSeleccionada,
    required Function(DateTime) onMesCambiado,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final year = mesActual.year;
    final month = mesActual.month;
    
    final firstDay = DateTime(year, month, 1);
    final firstDayWeekday = firstDay.weekday;
    
    final daysInMonth = DateTime(year, month + 1, 0).day;
    
    final prevMonth = month == 1 ? 12 : month - 1;
    final prevYear = month == 1 ? year - 1 : year;
    final daysInPrevMonth = DateTime(prevYear, prevMonth + 1, 0).day;
    
    final prevMonthDays = List.generate(
      firstDayWeekday - 1,
      (index) => daysInPrevMonth - (firstDayWeekday - 2) + index,
    );
    
    final currentMonthDays = List.generate(daysInMonth, (index) => index + 1);
    
    final totalDays = prevMonthDays.length + currentMonthDays.length;
    final remainingDays = (7 - totalDays % 7) % 7;
    final nextMonthDays = List.generate(remainingDays, (index) => index + 1);
    
    final allDays = [
      ...prevMonthDays.map((d) => {'day': d, 'isCurrentMonth': false}),
      ...currentMonthDays.map((d) => {'day': d, 'isCurrentMonth': true}),
      ...nextMonthDays.map((d) => {'day': d, 'isCurrentMonth': false}),
    ];
    
    List<Widget> rows = [];
    for (int i = 0; i < allDays.length; i += 7) {
      final weekDays = allDays.sublist(i, i + 7 > allDays.length ? allDays.length : i + 7);
      
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays.map((dayInfo) {
              final day = dayInfo['day'] as int;
              final isCurrentMonth = dayInfo['isCurrentMonth'] as bool;
              
              int dayMonth = month;
              int dayYear = year;
              
              if (!isCurrentMonth) {
                if (day > 15) {
                  dayMonth = month - 1;
                  if (dayMonth == 0) {
                    dayMonth = 12;
                    dayYear = year - 1;
                  }
                } else {
                  dayMonth = month + 1;
                  if (dayMonth == 13) {
                    dayMonth = 1;
                    dayYear = year + 1;
                  }
                }
              }
              
              final date = DateTime(dayYear, dayMonth, day);
              
              final isToday = date.year == today.year && 
                             date.month == today.month && 
                             date.day == today.day;
              
              final isSelected = date.year == fechaSeleccionada.year && 
                                date.month == fechaSeleccionada.month && 
                                date.day == fechaSeleccionada.day;
              
              final isBeforeToday = date.isBefore(today);
              final isAfterYear = date.isAfter(today.add(const Duration(days: 365)));
              final isDisabled = isBeforeToday || isAfterYear;
              
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (!isDisabled) {
                      onDateSelected(date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? const Color(0xff6D3EFF)
                          : isToday && !isSelected
                              ? const Color(0xff6D3EFF).withValues(alpha: 0.1)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        day.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isDisabled
                              ? Colors.grey.shade300
                              : isSelected
                                  ? Colors.white
                                  : isToday
                                      ? const Color(0xff6D3EFF)
                                      : isCurrentMonth
                                          ? const Color(0xff102A43)
                                          : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Cabecera con mes y año
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xff6D3EFF),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  onPressed: () {
                    final nuevoMes = DateTime(
                      mesActual.year,
                      mesActual.month - 1,
                      1,
                    );
                    onMesCambiado(nuevoMes);
                  },
                ),
                Text(
                  _formatearMesAnio(mesActual),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                  onPressed: () {
                    final nuevoMes = DateTime(
                      mesActual.year,
                      mesActual.month + 1,
                      1,
                    );
                    onMesCambiado(nuevoMes);
                  },
                ),
              ],
            ),
          ),
          
          // Días de la semana
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['L', 'M', 'Mi', 'J', 'V', 'S', 'D'].map((dia) {
                return Expanded(
                  child: Center(
                    child: Text(
                      dia,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Días del mes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: rows,
            ),
          ),
          
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  String _formatearMesAnio(DateTime fecha) {
    final meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${meses[fecha.month - 1]} ${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    final estantesDisponibles = _estantesDisponibles;
    final camposMedida = _camposMedida;

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
                          return "El nombre debe tener al menos 3 caracteres";
                        }
                        if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(value)) {
                          return "Solo letras y espacios";
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
                                return "El teléfono es obligatorio";
                              }
                              if (!RegExp(r'^[0-9]{10,15}$').hasMatch(value)) {
                                return "Ingresa un teléfono válido (10-15 dígitos)";
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
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return null;
                              }
                              if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                                return "Ingresa un correo válido (ejemplo@dominio.com)";
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              /// UBICACIÓN EN TALLER
              _seccionCard(
                titulo: "Ubicación en Taller",
                icon: Icons.location_on_outlined,
                child: Column(
                  children: [
                    if (estantesDisponibles.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.shade200,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "No hay estantes disponibles. Todos los estantes están llenos.",
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
                          final remaining = estante.capacidad - estante.ocupados;
                          return DropdownMenuItem(
                            value: estante.id,
                            child: Text(
                              "${estante.id} (${estante.ocupados}/${estante.capacidad}) - $remaining espacios disponibles",
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xff102A43),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            estanteAsignado = value!;
                          });
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
                          child: Text("Vestido de Noche / Gala"),
                        ),
                        DropdownMenuItem(
                          value: "pantalon",
                          child: Text("Pantalón"),
                        ),
                        DropdownMenuItem(
                          value: "saco",
                          child: Text("Saco"),
                        ),
                        DropdownMenuItem(
                          value: "falda",
                          child: Text("Falda"),
                        ),
                        DropdownMenuItem(
                          value: "ajuste",
                          child: Text("Ajuste"),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          tipoPrenda = value!;
                          bustoController.clear();
                          cinturaController.clear();
                          caderaController.clear();
                          largoController.clear();
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    InkWell(
                      onTap: () {
                        setState(() {
                          _showMeasurements = !_showMeasurements;
                        });
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
                                  _showMeasurements ? "Ocultar Mediciones" : "Agregar Mediciones",
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

                    if (_showMeasurements)
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          children: [
                            if (camposMedida.length >= 2)
                              Row(
                                children: [
                                  Expanded(
                                    child: _campoMedidaCompacto(
                                      camposMedida[0]['label'],
                                      camposMedida[0]['controller'],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _campoMedidaCompacto(
                                      camposMedida[1]['label'],
                                      camposMedida[1]['controller'],
                                    ),
                                  ),
                                ],
                              ),
                            if (camposMedida.length >= 4)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _campoMedidaCompacto(
                                        camposMedida[2]['label'],
                                        camposMedida[2]['controller'],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _campoMedidaCompacto(
                                        camposMedida[3]['label'],
                                        camposMedida[3]['controller'],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (camposMedida.length == 3)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _campoMedidaCompacto(
                                        camposMedida[2]['label'],
                                        camposMedida[2]['controller'],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Container(),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descripcionController,
                      maxLines: 4,
                      decoration: _input(
                        "Descripción de la Modificación / Trabajo",
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xff102A43),
                      ),
                      minLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return null;
                        }
                        if (value.length < 10) {
                          return "La descripción debe tener al menos 10 caracteres";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: tallaController,
                      decoration: _input("Talla / Medidas Clave"),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xff102A43),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return null;
                        }
                        final tallasValidas = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'];
                        final tallaMayus = value.toUpperCase().trim();
                        if (!tallasValidas.contains(tallaMayus) && !RegExp(r'^[0-9]+$').hasMatch(value)) {
                          return "Ingresa una talla válida (XS, S, M, L, XL, XXL, XXXL o número)";
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              /// ACUERDO FINANCIERO Y ENTREGA
              _seccionCard(
                titulo: "Acuerdo Financiero y Entrega",
                icon: Icons.payments_outlined,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () {
                              DateTime mesActual = DateTime(
                                fechaEntrega.year,
                                fechaEntrega.month,
                                1,
                              );
                              DateTime fechaTemp = fechaEntrega;
                              
                              showDialog(
                                context: context,
                                barrierDismissible: true,
                                builder: (context) => StatefulBuilder(
                                  builder: (context, setStateDialog) {
                                    return Dialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Fecha seleccionada
                                            Container(
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              child: Text(
                                                ' ${_formatearFecha(fechaTemp)}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xff6D3EFF),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            
                                            // Calendario
                                            _calendarioPersonalizado(
                                              mesActual: mesActual,
                                              fechaSeleccionada: fechaTemp,
                                              onDateSelected: (date) {
                                                setStateDialog(() {
                                                  fechaTemp = date;
                                                });
                                              },
                                              onMesCambiado: (nuevoMes) {
                                                setStateDialog(() {
                                                  mesActual = nuevoMes;
                                                });
                                              },
                                            ),
                                            
                                            const SizedBox(height: 16),
                                            
                                            // Botones
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                              children: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text(
                                                    'Cancelar',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      fechaEntrega = fechaTemp;
                                                    });
                                                    Navigator.pop(context);
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          ' ${_formatearFecha(fechaEntrega)}',
                                                          style: const TextStyle(color: Colors.white),
                                                        ),
                                                        backgroundColor: const Color(0xff6D3EFF),
                                                        duration: const Duration(seconds: 2),
                                                      ),
                                                    );
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xff6D3EFF),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 32,
                                                      vertical: 12,
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Aceptar',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        color: const Color(0xff6D3EFF),
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
                                      color: const Color(0xff6D3EFF).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xff6D3EFF).withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          _formatearFecha(fechaEntrega),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xff6D3EFF),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_drop_down,
                                          color: const Color(0xff6D3EFF),
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
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
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color(0xff102A43),
                                    ),
                                    onChanged: (value) {
                                      total = double.tryParse(value) ?? 0;
                                      calcularSaldo();
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "El costo total es obligatorio";
                                      }
                                      final doubleVal = double.tryParse(value);
                                      if (doubleVal == null || doubleVal <= 0) {
                                        return "Ingresa un monto válido mayor a 0";
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
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
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color(0xff102A43),
                                    ),
                                    onChanged: (value) {
                                      anticipo = double.tryParse(value) ?? 0;
                                      calcularSaldo();
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "El anticipo es obligatorio";
                                      }
                                      final doubleVal = double.tryParse(value);
                                      if (doubleVal == null || doubleVal < 0) {
                                        return "Ingresa un monto válido";
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
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
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.grey.shade300,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                      child: const Text(
                        "Cancelar",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff64748B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff6D3EFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                      onPressed: _isLoading ? null : () async {
                        if (!_formKey.currentState!.validate()) return;
                        final fechaEntregaStr =
                            '${fechaEntrega.year}-'
                            '${fechaEntrega.month.toString().padLeft(2, '0')}-'
                            '${fechaEntrega.day.toString().padLeft(2, '0')}';

                        if (estanteAsignado == null || estanteAsignado!.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Selecciona un estante"),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        final selectedEstante = widget.estantes.firstWhere(
                              (e) => e.id == estanteAsignado,
                          orElse: () => Estante(
                            id: '',
                            nombre: '',
                            capacidad: 0,
                            ocupados: 0,
                            fechaCreacion: DateTime.now(),
                          ),
                        );

                        if (selectedEstante.ocupados >= selectedEstante.capacidad) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Este estante ya está lleno"),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

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
                          'title': '${tipoPrenda.toUpperCase()} - ${clienteNombreController.text.trim()}',
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

                        final exito = await _pedidoService.insertarPedido(nuevoPedido);

                        setState(() => _isLoading = false);

                        if (!context.mounted) return;

                        if (exito) {
                          await NotificationService().scheduleNotificacionPedido(
                            pedidoId: id,
                            titulo: '${tipoPrenda.toUpperCase()} - ${clienteNombreController.text.trim()}',
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
                              "Guardar Pedido",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
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
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 11,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0xff6D3EFF),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        isDense: true,
      ),
      style: const TextStyle(
        fontSize: 13,
        color: Color(0xff102A43),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return null;
        }
        final doubleVal = double.tryParse(value);
        if (doubleVal == null || doubleVal <= 0) {
          return "Ingresa un valor válido";
        }
        return null;
      },
    );
  }

  String _formatearFecha(DateTime fecha) {
    final meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    final diasSemana = [
      'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
    ];
    
    final diaSemana = diasSemana[fecha.weekday - 1];
    return '$diaSemana ${fecha.day} de ${meses[fecha.month - 1]}';
  }

  Widget _opcionPrioridad(String label, IconData icon) {
    final isSelected = prioridad == label;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            prioridad = label;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 4,
          ),
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
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
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