import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  // Genera un código aleatorio de 6 dígitos
  static String generarCodigo() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Envía el correo al padre
  static Future<bool> enviarCodigo(String correoPadre, String codigo) async {
    // REEMPLAZA ESTO CON TUS DATOS REALES
    String username = 'daea.studio@gmail.com'; 
    String password = 'edsajvvximsymyib'; 

    final smtpServer = gmail(username, password);

    final message = Message()
      ..from = Address(username, 'EduPlay 2.0 🚀')
      ..recipients.add(correoPadre)
      ..subject = 'Código de Verificación - EduPlay 2.0'
      ..html = '''
        <div style="font-family: sans-serif; text-align: center; color: #333;">
          <h2 style="color: #4ECDC4;">¡Hola!</h2>
          <p>Tu explorador quiere iniciar una nueva aventura en EduPlay.</p>
          <p>Para autorizar su cuenta y recibir sus reportes, ingresa el siguiente código en la aplicación:</p>
          <div style="background-color: #f4f4f4; padding: 20px; border-radius: 10px; display: inline-block; margin: 20px 0;">
            <h1 style="color: #9D4EDD; letter-spacing: 8px; margin: 0;">$codigo</h1>
          </div>
          <p style="font-size: 12px; color: #999;">Si no solicitaste esto, ignora este mensaje.</p>
        </div>
      ''';

    try {
      await send(message, smtpServer);
      return true;
    } catch (e) {
      print('Error al enviar correo: $e');
      return false;
    }
  }
}