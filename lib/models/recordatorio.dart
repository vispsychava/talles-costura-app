class Recordatorio {
  final String id;
  final String pedidoId;
  final String titulo;
  final String? descripcion;
  final DateTime fechaRecordatorio;
  final bool completado;
  final DateTime fechaCreacion;
  final DateTime? fechaActualizacion;

  Recordatorio({
    required this.id,
    required this.pedidoId,
    required this.titulo,
    this.descripcion,
    required this.fechaRecordatorio,
    required this.completado,
    required this.fechaCreacion,
    this.fechaActualizacion,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'pedido_id': pedidoId,
    'titulo': titulo,
    'descripcion': descripcion,
    'fecha_recordatorio': fechaRecordatorio.toIso8601String(),
    'completado': completado,
    'fecha_creacion': fechaCreacion.toIso8601String(),
    'fecha_actualizacion': fechaActualizacion?.toIso8601String(),
  };

  factory Recordatorio.fromJson(Map<String, dynamic> json) => Recordatorio(
    id: json['id'],
    pedidoId: json['pedido_id'],
    titulo: json['titulo'],
    descripcion: json['descripcion'],
    fechaRecordatorio: DateTime.parse(json['fecha_recordatorio']),
    completado: json['completado'],
    fechaCreacion: DateTime.parse(json['fecha_creacion']),
    fechaActualizacion: json['fecha_actualizacion'] != null 
        ? DateTime.parse(json['fecha_actualizacion']) 
        : null,
  );
}