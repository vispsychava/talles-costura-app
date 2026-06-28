import 'package:flutter/material.dart';
import '../models/estante.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AgregarEstanteScreen extends StatefulWidget {
  final Function(Estante) onAgregarEstante;

  const AgregarEstanteScreen({
    super.key,
    required this.onAgregarEstante,
  });

  @override
  State<AgregarEstanteScreen> createState() => _AgregarEstanteScreenState();
}

class _AgregarEstanteScreenState extends State<AgregarEstanteScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Agregar Estante",
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
              /// INFORMACIÓN DEL ESTANTE
              Container(
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
                          child: const Icon(
                            Icons.shelves,
                            color: Color(0xff6D3EFF),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Información del Estante",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff102A43),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    /// Código del Estante (UNICO)
                    TextFormField(
                      controller: _codigoController,
                      decoration: InputDecoration(
                        labelText: "Código del Estante",
                        hintText: "Ej: A1, B2, C3",
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
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xff102A43),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Ingresa un código para el estante";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    /// Descripción del Estante
                    TextFormField(
                      controller: _descripcionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: "Descripción",
                        hintText: "Ej: Estante Principal, Estante Norte",
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
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xff102A43),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Ingresa una descripción para el estante";
                        }
                        return null;
                      },
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
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;

                        final codigo = _codigoController.text.toUpperCase().trim();
                        final descripcion = _descripcionController.text.trim();

                        print('Intentando guardar estante: codigo=$codigo, descripcion=$descripcion');

                        try {
                          // Guardar en Supabase - SOLO con los campos que tiene la tabla
                          final response = await Supabase.instance.client.from('estantes').insert({
                            'codigo': codigo,
                            'descripcion': descripcion,
                          }).select();

                          print('Estante guardado en Supabase: $response');

                          
                          final nuevoEstante = Estante(
                            id: codigo,  
                            nombre: descripcion,
                            ubicacion: null,
                            descripcion: descripcion,
                            capacidad: 10,
                            ocupados: 0,
                            fechaCreacion: DateTime.now(),
                            fechaActualizacion: null,
                          );

                          widget.onAgregarEstante(nuevoEstante);
                          if (!context.mounted) return;
                          Navigator.pop(context, true);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(' Estante creado correctamente'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          print(' Error en Supabase: $e');
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(' Error: ${e.toString().replaceFirst('Exception: ', '')}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text(
                        "Guardar Estante",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}