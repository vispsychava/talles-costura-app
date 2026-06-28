class NotaProgreso {
  final String id;
  final String pedidoId;
  final String contenido;
  final String? usuarioId;
  final DateTime fechaCreacion;
  final DateTime? fechaActualizacion;

  NotaProgreso({
    required this.id,
    required this.pedidoId,
    required this.contenido,
    this.usuarioId,
    required this.fechaCreacion,
    this.fechaActualizacion,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'pedido_id': pedidoId,
    'contenido': contenido,
    'usuario_id': usuarioId,
    'fecha_creacion': fechaCreacion.toIso8601String(),
    'fecha_actualizacion': fechaActualizacion?.toIso8601String(),
  };

  factory NotaProgreso.fromJson(Map<String, dynamic> json) => NotaProgreso(
    id: json['id'],
    pedidoId: json['pedido_id'],
    contenido: json['contenido'],
    usuarioId: json['usuario_id'],
    fechaCreacion: DateTime.parse(json['fecha_creacion']),
    fechaActualizacion: json['fecha_actualizacion'] != null 
        ? DateTime.parse(json['fecha_actualizacion']) 
        : null,
  );
}