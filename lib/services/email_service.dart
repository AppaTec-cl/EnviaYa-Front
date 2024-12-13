import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

Future<void> sendTrackingEmail({
  required String recipientEmail,
  required String recipientName,
  required String trackingNumber,
  required String address,
  required String city,
  required String postalCode,
}) async {
  final smtpServer = SmtpServer(
    'smtp.zoho.com',
    port: 465,
    ssl: true,
    username: 'admin@appatec.cl', 
    password: 'Boby1201*', 
  );

  final message = Message()
    ..from = Address('admin@appatec.cl', 'EnviaYa') 
    ..recipients.add(recipientEmail)
    ..subject = 'EnviaYa: Número de Seguimiento de tu Paquete'
    ..text = '''
Hola $recipientName,

Gracias por elegir EnviaYa. Aquí están los detalles de tu envío:

- Número de seguimiento: $trackingNumber
- Dirección de entrega: $address
- Ciudad: $city
- Código postal: $postalCode

Puedes usar el número de seguimiento para rastrear el estado de tu paquete en nuestra plataforma.

Si tienes alguna pregunta o necesitas asistencia, no dudes en contactarnos.

Atentamente,
El equipo de EnviaYa.
''';

  try {
    final sendReport = await send(message, smtpServer);
    print('Correo enviado: ${sendReport.toString()}');
  } catch (e) {
    print('Error al enviar el correo: $e');
  }
}
