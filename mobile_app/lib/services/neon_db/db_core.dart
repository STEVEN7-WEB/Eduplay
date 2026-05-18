import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';

class DbCore {
  static Future<Connection> conectar() async {
    final endpoint = Endpoint(
      host: 'ep-bold-sea-ammozaye-pooler.c-5.us-east-1.aws.neon.tech',
      database: 'neondb',
      username: 'neondb_owner',
      password: 'npg_XkHAZ3tCTf8U', 
      port: 5432,
    );
    return await Connection.open(endpoint, settings: ConnectionSettings(sslMode: SslMode.require));
  }

  static String hp(String texto) {
    var bytes = utf8.encode(texto); 
    var digest = sha256.convert(bytes); 
    return digest.toString(); 
  }
}