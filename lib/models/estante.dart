// lib/models/estante.dart
class Estante {
  final String id;          
  final String nombre;
  final String? ubicacion;
  final String? descripcion;
  final int capacidad;
  final int ocupados;
  final DateTime fechaCreacion;
  final DateTime? fechaActualizacion;

  Estante({
    required this.id,
    required this.nombre,
    this.ubicacion,
    this.descripcion,
    required this.capacidad,
    required this.ocupados,
    required this.fechaCreacion,
    this.fechaActualizacion,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'ubicacion': ubicacion,
    'descripcion': descripcion,
    'capacidad': capacidad,
    'ocupados': ocupados,
    'fecha_creacion': fechaCreacion.toIso8601String(),
    'fecha_actualizacion': fechaActualizacion?.toIso8601String(),
  };

  factory Estante.fromJson(Map<String, dynamic> json) => Estante(
    
    id: json['codigo']?.toString() ?? json['id_estante']?.toString() ?? '',
    nombre: json['descripcion'] ?? 'Estante ${json['codigo'] ?? ''}',
    ubicacion: json['ubicacion'] ?? '',
    descripcion: json['descripcion'] ?? '',
    capacidad: json['capacidad'] ?? 10,
    ocupados: json['ocupados'] ?? 0,
    fechaCreacion: json['fecha_creacion'] != null 
        ? DateTime.parse(json['fecha_creacion']) 
        : DateTime.now(),
    fechaActualizacion: json['fecha_actualizacion'] != null 
        ? DateTime.parse(json['fecha_actualizacion']) 
        : null,
  );
}