class Prenda {
  final String id;
  final String? pedidoId;         
  final String nombre;            
  final String? descripcion;
  final String? talla;
  final String? color;
  final String? material;
  final double? precio;
  final String? estado;           
  final String? estanteId;        
  final DateTime fechaCreacion;
  final DateTime? fechaActualizacion;

  Prenda({
    required this.id,
    this.pedidoId,
    required this.nombre,
    this.descripcion,
    this.talla,
    this.color,
    this.material,
    this.precio,
    this.estado,
    this.estanteId,
    required this.fechaCreacion,
    this.fechaActualizacion,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'pedido_id': pedidoId,
    'nombre': nombre,
    'descripcion': descripcion,
    'talla': talla,
    'color': color,
    'material': material,
    'precio': precio,
    'estado': estado,
    'estante_id': estanteId,
    'fecha_creacion': fechaCreacion.toIso8601String(),
    'fecha_actualizacion': fechaActualizacion?.toIso8601String(),
  };

  factory Prenda.fromJson(Map<String, dynamic> json) => Prenda(
    id: json['id'],
    pedidoId: json['pedido_id'],
    nombre: json['nombre'],
    descripcion: json['descripcion'],
    talla: json['talla'],
    color: json['color'],
    material: json['material'],
    precio: json['precio']?.toDouble(),
    estado: json['estado'],
    estanteId: json['estante_id'],
    fechaCreacion: DateTime.parse(json['fecha_creacion']),
    fechaActualizacion: json['fecha_actualizacion'] != null 
        ? DateTime.parse(json['fecha_actualizacion']) 
        : null,
  );
}