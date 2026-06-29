// lib/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pedido.dart';
import '../models/recordatorio.dart';
import '../models/estante.dart';
import '../models/medida.dart';
import '../models/prenda.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Pedido>> obtenerPedidos() async {
    try {
      final response = await _supabase
          .from('pedidos')
          .select('''
            *,
            medidas:medidas_pedido(*),
            prendas:prendas(*)
          ''')
          .order('fecha_registro', ascending: false);

      if (response is! List) {
        print(' La respuesta no es una lista: ${response.runtimeType}');
        return [];
      }

      final List<dynamic> data = response;

      return data.map((json) {
        // Procesar medidas si existen
        List<Medida> medidas = [];
        if (json['medidas'] != null && json['medidas'] is List) {
          medidas = (json['medidas'] as List).map((m) => Medida(
            id: m['id_medida']?.toString() ?? '',
            pedidoId: json['id_pedido']?.toString() ?? '',
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
          titulo: json['codigo_pedido'] ?? 'Pedido',
          estanteId: json['id_estante']?.toString(),
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
  Future<bool> insertarPedido(Map<String, dynamic> pedidoData) async {
    try {
      final estanteId = int.tryParse(pedidoData['shelfAssignment']?.toString() ?? '0') ?? 0;
      
      if (estanteId == 0) {
        print('Estante no válido: ${pedidoData['shelfAssignment']}');
        return false;
      }

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
        'id_estante': estanteId,
        'prioridad': pedidoData['priority'] ?? 'Media',
        'tipo_prenda': pedidoData['garmentType'] ?? 'vestido',
        'talla': pedidoData['size'] ?? 'M',
      }).select();

      print('Pedido insertado correctamente: $response');
      return true;
    } catch (e) {
      print('Error en insertarPedido: $e');
      print('Datos del pedido: $pedidoData');
      return false;
    }
  }

  Future<List<Estante>> obtenerEstantes() async {
    try {
      final response = await _supabase
          .from('estantes')
          .select('*')
          .order('codigo', ascending: true);

      if (response is! List) {
        print(' La respuesta no es una lista: ${response.runtimeType}');
        return [];
      }

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

  Future<List<Recordatorio>> obtenerRecordatorios() async {
    try {
      final response = await _supabase
          .from('recordatorios')
          .select('*')
          .order('fecha_recordatorio', ascending: true);

      if (response is! List) {
        print(' La respuesta no es una lista: ${response.runtimeType}');
        return [];
      }

      final List<dynamic> data = response;

      return data.map((json) => Recordatorio(
        id: json['id_recordatorio']?.toString() ?? '',
        pedidoId: json['pedido_id']?.toString() ?? '',
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

  Future<List<Medida>> obtenerMedidasPorPedido(String pedidoId) async {
    try {
      final response = await _supabase
          .from('medidas_pedido')
          .select('*')
          .eq('pedido_id', int.tryParse(pedidoId) ?? 0)
          .order('tipo_medida', ascending: true);

      if (response is! List) {
        print('La respuesta no es una lista: ${response.runtimeType}');
        return [];
      }

      final List<dynamic> data = response;

      return data.map((json) => Medida(
        id: json['id_medida']?.toString() ?? '',
        pedidoId: pedidoId,
        clienteNombre: json['cliente_nombre'] ?? '',
        tipoMedida: json['tipo_medida'] ?? '',
        valor: (json['valor'] as num?)?.toDouble() ?? 0.0,
        observaciones: json['observaciones'] ?? '',
        fechaCreacion: json['fecha_creacion'] != null 
            ? DateTime.parse(json['fecha_creacion']) 
            : DateTime.now(),
        fechaActualizacion: json['fecha_actualizacion'] != null 
            ? DateTime.parse(json['fecha_actualizacion']) 
            : null,
      )).toList();
    } catch (e) {
      print('Error en obtenerMedidasPorPedido: $e');
      return [];
    }
  }

  /// Insertar una nueva medida
  Future<bool> insertarMedida(Map<String, dynamic> medidaData) async {
    try {
      await _supabase.from('medidas_pedido').insert({
        'pedido_id': int.tryParse(medidaData['pedidoId']?.toString() ?? '0') ?? 0,
        'tipo_medida': medidaData['tipoMedida'] ?? '',
        'valor': medidaData['valor'] ?? 0.0,
        'observaciones': medidaData['observaciones'] ?? '',
        'fecha_creacion': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error en insertarMedida: $e');
      return false;
    }
  }
}