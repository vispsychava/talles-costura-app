// lib/services/pedido_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pedido.dart';
import '../models/medida.dart';

class PedidoService {
  final supabase = Supabase.instance.client;

  /// Crear un nuevo pedido
  Future<Map<String, dynamic>> crearPedido(Pedido pedido) async {
    try {
      // Obtener el ID del estante por su código
      final estanteResponse = await supabase
          .from('estantes')
          .select('id_estante')
          .eq('codigo_estante', pedido.estanteId ?? '')
          .maybeSingle();

      if (estanteResponse == null) {
        throw Exception('Estante no encontrado: ${pedido.estanteId}');
      }

      final idEstante = estanteResponse['id_estante'];

      // Obtener el ID de la prenda por su nombre
      final prendaResponse = await supabase
          .from('prendas')
          .select('id_prenda')
          .eq('nombre', pedido.tipoPrenda ?? '')
          .maybeSingle();

      int? idPrenda;
      if (prendaResponse == null) {
        // Si no existe, crear la prenda
        final newPrenda = await supabase
            .from('prendas')
            .insert({
              'nombre': pedido.tipoPrenda ?? 'General',
              'descripcion': pedido.descripcion ?? '',
            })
            .select()
            .single();
        idPrenda = newPrenda['id_prenda'];
      } else {
        idPrenda = prendaResponse['id_prenda'];
      }

      // Crear el mapa para insertar
      final data = {
        'id_estante': idEstante,
        'id_prenda': idPrenda,
        'codigo_pedido': pedido.id,
        'nombre_cliente': pedido.clienteNombre,
        'telefono': pedido.clienteTelefono,
        'email': pedido.clienteEmail ?? '',
        'descripcion': pedido.descripcion ?? '',
        'precio_total': pedido.total ?? 0.0,
        'anticipo': pedido.anticipo ?? 0.0,
        'saldo': pedido.saldo ?? 0.0,
        'estado_pago': (pedido.saldo ?? 0) == 0 ? 'Pagado' : 'Pendiente',
        'estado_pedido': pedido.estado,
        'fecha_entrega': pedido.fechaEntrega?.toIso8601String() ?? '',
        'prioridad': pedido.prioridad ?? 'Media',
        'tipo_prenda': pedido.tipoPrenda ?? 'vestido',
        'talla': pedido.talla ?? 'M',
      };

      final response = await supabase
          .from('pedidos')
          .insert(data)
          .select()
          .single();

      return response;
    } catch (e) {
      print('Error al crear pedido: $e');
      rethrow;
    }
  }

  /// Obtener todos los pedidos
  Future<List<Pedido>> obtenerPedidos() async {
    try {
      final response = await supabase
          .from('pedidos')
          .select('''
            *,
            estantes(id_estante, codigo_estante, capacidad),
            prendas(id_prenda, nombre, descripcion),
            medidas(*)
          ''');

      List<Pedido> pedidos = [];
      for (var json in response) {
        try {
          final pedido = _mapToPedido(json);
          pedidos.add(pedido);
        } catch (e) {
          print('Error al mapear pedido: $e');
        }
      }
      return pedidos;
    } catch (e) {
      print('Error al obtener pedidos: $e');
      return [];
    }
  }

  /// Obtener un pedido por ID
  Future<Pedido?> obtenerPedidoPorId(String id) async {
    try {
      final response = await supabase
          .from('pedidos')
          .select('''
            *,
            estantes(id_estante, codigo_estante, capacidad),
            prendas(id_prenda, nombre, descripcion),
            medidas(*)
          ''')
          .eq('codigo_pedido', id)
          .maybeSingle();

      if (response == null) return null;
      return _mapToPedido(response);
    } catch (e) {
      print('Error al obtener pedido por ID: $e');
      return null;
    }
  }

  /// Actualizar un pedido
  Future<bool> actualizarPedido(Pedido pedido) async {
    try {
      final data = {
        'nombre_cliente': pedido.clienteNombre,
        'telefono': pedido.clienteTelefono,
        'email': pedido.clienteEmail ?? '',
        'descripcion': pedido.descripcion ?? '',
        'precio_total': pedido.total ?? 0.0,
        'anticipo': pedido.anticipo ?? 0.0,
        'saldo': pedido.saldo ?? 0.0,
        'estado_pago': (pedido.saldo ?? 0) == 0 ? 'Pagado' : 'Pendiente',
        'estado_pedido': pedido.estado,
        'fecha_entrega': pedido.fechaEntrega?.toIso8601String() ?? '',
        'prioridad': pedido.prioridad ?? 'Media',
        'tipo_prenda': pedido.tipoPrenda ?? 'vestido',
        'talla': pedido.talla ?? 'M',
        'fecha_actualizacion': DateTime.now().toIso8601String(),
      };

      await supabase
          .from('pedidos')
          .update(data)
          .eq('codigo_pedido', pedido.id);

      return true;
    } catch (e) {
      print('Error al actualizar pedido: $e');
      return false;
    }
  }

  ///  Actualizar estado de un pedido
  Future<bool> actualizarEstadoPedido(String pedidoId, String nuevoEstado) async {
    try {
      await supabase
          .from('pedidos')
          .update({
            'estado_pedido': nuevoEstado,
            'fecha_actualizacion': DateTime.now().toIso8601String(),
          })
          .eq('codigo_pedido', pedidoId);

      return true;
    } catch (e) {
      print('Error al actualizar estado: $e');
      return false;
    }
  }

  ///  Actualizar estado de pago
  Future<bool> actualizarEstadoPago(String pedidoId, double nuevoSaldo) async {
    try {
      final estadoPago = nuevoSaldo == 0 ? 'Pagado' : 'Pendiente';
      await supabase
          .from('pedidos')
          .update({
            'saldo': nuevoSaldo,
            'estado_pago': estadoPago,
            'fecha_actualizacion': DateTime.now().toIso8601String(),
          })
          .eq('codigo_pedido', pedidoId);

      return true;
    } catch (e) {
      print('Error al actualizar pago: $e');
      return false;
    }
  }

  ///  Registrar un pago
  Future<bool> registrarPago(String pedidoId, double monto) async {
    try {
      // Obtener el pedido actual
      final pedidoActual = await obtenerPedidoPorId(pedidoId);
      if (pedidoActual == null) return false;

      final nuevoSaldo = ((pedidoActual.saldo ?? 0) - monto).clamp(0.0, double.infinity);
      final estadoPago = nuevoSaldo == 0 ? 'Pagado' : 'Pendiente';

      await supabase
          .from('pedidos')
          .update({
            'saldo': nuevoSaldo,
            'estado_pago': estadoPago,
            'fecha_actualizacion': DateTime.now().toIso8601String(),
          })
          .eq('codigo_pedido', pedidoId);

      return true;
    } catch (e) {
      print('Error al registrar pago: $e');
      return false;
    }
  }

  /// Eliminar un pedido
  Future<bool> eliminarPedido(String pedidoId) async {
    try {
      await supabase
          .from('pedidos')
          .delete()
          .eq('codigo_pedido', pedidoId);

      return true;
    } catch (e) {
      print('Error al eliminar pedido: $e');
      return false;
    }
  }

  /// Obtener pedidos por estado
  Future<List<Pedido>> obtenerPedidosPorEstado(String estado) async {
    try {
      final response = await supabase
          .from('pedidos')
          .select('''
            *,
            estantes(id_estante, codigo_estante, capacidad),
            prendas(id_prenda, nombre, descripcion)
          ''')
          .eq('estado_pedido', estado)
          .order('fecha_creacion', ascending: false);

      List<Pedido> pedidos = [];
      for (var json in response) {
        try {
          final pedido = _mapToPedido(json);
          pedidos.add(pedido);
        } catch (e) {
          print('Error al mapear pedido: $e');
        }
      }
      return pedidos;
    } catch (e) {
      print('Error al obtener pedidos por estado: $e');
      return [];
    }
  }

  /// Obtener pedidos por cliente
  Future<List<Pedido>> obtenerPedidosPorCliente(String clienteNombre) async {
    try {
      final response = await supabase
          .from('pedidos')
          .select('''
            *,
            estantes(id_estante, codigo_estante, capacidad),
            prendas(id_prenda, nombre, descripcion)
          ''')
          .ilike('nombre_cliente', '%$clienteNombre%')
          .order('fecha_creacion', ascending: false);

      List<Pedido> pedidos = [];
      for (var json in response) {
        try {
          final pedido = _mapToPedido(json);
          pedidos.add(pedido);
        } catch (e) {
          print('Error al mapear pedido: $e');
        }
      }
      return pedidos;
    } catch (e) {
      print('Error al obtener pedidos por cliente: $e');
      return [];
    }
  }

  /// Mapear JSON a Pedido
  Pedido _mapToPedido(Map<String, dynamic> json) {
    // Obtener el código del estante
    String codigoEstante = '';
    if (json['estantes'] != null) {
      codigoEstante = json['estantes']['codigo_estante'] ?? '';
    }

    // Obtener el nombre de la prenda
    String prendaNombre = '';
    if (json['prendas'] != null) {
      prendaNombre = json['prendas']['nombre'] ?? '';
    }

    // Procesar medidas si existen
    List<Medida> medidas = [];
    if (json['medidas'] != null && json['medidas'] is List) {
      medidas = (json['medidas'] as List).map((m) => Medida(
        id: m['id_medida']?.toString() ?? '',
        pedidoId: json['codigo_pedido'] ?? '',
        clienteNombre: json['nombre_cliente'] ?? '',
        tipoMedida: m['tipo_medida'] ?? '',
        valor: (m['valor'] as num?)?.toDouble() ?? 0.0,
        observaciones: m['observaciones'] ?? '',
        fechaCreacion: m['fecha_creacion'] != null 
            ? DateTime.parse(m['fecha_creacion']) 
            : DateTime.now(),
        fechaActualizacion: m['fecha_actualizacion'] != null 
            ? DateTime.parse(m['fecha_actualizacion']) 
            : null,
      )).toList();
    }

    // Parsear fecha de entrega
    DateTime? fechaEntrega;
    if (json['fecha_entrega'] != null && json['fecha_entrega'].isNotEmpty) {
      try {
        fechaEntrega = DateTime.parse(json['fecha_entrega']);
      } catch (e) {
        // Si falla el parseo, intentar con formato dd/MM/yyyy
        try {
          final parts = json['fecha_entrega'].split('/');
          if (parts.length == 3) {
            fechaEntrega = DateTime(
              int.parse(parts[2]),
              int.parse(parts[1]),
              int.parse(parts[0]),
            );
          }
        } catch (e2) {
          print('Error al parsear fecha: $e2');
        }
      }
    }

    return Pedido(
      id: json['codigo_pedido'] ?? '',
      clienteNombre: json['nombre_cliente'] ?? '',
      clienteTelefono: json['telefono'] ?? '',
      clienteEmail: json['email'] ?? '',
      estado: json['estado_pedido'] ?? 'Sin empezar',
      descripcion: json['descripcion'] ?? '',
      total: (json['precio_total'] as num?)?.toDouble() ?? 0.0,
      fechaPedido: json['fecha_creacion'] != null 
          ? DateTime.parse(json['fecha_creacion']) 
          : DateTime.now(),
      fechaEntrega: fechaEntrega,
      fechaActualizacion: json['fecha_actualizacion'] != null 
          ? DateTime.parse(json['fecha_actualizacion']) 
          : null,
      medidas: medidas,
      titulo: prendaNombre.isNotEmpty ? '$prendaNombre - ${json['nombre_cliente']}' : 'Pedido',
      estanteId: codigoEstante.isNotEmpty ? codigoEstante : null,
      prioridad: json['prioridad'] ?? 'Media',
      tipoPrenda: json['tipo_prenda'] ?? prendaNombre,
      talla: json['talla'] ?? 'M',
      anticipo: (json['anticipo'] as num?)?.toDouble() ?? 0.0,
      saldo: (json['saldo'] as num?)?.toDouble() ?? 0.0,
    );
  }
}