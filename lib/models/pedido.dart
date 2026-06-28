// lib/models/pedido.dart
import 'medida.dart';
import 'prenda.dart';

class Pedido {
  final String id;
  final String clienteNombre;
  final String clienteTelefono;
  final String? clienteEmail;
  final String estado;           
  final String? descripcion;
  final double? total;
  final DateTime fechaPedido;
  final DateTime? fechaEntrega;
  final DateTime? fechaActualizacion;
  final List<Medida>? medidas;   
  final List<Prenda>? prendas;   
  
  
  final String? titulo;         
  final String? estanteId;       
  final String? prioridad;       
  final String? tipoPrenda;      
  final String? talla;          
  final double? anticipo;        
  final double? saldo;           

  Pedido({
    required this.id,
    required this.clienteNombre,
    required this.clienteTelefono,
    this.clienteEmail,
    required this.estado,
    this.descripcion,
    this.total,
    required this.fechaPedido,
    this.fechaEntrega,
    this.fechaActualizacion,
    this.medidas,
    this.prendas,
    this.titulo,
    this.estanteId,
    this.prioridad,
    this.tipoPrenda,
    this.talla,
    this.anticipo,
    this.saldo,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'cliente_nombre': clienteNombre,
    'cliente_telefono': clienteTelefono,
    'cliente_email': clienteEmail,
    'estado': estado,
    'descripcion': descripcion,
    'total': total,
    'fecha_pedido': fechaPedido.toIso8601String(),
    'fecha_entrega': fechaEntrega?.toIso8601String(),
    'fecha_actualizacion': fechaActualizacion?.toIso8601String(),
    'titulo': titulo,
    'estante_id': estanteId,
    'prioridad': prioridad,
    'tipo_prenda': tipoPrenda,
    'talla': talla,
    'anticipo': anticipo,
    'saldo': saldo,
  };

  factory Pedido.fromJson(Map<String, dynamic> json) => Pedido(
    id: json['id'] ?? json['codigo_pedido'] ?? '',
    clienteNombre: json['cliente_nombre'] ?? json['nombre_cliente'] ?? '',
    clienteTelefono: json['cliente_telefono'] ?? json['telefono'] ?? '',
    clienteEmail: json['cliente_email'] ?? json['email'],
    estado: json['estado'] ?? json['estado_pedido'] ?? 'Sin empezar',
    descripcion: json['descripcion'],
    total: (json['total'] ?? json['precio_total'])?.toDouble(),
    fechaPedido: json['fecha_pedido'] != null 
        ? DateTime.parse(json['fecha_pedido'])
        : json['fecha_registro'] != null
            ? DateTime.parse(json['fecha_registro'])
            : DateTime.now(),
    fechaEntrega: json['fecha_entrega'] != null 
        ? DateTime.parse(json['fecha_entrega']) 
        : null,
    fechaActualizacion: json['fecha_actualizacion'] != null 
        ? DateTime.parse(json['fecha_actualizacion']) 
        : null,
  
    titulo: json['titulo'] ?? json['codigo_pedido'] ?? 'Pedido',
    estanteId: json['estante_id'] ?? json['id_estante']?.toString() ?? json['shelfAssignment'],
    prioridad: json['prioridad'] ?? 'Media',
    tipoPrenda: json['tipo_prenda'] ?? json['garmentType'] ?? 'vestido',
    talla: json['talla'] ?? json['size'] ?? 'M',
    anticipo: (json['anticipo'] ?? json['advancePaid'])?.toDouble() ?? 0.0,
    saldo: (json['saldo'] ?? json['balanceDue'])?.toDouble() ?? 0.0,
  );

  Pedido copyWith({
    String? id,
    String? clienteNombre,
    String? clienteTelefono,
    String? clienteEmail,
    String? estado,
    String? descripcion,
    double? total,
    DateTime? fechaPedido,
    DateTime? fechaEntrega,
    DateTime? fechaActualizacion,
    List<Medida>? medidas,
    List<Prenda>? prendas,
    String? titulo,
    String? estanteId,
    String? prioridad,
    String? tipoPrenda,
    String? talla,
    double? anticipo,
    double? saldo,
  }) {
    return Pedido(
      id: id ?? this.id,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      clienteTelefono: clienteTelefono ?? this.clienteTelefono,
      clienteEmail: clienteEmail ?? this.clienteEmail,
      estado: estado ?? this.estado,
      descripcion: descripcion ?? this.descripcion,
      total: total ?? this.total,
      fechaPedido: fechaPedido ?? this.fechaPedido,
      fechaEntrega: fechaEntrega ?? this.fechaEntrega,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      medidas: medidas ?? this.medidas,
      prendas: prendas ?? this.prendas,
      titulo: titulo ?? this.titulo,
      estanteId: estanteId ?? this.estanteId,
      prioridad: prioridad ?? this.prioridad,
      tipoPrenda: tipoPrenda ?? this.tipoPrenda,
      talla: talla ?? this.talla,
      anticipo: anticipo ?? this.anticipo,
      saldo: saldo ?? this.saldo,
    );
  }

  bool get estaPagado => (saldo ?? 0) <= 0;

  String get estadoTexto {
    switch (estado) {
      case 'Sin empezar':
        return 'Sin empezar';
      case 'En proceso':
        return 'En proceso';
      case 'Terminado':
        return 'Terminado';
      case 'Entregado':
        return 'Entregado';
      case 'Atrasado':
        return 'Atrasado';
      default:
        return estado;
    }
  }

  String get estadoNombre {
    switch (estado) {
      case 'Sin empezar':
        return 'Sin empezar';
      case 'En proceso':
        return 'En proceso';
      case 'Terminado':
        return 'Terminado';
      case 'Entregado':
        return 'Entregado';
      case 'Atrasado':
        return 'Atrasado';
      default:
        return estado;
    }
  }

  
  String get estadoIcono {
    switch (estado) {
      case 'Sin empezar':
        return '📋';
      case 'En proceso':
        return '⏳';
      case 'Terminado':
        return '✅';
      case 'Entregado':
        return '📦';
      case 'Atrasado':
        return '⚠️';
      default:
        return '📋';
    }
  }

  
  String get estadoColorHex {
    switch (estado) {
      case 'Sin empezar':
        return '#9E9E9E'; 
      case 'En proceso':
        return '#8B5CF6'; 
      case 'Terminado':
        return '#10B981'; 
      case 'Entregado':
        return '#3B82F6'; 
      case 'Atrasado':
        return '#EF4444'; 
      default:
        return '#9E9E9E';
    }
  }
}