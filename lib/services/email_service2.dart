import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  final String smtpHost = 'smtp.zoho.com';
  final int smtpPort = 465;
  final String username = 'admin@appatec.cl'; 
  final String password = 'Boby1201*'; 

  Future<void> sendProblemReportEmail({
    required String recipientEmail,
    required String recipientName,
    required String trackingNumber,
    required String problemDescription,
  }) async {
    final smtpServer = SmtpServer(
      smtpHost,
      port: smtpPort,
      ssl: true,
      username: username,
      password: password,
    );

    final message = Message()
      ..from = Address(username, 'EnviaYa - Reporte de Problema')
      ..recipients.add(recipientEmail)
      ..subject = 'Reporte de Problema - Pedido $trackingNumber'
      ..text = '''
Estimado/a $recipientName,

Le informamos que hemos registrado un problema con su pedido asociado al número de seguimiento $trackingNumber.

**Descripción del problema**: 
$problemDescription

Nos disculpamos por los inconvenientes causados y le aseguramos que estamos trabajando para solucionar este problema a la brevedad.

Si tiene alguna consulta o requiere más información, no dude en contactarnos respondiendo este correo.

Atentamente,
El equipo de EnviaYa
''';

    try {
      await send(message, smtpServer);
      print('Correo enviado al cliente con éxito.');
    } catch (e) {
      print('Error al enviar el correo: $e');
      rethrow;
    }
  }
}
