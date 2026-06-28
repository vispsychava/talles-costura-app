class Medida {
  final String id;
  final String? pedidoId;        
  final String clienteNombre;     
  final String tipoMedida;        
  final double valor;             
  final String? observaciones;    
  final DateTime fechaCreacion;
  final DateTime? fechaActualizacion;

  Medida({
    required this.id,
    this.pedidoId,
    required this.clienteNombre,
    required this.tipoMedida,
    required this.valor,
    this.observaciones,
    required this.fechaCreacion,
    this.fechaActualizacion,
  });

  // Para enviar a Supabase
  Map<String, dynamic> toJson() => {
    'id': id,
    'pedido_id': pedidoId,
    'cliente_nombre': clienteNombre,
    'tipo_medida': tipoMedida,
    'valor': valor,
    'observaciones': observaciones,
    'fecha_creacion': fechaCreacion.toIso8601String(),
    'fecha_actualizacion': fechaActualizacion?.toIso8601String(),
  };

  // Para recibir de Supabase
  factory Medida.fromJson(Map<String, dynamic> json) => Medida(
    id: json['id'],
    pedidoId: json['pedido_id'],
    clienteNombre: json['cliente_nombre'],
    tipoMedida: json['tipo_medida'],
    valor: json['valor'].toDouble(),
    observaciones: json['observaciones'],
    fechaCreacion: DateTime.parse(json['fecha_creacion']),
    fechaActualizacion: json['fecha_actualizacion'] != null 
        ? DateTime.parse(json['fecha_actualizacion']) 
        : null,
  );
}