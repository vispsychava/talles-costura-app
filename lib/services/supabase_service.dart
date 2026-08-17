// lib/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pedido.dart';
import '../models/recordatorio.dart';
import '../models/estante.dart';
import '../models/medida.dart';
import '../models/prenda.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// ============================================================
  /// PEDIDOS (tabla: pedidos)
  /// ============================================================

  /// Obtener todos los pedidos
  Future<List<Pedido>> obtenerPedidos() async {
    try {
      final response = await _supabase
    .from('pedidos')
    .select('''
      *,
      estantes:estantes(codigo, descripcion),
      medidas:medidas_pedido(id_medida_pedido, valor, tipo_medidas(nombre)),
      prendas:prendas(*)
    ''')
    .order('fecha_registro', ascending: false);

      final List<dynamic> data = response;

      return data.map((json) {
        // Procesar medidas si existen
        List<Medida> medidas = [];
        if (json['medidas'] != null && json['medidas'] is List) {
  medidas = (json['medidas'] as List).map((m) => Medida(
    id: m['id_medida_pedido']?.toString() ?? '',
    pedidoId: json['id_pedido']?.toString() ?? '',
    clienteNombre: json['nombre_cliente'] ?? '',
    tipoMedida: m['tipo_medidas']?['nombre'] ?? '',
    valor: (m['valor'] as num?)?.toDouble() ?? 0.0,
    observaciones: '',
    fechaCreacion: DateTime.now(),
    fechaActualizacion: null,
  )).toList();
}

        // Procesar prendas si existen
        List<Prenda> prendas = [];
        if (json['prendas'] != null && json['prendas'] is List) {
          prendas = (json['prendas'] as List).map((p) => Prenda(
            id: p['id_prenda']?.toString() ?? '',
            pedidoId: json['id_pedido']?.toString() ?? '',
            nombre: p['nombre'] ?? '',
            descripcion: p['descripcion'] ?? '',
            talla: p['talla'] ?? '',
            color: p['color'] ?? '',
            material: p['material'] ?? '',
            precio: (p['precio'] as num?)?.toDouble() ?? 0.0,
            estado: p['estado'] ?? 'Pendiente',
            estanteId: p['id_estante']?.toString(),
            fechaCreacion: p['fecha_creacion'] != null 
                ? DateTime.parse(p['fecha_creacion']) 
                : DateTime.now(),
            fechaActualizacion: p['fecha_actualizacion'] != null 
                ? DateTime.parse(p['fecha_actualizacion']) 
                : null,
          )).toList();
        }

        // ✅ Obtener el código del estante (en lugar del ID numérico)
        String codigoEstante = '';
        if (json['estantes'] != null && json['estantes']['codigo'] != null) {
          codigoEstante = json['estantes']['codigo'].toString();
        }

        return Pedido(
          id: json['codigo_pedido']?.toString() ?? json['id_pedido']?.toString() ?? '0',
          clienteNombre: json['nombre_cliente'] ?? '',
          clienteTelefono: json['telefono'] ?? '',
          clienteEmail: json['email'] ?? '',
          estado: json['estado_pedido'] ?? 'Pendiente',
          descripcion: json['descripcion'] ?? '',
          total: (json['precio_total'] as num?)?.toDouble() ?? 0.0,
          fechaPedido: json['fecha_registro'] != null 
              ? DateTime.parse(json['fecha_registro']) 
              : DateTime.now(),
          fechaEntrega: json['fecha_entrega'] != null 
              ? DateTime.parse(json['fecha_entrega']) 
              : null,
          fechaActualizacion: json['fecha_actualizacion'] != null 
              ? DateTime.parse(json['fecha_actualizacion']) 
              : null,
          medidas: medidas,
          prendas: prendas,
          titulo: '${json['tipo_prenda'] ?? 'Pedido'} - ${json['nombre_cliente'] ?? ''}',
          estanteId: codigoEstante, // ✅ Usar el código del estante (ej: "E04")
          prioridad: json['prioridad'] ?? 'Media',
          tipoPrenda: json['tipo_prenda'] ?? 'vestido',
          talla: json['talla'] ?? 'M',
          anticipo: (json['anticipo'] as num?)?.toDouble() ?? 0.0,
          saldo: (json['saldo'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
    } catch (e) {
      print('Error en obtenerPedidos: $e');
      return [];
    }
  }

  /// Insertar un nuevo pedido
Future<int?> insertarPedido(Map<String, dynamic> pedidoData) async {
  try {
    final codigoEstante = pedidoData['shelfAssignment']?.toString() ?? '';
    if (codigoEstante.isEmpty) {
      print('❌ Código de estante vacío');
      return null;
    }

    final estanteResponse = await _supabase
        .from('estantes')
        .select('id_estante')
        .eq('codigo', codigoEstante)
        .maybeSingle();

    if (estanteResponse == null) {
      print('❌ Estante no encontrado con código: $codigoEstante');
      return null;
    }

    final int idEstante = estanteResponse['id_estante'];

    final response = await _supabase.from('pedidos').insert({
      'codigo_pedido': pedidoData['id'] ?? 'PED-${DateTime.now().millisecondsSinceEpoch}',
      'nombre_cliente': pedidoData['clientName'] ?? '',
      'telefono': pedidoData['clientPhone'] ?? '',
      'email': pedidoData['clientEmail'] ?? '',
      'descripcion': pedidoData['description'] ?? '',
      'precio_total': pedidoData['totalAmount'] ?? 0.0,
      'anticipo': pedidoData['advancePaid'] ?? 0.0,
      'saldo': pedidoData['balanceDue'] ?? 0.0,
      'estado_pedido': pedidoData['status'] ?? 'Sin empezar',
      'fecha_registro': pedidoData['statusDate'] ?? DateTime.now().toIso8601String(),
      'fecha_entrega': pedidoData['expectedDeliveryDate'] ??
          DateTime.now().add(const Duration(days: 7)).toIso8601String().substring(0, 10),
      'id_estante': idEstante,
      'prioridad': pedidoData['priority'] ?? 'Media',
      'tipo_prenda': pedidoData['garmentType'] ?? 'vestido',
      'talla': pedidoData['size'] ?? 'M',
    }).select('id_pedido').single();

    final int idPedido = response['id_pedido'];
    await _actualizarOcupadosEstante(idEstante);
    print('✅ Pedido insertado correctamente: id_pedido=$idPedido');
    return idPedido;
  } catch (e) {
    print('❌ Error en insertarPedido: $e');
    print('📦 Datos del pedido: $pedidoData');
    return null;
  }
}
  /// Recalcula y actualiza el campo ocupados de un estante
  Future<void> _actualizarOcupadosEstante(int idEstante) async {
    try {
      final pedidosActivos = await _supabase
          .from('pedidos')
          .select('id_pedido')
          .eq('id_estante', idEstante)
          .neq('estado_pedido', 'Entregado');

      final int count = (pedidosActivos as List).length;

      await _supabase
          .from('estantes')
          .update({'ocupados': count})
          .eq('id_estante', idEstante);

      print('✅ Estante $idEstante actualizado: $count ocupados');
    } catch (e) {
      print('❌ Error al actualizar ocupados: $e');
    }
  }

  /// Recalcula ocupados de TODOS los estantes
  Future<void> recalcularTodosLosEstantes() async {
    try {
      final estantes = await _supabase
          .from('estantes')
          .select('id_estante');

      for (final estante in estantes as List) {
        await _actualizarOcupadosEstante(estante['id_estante']);
      }
      print('✅ Todos los estantes recalculados');
    } catch (e) {
      print('❌ Error al recalcular estantes: $e');
    }
  }

  /// Obtener todos los estantes
  Future<List<Estante>> obtenerEstantes() async {
    try {
      final response = await _supabase
          .from('estantes')
          .select('*')
          .order('codigo', ascending: true);

      final List<dynamic> data = response;

      return data.map((json) {
        return Estante(
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
      }).toList();
    } catch (e) {
      print('Error en obtenerEstantes: $e');
      return [];
    }
  }

  /// ============================================================
  /// RECORDATORIOS (tabla: recordatorios)
  /// ============================================================

  /// Obtener todos los recordatorios
  Future<List<Recordatorio>> obtenerRecordatorios() async {
    try {
      final response = await _supabase
          .from('recordatorios')
          .select('*')
          .order('fecha_recordatorio', ascending: true);

      final List<dynamic> data = response;

        return data.map((json) => Recordatorio(
          id: json['id_recordatorio']?.toString() ?? '',
          pedidoId: json['pedido_id'] != null ? int.tryParse(json['pedido_id'].toString()) : null,
          clienteNombre: json['cliente_nombre'],
          titulo: json['titulo'] ?? '',
          descripcion: json['descripcion'] ?? '',
          fechaRecordatorio: json['fecha_recordatorio'] != null
              ? DateTime.parse(json['fecha_recordatorio'])
              : DateTime.now(),
          completado: json['completado'] ?? false,
          fechaCreacion: json['fecha_creacion'] != null
              ? DateTime.parse(json['fecha_creacion'])
              : DateTime.now(),
          fechaActualizacion: json['fecha_actualizacion'] != null
              ? DateTime.parse(json['fecha_actualizacion'])
              : null,
        )).toList();
    } catch (e) {
      print('Error en obtenerRecordatorios: $e');
      return [];
    }
  }


  /// Insertar un nuevo recordatorio
Future<bool> insertarRecordatorio(Recordatorio recordatorio) async {
  try {
    await _supabase.from('recordatorios').insert({
      'pedido_id': recordatorio.pedidoId,           // null si es manual
      'cliente_nombre': recordatorio.clienteNombre, // texto libre
      'titulo': recordatorio.titulo,
      'descripcion': recordatorio.descripcion,
      'fecha_recordatorio': recordatorio.fechaRecordatorio.toIso8601String(),
      'completado': recordatorio.completado,
      'fecha_creacion': recordatorio.fechaCreacion.toIso8601String(),
    });
    return true;
  } catch (e) {
    print('Error en insertarRecordatorio: $e');
    return false;
  }
}

/// Marcar un recordatorio como completado
Future<bool> completarRecordatorio(String idRecordatorio) async {
  try {
    await _supabase
        .from('recordatorios')
        .update({
          'completado': true,
          'fecha_actualizacion': DateTime.now().toIso8601String(),
        })
        .eq('id_recordatorio', idRecordatorio);
    return true;
  } catch (e) {
    print('Error en completarRecordatorio: $e');
    return false;
  }
}

  /// ============================================================
  /// MEDIDAS (tabla: medidas_pedido)
  /// ============================================================

  /// Obtener medidas de un pedido
  /// Obtener medidas de un pedido (por id_pedido numérico)
Future<List<Medida>> obtenerMedidasPorPedido(String pedidoId) async {
  try {
    final idPedidoInt = int.tryParse(pedidoId) ?? 0;

    final response = await _supabase
        .from('medidas_pedido')
        .select('id_medida_pedido, valor, tipo_medidas(nombre)')
        .eq('id_pedido', idPedidoInt);

    final List<dynamic> data = response;

    return data.map((json) => Medida(
      id: json['id_medida_pedido']?.toString() ?? '',
      pedidoId: pedidoId,
      clienteNombre: '',
      tipoMedida: json['tipo_medidas']?['nombre'] ?? '',
      valor: (json['valor'] as num?)?.toDouble() ?? 0.0,
      observaciones: '',
      fechaCreacion: DateTime.now(),
      fechaActualizacion: null,
    )).toList();
  } catch (e) {
    print('Error en obtenerMedidasPorPedido: $e');
    return [];
  }
}

  /// Insertar una nueva medida
Future<bool> insertarMedidasPedido(int idPedido, List<Map<String, dynamic>> medidas) async {
  try {
    if (medidas.isEmpty) return true;

    final rows = medidas.map((m) => {
      'id_pedido': idPedido,
      'id_tipo_medida': m['idTipoMedida'],
      'valor': m['valor'],
    }).toList();

    await _supabase.from('medidas_pedido').insert(rows);
    print('✅ ${rows.length} medida(s) insertadas para pedido $idPedido');
    return true;
  } catch (e) {
    print('❌ Error en insertarMedidasPedido: $e');
    return false;
  }
}

  /// Obtener medidas por tipo de prenda
Future<List<Map<String, dynamic>>> obtenerMedidasPorTipoPrenda(int idPrenda) async {
  try {
    final response = await _supabase
        .from('prenda_medidas')
        .select('id_tipo_medida, tipo_medidas(nombre)')
        .eq('id_prenda', idPrenda)
        .order('orden', ascending: true);

    return (response as List)
        .map((item) => {
              'id_tipo_medida': item['id_tipo_medida'] as int,
              'nombre': item['tipo_medidas']['nombre'].toString(),
            })
        .toList();
  } catch (e) {
    print('Error en obtenerMedidasPorTipoPrenda: $e');
    return [];
  }
}

/// Mapa de tipo de prenda a id_prenda
static const Map<String, int> idPrendaPorTipo = {
  'camisa': 1,
  'pantalon': 2,
  'vestido': 3,
  'blusa': 4,
  'falda': 5,
  'saco': 3,
  'ajuste': 3,
};  
}