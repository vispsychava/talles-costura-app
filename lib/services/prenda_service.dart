// lib/services/prenda_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/prenda.dart';

class PrendaService {
  final supabase = Supabase.instance.client;

  Future<List<Prenda>> obtenerPrendas() async {
    try {
      final response = await supabase
          .from('prendas')
          .select('*')
          .order('nombre', ascending: true);

      return response
          .map<Prenda>((json) => Prenda.fromJson(json))
          .toList();
    } catch (e) {
      print('Error al obtener prendas: $e');
      return [];
    }
  }

  Future<Prenda?> obtenerPrendaPorId(String id) async {
    try {
      final response = await supabase
          .from('prendas')
          .select('*')
          .eq('id_prenda', int.tryParse(id) ?? 0)
          .maybeSingle();

      if (response == null) return null;
      return Prenda.fromJson(response);
    } catch (e) {
      print('Error al obtener prenda por ID: $e');
      return null;
    }
  }

  Future<List<Prenda>> obtenerPrendasPorPedido(String pedidoId) async {
    try {
      final response = await supabase
          .from('prendas')
          .select('*')
          .eq('pedido_id', int.tryParse(pedidoId) ?? 0)
          .order('nombre', ascending: true);

      return response
          .map<Prenda>((json) => Prenda.fromJson(json))
          .toList();
    } catch (e) {
      print('Error al obtener prendas por pedido: $e');
      return [];
    }
  }

  Future<bool> crearPrenda(Map<String, dynamic> prendaData) async {
    try {
      await supabase.from('prendas').insert({
        'pedido_id': int.tryParse(prendaData['pedidoId']?.toString() ?? '0') ?? 0,
        'nombre': prendaData['nombre'] ?? '',
        'descripcion': prendaData['descripcion'] ?? '',
        'talla': prendaData['talla'] ?? '',
        'color': prendaData['color'] ?? '',
        'material': prendaData['material'] ?? '',
        'precio': prendaData['precio'] ?? 0.0,
        'estado': prendaData['estado'] ?? 'Pendiente',
        'id_estante': int.tryParse(prendaData['estanteId']?.toString() ?? '0') ?? 0,
        'fecha_creacion': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error al crear prenda: $e');
      return false;
    }
  }

  Future<bool> actualizarPrenda(String id, Map<String, dynamic> data) async {
    try {
      await supabase
          .from('prendas')
          .update({
            'nombre': data['nombre'],
            'descripcion': data['descripcion'],
            'talla': data['talla'],
            'color': data['color'],
            'material': data['material'],
            'precio': data['precio'],
            'estado': data['estado'],
            'id_estante': int.tryParse(data['estanteId']?.toString() ?? '0') ?? 0,
            'fecha_actualizacion': DateTime.now().toIso8601String(),
          })
          .eq('id_prenda', int.tryParse(id) ?? 0);

      return true;
    } catch (e) {
      print('Error al actualizar prenda: $e');
      return false;
    }
  }

  Future<bool> actualizarEstadoPrenda(String id, String nuevoEstado) async {
    try {
      await supabase
          .from('prendas')
          .update({
            'estado': nuevoEstado,
            'fecha_actualizacion': DateTime.now().toIso8601String(),
          })
          .eq('id_prenda', int.tryParse(id) ?? 0);

      return true;
    } catch (e) {
      print('Error al actualizar estado de prenda: $e');
      return false;
    }
  }

  Future<bool> actualizarEstantePrenda(String id, String estanteId) async {
    try {
      await supabase
          .from('prendas')
          .update({
            'id_estante': int.tryParse(estanteId) ?? 0,
            'fecha_actualizacion': DateTime.now().toIso8601String(),
          })
          .eq('id_prenda', int.tryParse(id) ?? 0);

      return true;
    } catch (e) {
      print('Error al actualizar estante de prenda: $e');
      return false;
    }
  }

  Future<bool> eliminarPrenda(String id) async {
    try {
      await supabase
          .from('prendas')
          .delete()
          .eq('id_prenda', int.tryParse(id) ?? 0);

      return true;
    } catch (e) {
      print('Error al eliminar prenda: $e');
      return false;
    }
  }


  Future<List<Prenda>> buscarPrendas(String query) async {
    try {
      final response = await supabase
          .from('prendas')
          .select('*')
          .ilike('nombre', '%$query%')
          .order('nombre', ascending: true);

      return response
          .map<Prenda>((json) => Prenda.fromJson(json))
          .toList();
    } catch (e) {
      print('Error al buscar prendas: $e');
      return [];
    }
  }

  Future<List<Prenda>> obtenerPrendasPorEstado(String estado) async {
    try {
      final response = await supabase
          .from('prendas')
          .select('*')
          .eq('estado', estado)
          .order('nombre', ascending: true);

      return response
          .map<Prenda>((json) => Prenda.fromJson(json))
          .toList();
    } catch (e) {
      print('Error al obtener prendas por estado: $e');
      return [];
    }
  }

  
  Future<List<Prenda>> obtenerPrendasPorEstante(String estanteId) async {
    try {
      final response = await supabase
          .from('prendas')
          .select('*')
          .eq('id_estante', int.tryParse(estanteId) ?? 0)
          .order('nombre', ascending: true);

      return response
          .map<Prenda>((json) => Prenda.fromJson(json))
          .toList();
    } catch (e) {
      print('Error al obtener prendas por estante: $e');
      return [];
    }
  }

  Future<Map<String, int>> obtenerEstadisticas() async {
    try {
      final response = await supabase
          .from('prendas')
          .select('estado');

      int total = response.length;
      int pendientes = 0;
      int enProceso = 0;
      int terminadas = 0;
      int entregadas = 0;

      for (var json in response) {
        final estado = json['estado'] ?? '';
        switch (estado) {
          case 'Pendiente':
            pendientes++;
            break;
          case 'En proceso':
            enProceso++;
            break;
          case 'Terminado':
            terminadas++;
            break;
          case 'Entregado':
            entregadas++;
            break;
        }
      }

      return {
        'total': total,
        'pendientes': pendientes,
        'enProceso': enProceso,
        'terminadas': terminadas,
        'entregadas': entregadas,
      };
    } catch (e) {
      print('Error al obtener estadísticas de prendas: $e');
      return {
        'total': 0,
        'pendientes': 0,
        'enProceso': 0,
        'terminadas': 0,
        'entregadas': 0,
      };
    }
  }
}