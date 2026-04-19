import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  static String get _url =>
      dotenv.env['SUPABASE_URL'] ?? (throw Exception('SUPABASE_URL tidak ditemukan di .env'));

  static String get _anonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? (throw Exception('SUPABASE_ANON_KEY tidak ditemukan di .env'));

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> init() async {
    await Supabase.initialize(url: _url, anonKey: _anonKey);
  }
}