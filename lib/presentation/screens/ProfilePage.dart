import 'package:admin/services/Config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:convert';
import 'dart:developer';
import 'dart:math';
import 'package:admin/Models/Profile.dart';
import 'package:admin/presentation/screens/ChangePassword.dart';
import 'package:admin/presentation/screens/RegisterBoss.dart';
import 'package:admin/services/services_firebase.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:admin/presentation/screens/Campaign.dart';
import 'package:admin/presentation/screens/List_members.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class ProfilePage extends StatelessWidget {
  Member? member;

  Future<Member?> recoverPassword(String email) async {
    final url = Uri.parse(Config.baseUrl+'/checkemail/$email');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      member = Member.fromJson2(data);

      return member;
    } else if (response.statusCode == 404) {
      return null; // Correo no encontrado en la base de datos
    } else {
      throw Exception('Error al recuperar la contraseña');
    }
  }

  Future<bool> sendEmailAndUpdateCode(int userId) async {
    final code = generateRandomCode();
    final exists = await checkCodeExists(userId);
    final smtpServer = gmail('bdcbba96@gmail.com', 'ehbh ugsw srnj jxsf');
    final message = Message()
      ..from = Address('bdcbba96@gmail.com', 'Admin')
      ..recipients.add(member!.correo)
      ..subject = 'Cambiar Contraseña MaYpiVaC'
      ..text = 'Código de recuperación de contraseña: $code';
    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
      // Actualiza la base de datos
      final url = exists
          ? Uri.parse(
              Config.baseUrl+'/updateCode/$userId/$code') // URL para actualizar el código
          : Uri.parse(
              Config.baseUrl+'/insertCode/$userId/$code'); // URL para insertar un nuevo registro
      final response = await (exists ? http.put(url) : http.post(url));
      if (response.statusCode == 200) {
        print('Código actualizado/insertado en la base de datos.');
        return true; // Devuelve true si todo fue exitoso
      } else {
        print('Error al actualizar/insertar el código en la base de datos.');
        return false; // Devuelve false en caso de error
      }
    } catch (e) {
      print('Message not sent.');
      print(e.toString());
      return false; // Devuelve false en caso de error
    }
  }

  String generateRandomCode() {
    final random = Random();
    final firstDigit =
        random.nextInt(9) + 1; // Genera un número aleatorio entre 1 y 9
    final restOfDigits = List.generate(4, (index) => random.nextInt(10)).join();
    final code = '$firstDigit$restOfDigits';
    return code;
  }

  Future<bool> checkCodeExists(int userId) async {
    var userId = member?.id;
    final response = await http.get(
      Uri.parse(
          Config.baseUrl+'/checkCodeExists/$userId'), // Reemplaza con la URL correcta de tu API
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data[
          'exists']; // Suponiendo que la API devuelve un booleano llamado "exists"
    } else {
      throw Exception('Error al verificar el código.');
    }
  }

  ProfilePage({this.member});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Perfil de ${member!.names}"),
        backgroundColor: Color.fromARGB(255, 92, 142, 203),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.arrow_back,
                color: Color.fromARGB(255, 255, 255, 255)),
            onPressed: () {
                Navigator.pop(context);
              
            },
          ),
        ),
      ),
      body: Container(
        color: Color.fromARGB(255, 255, 255, 255),
        child: Column(
          children: [
            FractionallySizedBox(
              widthFactor: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 92, 142, 203),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(80),
                    bottomRight: Radius.circular(80),
                  ),
                ),
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "${member!.names}",
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    Text(
                      "${member!.role}",
                      style: TextStyle(
                        fontSize: 18,
                        color: Color.fromARGB(255, 10, 10, 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoItem("Correo: ${member!.correo}"),
                      _buildInfoItem("Carnet: ${member!.carnet}"),
                      _buildInfoItem("Teléfono: ${member!.telefono}"),
                      _buildInfoItem(
                          "Fecha de Nacimiento: ${member!.fechaNacimiento}"),
                      _buildMap(member!.latitud, member!.longitud),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              if (member!.role == "Carnetizador") {
                                esCarnetizador = true;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RegisterBossPage(
                                      isUpdate: true, userData: member),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white, // Fondo blanco
                              padding: EdgeInsets.symmetric(
                                  horizontal: 45, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                side: BorderSide(
                                    color: Color.fromARGB(255, 92, 142, 203),
                                    width: 3.0), // Bordes del color deseado
                              ),
                            ),
                            child: Text(
                              "Editar Perfil",
                              style: TextStyle(
                                color: Color(0xFF4D6596),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 20),
                          if(miembroActual!.role=="Administrador"||miembroActual!.role=="Super Admin")
                          _buildSendEmailButton(context)
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendEmailButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF4D6596),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
      ),
      onPressed: () async {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return FutureBuilder(
              future: sendEmailAndUpdateCode(member!.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return AlertDialog(
                    title: Text('Espere unos momentos....'),
                    content: SingleChildScrollView(
                      child: ListBody(
                        children: [
                          Center(
                            child: SpinKitFadingCube(
                              color: Colors.blue,
                              size: 50.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return AlertDialog(
                    title: Text('Error'),
                    content: Text(
                        'Ocurrió un error al enviar el código de recuperación.'),
                    actions: <Widget>[
                      TextButton(
                        child: Text('Cerrar'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                } else {
                  // El proceso se completó con éxito
                  return AlertDialog(
                    title: Text('Éxito'),
                    content: Text(
                        'Se ha enviado un código a tu correo electrónico.'),
                    actions: <Widget>[
                      TextButton(
                        child: Text('Cerrar'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChangePasswordPage(
                                member: member,
                              ),
                            ),
                          );
                          isLogin = 0;
                        },
                      ),
                    ],
                  );
                }
              },
            );
          },
        );
      },
      child: Text("Cambiar Contraseña"),
    );
  }

  Widget _buildInfoItem(String text) {
    final List<String> parts =
        text.split(":"); // Dividimos el texto en dos partes

    return Container(
      padding: EdgeInsets.symmetric(vertical: 13, horizontal: 20),
      child: RichText(
        text: TextSpan(
          style:
              TextStyle(color: Color.fromARGB(255, 92, 142, 203), fontSize: 20),
          children: [
            TextSpan(
              text: "${parts[0]}: ", // Parte del título en negrita
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: parts[1], style: TextStyle(color: Colors.black)
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildMap(double lat, double lng) {
  return Container(
    height: 150, // Altura del cuadro del mapa
    width: double.infinity, // Ocupa todo el ancho disponible
    child: GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(lat, lng),
        zoom: 15,
      ),
      markers: {
        Marker(
          markerId: MarkerId('memberLocation'),
          position: LatLng(lat, lng),
        ),
      },
    ),
  );
}
