// lib/services/estante_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/estante.dart';

class EstanteService {
  final supabase = Supabase.instance.client;

  Future<List<Estante>> obtenerEstantes() async {
    try {
      final response = await supabase
          .from('estantes')
          .select('''
            *,
            pedidos:pedidos(count)
          ''');

      List<Estante> estantes = [];
      for (var json in response) {
        try {
          // Contar pedidos activos en este estante
          int ocupados = 0;
          if (json['pedidos'] != null) {
            // Si pedidos es un array, contar los elementos
            if (json['pedidos'] is List) {
              ocupados = (json['pedidos'] as List).length;
            } else if (json['pedidos'] is Map) {
              // Si es un objeto con count
              ocupados = json['pedidos']['count'] ?? 0;
            }
          }

          final estante = Estante(
            id: json['id_estante']?.toString() ?? '',
            nombre: json['descripcion'] ?? 'Estante ${json['codigo_estante'] ?? ''}',
            ubicacion: json['ubicacion'] ?? '',
            descripcion: json['descripcion'] ?? '',
            capacidad: json['capacidad'] ?? 10,
            ocupados: ocupados,
            fechaCreacion: json['fecha_creacion'] != null 
                ? DateTime.parse(json['fecha_creacion']) 
                : DateTime.now(),
            fechaActualizacion: json['fecha_actualizacion'] != null 
                ? DateTime.parse(json['fecha_actualizacion']) 
                : null,
          );
          estantes.add(estante);
        } catch (e) {
          print('Error al mapear estante: $e');
        }
      }
      return estantes;
    } catch (e) {
      print('Error al obtener estantes: $e');
      return [];
    }
  }

  Future<Estante?> obtenerEstantePorId(String id) async {
    try {
      final response = await supabase
          .from('estantes')
          .select('''
            *,
            pedidos:pedidos(count)
          ''')
          .eq('id_estante', int.tryParse(id) ?? 0)
          .maybeSingle();

      if (response == null) return null;

      // Contar pedidos activos en este estante
      int ocupados = 0;
      if (response['pedidos'] != null) {
        if (response['pedidos'] is List) {
          ocupados = (response['pedidos'] as List).length;
        } else if (response['pedidos'] is Map) {
          ocupados = response['pedidos']['count'] ?? 0;
        }
      }

      return Estante(
        id: response['id_estante']?.toString() ?? '',
        nombre: response['descripcion'] ?? 'Estante ${response['codigo_estante'] ?? ''}',
        ubicacion: response['ubicacion'] ?? '',
        descripcion: response['descripcion'] ?? '',
        capacidad: response['capacidad'] ?? 10,
        ocupados: ocupados,
        fechaCreacion: response['fecha_creacion'] != null 
            ? DateTime.parse(response['fecha_creacion']) 
            : DateTime.now(),
        fechaActualizacion: response['fecha_actualizacion'] != null 
            ? DateTime.parse(response['fecha_actualizacion']) 
            : null,
      );
    } catch (e) {
      print('Error al obtener estante por ID: $e');
      return null;
    }
  }

  Future<bool> crearEstante(String codigo, int capacidad, {String? descripcion, String? ubicacion}) async {
    try {
      await supabase
          .from('estantes')
          .insert({
            'codigo_estante': codigo,
            'capacidad': capacidad,
            'descripcion': descripcion ?? 'Estante $codigo',
            'ubicacion': ubicacion ?? '',
            'ocupados': 0,
            'fecha_creacion': DateTime.now().toIso8601String(),
          });

      return true;
    } catch (e) {
      print('Error al crear estante: $e');
      return false;
    }
  }

  Future<bool> actualizarEstante(String id, Map<String, dynamic> data) async {
    try {
      await supabase
          .from('estantes')
          .update({
            'descripcion': data['nombre'],
            'ubicacion': data['ubicacion'],
            'capacidad': data['capacidad'],
            'fecha_actualizacion': DateTime.now().toIso8601String(),
          })
          .eq('id_estante', int.tryParse(id) ?? 0);

      return true;
    } catch (e) {
      print('Error al actualizar estante: $e');
      return false;
    }
  }

  Future<bool> actualizarOcupados(String id, int nuevoOcupados) async {
    try {
      await supabase
          .from('estantes')
          .update({
            'ocupados': nuevoOcupados,
            'fecha_actualizacion': DateTime.now().toIso8601String(),
          })
          .eq('id_estante', int.tryParse(id) ?? 0);

      return true;
    } catch (e) {
      print('Error al actualizar ocupados: $e');
      return false;
    }
  }

  Future<bool> eliminarEstante(String id) async {
    try {
      await supabase
          .from('estantes')
          .delete()
          .eq('id_estante', int.tryParse(id) ?? 0);

      return true;
    } catch (e) {
      print('Error al eliminar estante: $e');
      return false;
    }
  }

  Future<List<Estante>> obtenerEstantesDisponibles() async {
    try {
      final response = await supabase
          .from('estantes')
          .select('''
            *,
            pedidos:pedidos(count)
          ''')
          .filter('ocupados', 'lt', 'capacidad')
          .order('codigo_estante', ascending: true);

      List<Estante> estantes = [];
      for (var json in response) {
        try {
          int ocupados = 0;
          if (json['pedidos'] != null) {
            if (json['pedidos'] is List) {
              ocupados = (json['pedidos'] as List).length;
            } else if (json['pedidos'] is Map) {
              ocupados = json['pedidos']['count'] ?? 0;
            }
          }

          final estante = Estante(
            id: json['id_estante']?.toString() ?? '',
            nombre: json['descripcion'] ?? 'Estante ${json['codigo_estante'] ?? ''}',
            ubicacion: json['ubicacion'] ?? '',
            descripcion: json['descripcion'] ?? '',
            capacidad: json['capacidad'] ?? 10,
            ocupados: ocupados,
            fechaCreacion: json['fecha_creacion'] != null 
                ? DateTime.parse(json['fecha_creacion']) 
                : DateTime.now(),
            fechaActualizacion: json['fecha_actualizacion'] != null 
                ? DateTime.parse(json['fecha_actualizacion']) 
                : null,
          );
          estantes.add(estante);
        } catch (e) {
          print('Error al mapear estante: $e');
        }
      }
      return estantes;
    } catch (e) {
      print('Error al obtener estantes disponibles: $e');
      return [];
    }
  }

  Future<List<Estante>> obtenerEstantesLlenos() async {
    try {
      final response = await supabase
          .from('estantes')
          .select('''
            *,
            pedidos:pedidos(count)
          ''')
          .filter('ocupados', 'gte', 'capacidad')
          .order('codigo_estante', ascending: true);

      List<Estante> estantes = [];
      for (var json in response) {
        try {
          int ocupados = 0;
          if (json['pedidos'] != null) {
            if (json['pedidos'] is List) {
              ocupados = (json['pedidos'] as List).length;
            } else if (json['pedidos'] is Map) {
              ocupados = json['pedidos']['count'] ?? 0;
            }
          }

          final estante = Estante(
            id: json['id_estante']?.toString() ?? '',
            nombre: json['descripcion'] ?? 'Estante ${json['codigo_estante'] ?? ''}',
            ubicacion: json['ubicacion'] ?? '',
            descripcion: json['descripcion'] ?? '',
            capacidad: json['capacidad'] ?? 10,
            ocupados: ocupados,
            fechaCreacion: json['fecha_creacion'] != null 
                ? DateTime.parse(json['fecha_creacion']) 
                : DateTime.now(),
            fechaActualizacion: json['fecha_actualizacion'] != null 
                ? DateTime.parse(json['fecha_actualizacion']) 
                : null,
          );
          estantes.add(estante);
        } catch (e) {
          print('Error al mapear estante: $e');
        }
      }
      return estantes;
    } catch (e) {
      print('Error al obtener estantes llenos: $e');
      return [];
    }
  }

  Future<Map<String, int>> obtenerEstadisticas() async {
    try {
      final response = await supabase
          .from('estantes')
          .select('''
            *,
            pedidos:pedidos(count)
          ''');

      int total = 0;
      int disponibles = 0;
      int casiLlenos = 0;
      int llenos = 0;

      for (var json in response) {
        total++;
        final capacidad = json['capacidad'] ?? 10;
        
        // Contar ocupados
        int ocupados = 0;
        if (json['pedidos'] != null) {
          if (json['pedidos'] is List) {
            ocupados = (json['pedidos'] as List).length;
          } else if (json['pedidos'] is Map) {
            ocupados = json['pedidos']['count'] ?? 0;
          }
        }

        final porcentaje = capacidad > 0 ? ocupados / capacidad : 0.0;
        if (porcentaje >= 1.0) {
          llenos++;
        } else if (porcentaje >= 0.75) {
          casiLlenos++;
        } else {
          disponibles++;
        }
      }

      return {
        'total': total,
        'disponibles': disponibles,
        'casiLlenos': casiLlenos,
        'llenos': llenos,
      };
    } catch (e) {
      print('Error al obtener estadísticas: $e');
      return {
        'total': 0,
        'disponibles': 0,
        'casiLlenos': 0,
        'llenos': 0,
      };
    }
  }

  Future<bool> tieneEspacioDisponible(String id) async {
    try {
      final estante = await obtenerEstantePorId(id);
      if (estante == null) return false;
      return estante.ocupados < estante.capacidad;
    } catch (e) {
      print('Error al verificar espacio: $e');
      return false;
    }
  }

  String _obtenerEstado(int ocupados, int capacidad) {
    if (capacidad == 0) return "Lleno";
    final percentage = ocupados / capacidad;
    if (percentage >= 1.0) return "Lleno";
    if (percentage >= 0.75) return "Casi Lleno";
    return "Abierto";
  }
}