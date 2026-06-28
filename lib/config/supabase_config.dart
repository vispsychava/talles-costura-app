// lib/config/supabase_config.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String _url = 'https://lckwfjszggnioczjfyxm.supabase.co';
  static const String _anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxja3dmanN6Z2duaW9jempmeXhtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEyODkzOTUsImV4cCI6MjA5Njg2NTM5NX0.8nV7pQPOosjPX4RyjYZxgVfyMqm9Rsjeaa8VO9ANIco';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _url,
      anonKey: _anonKey,
    );
  }

  // ✅ Método para obtener la URL (por si la necesitas en otro lado)
  static String get url => _url;
  
  // ✅ Método para obtener la clave anónima (por si la necesitas en otro lado)
  static String get anonKey => _anonKey;
}