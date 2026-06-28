class TipoMedida {
  final String id;
  final String nombre;            
  final String? descripcion;
  final String? unidad;           
  final bool activo;
  final DateTime fechaCreacion;
  final DateTime? fechaActualizacion;

  TipoMedida({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.unidad,
    required this.activo,
    required this.fechaCreacion,
    this.fechaActualizacion,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'descripcion': descripcion,
    'unidad': unidad,
    'activo': activo,
    'fecha_creacion': fechaCreacion.toIso8601String(),
    'fecha_actualizacion': fechaActualizacion?.toIso8601String(),
  };

  factory TipoMedida.fromJson(Map<String, dynamic> json) => TipoMedida(
    id: json['id'],
    nombre: json['nombre'],
    descripcion: json['descripcion'],
    unidad: json['unidad'],
    activo: json['activo'],
    fechaCreacion: DateTime.parse(json['fecha_creacion']),
    fechaActualizacion: json['fecha_actualizacion'] != null 
        ? DateTime.parse(json['fecha_actualizacion']) 
        : null,
  );
}