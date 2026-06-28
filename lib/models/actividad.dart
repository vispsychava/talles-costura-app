class Actividad {
  final String id;
  final String usuarioId;
  final String tipo;             
  final String descripcion;
  final String? pedidoId;        
  final String? prendaId;         
  final DateTime fechaCreacion;

  Actividad({
    required this.id,
    required this.usuarioId,
    required this.tipo,
    required this.descripcion,
    this.pedidoId,
    this.prendaId,
    required this.fechaCreacion,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'usuario_id': usuarioId,
    'tipo': tipo,
    'descripcion': descripcion,
    'pedido_id': pedidoId,
    'prenda_id': prendaId,
    'fecha_creacion': fechaCreacion.toIso8601String(),
  };

  factory Actividad.fromJson(Map<String, dynamic> json) => Actividad(
    id: json['id'],
    usuarioId: json['usuario_id'],
    tipo: json['tipo'],
    descripcion: json['descripcion'],
    pedidoId: json['pedido_id'],
    prendaId: json['prenda_id'],
    fechaCreacion: DateTime.parse(json['fecha_creacion']),
  );
}