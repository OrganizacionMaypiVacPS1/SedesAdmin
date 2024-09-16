/// <summary>
/// Nombre de la aplicación: AdminMaYpiVaC
/// Nombre del desarrollador: Equipo-Sedes-Univalle
/// Fecha de creación: 18/08/2023
/// </summary>
///
// <copyright file="SplashScreen.dart" company="Sedes-Univalle">
// Esta clase está restringida para su uso, sin la previa autorización de Sedes-Univalle.
// </copyright>

import 'package:admin/Implementation/CampaignImplementation.dart';
import 'package:admin/Models/CampaignModel.dart';
import 'package:admin/presentation/screens/Login.dart';
import 'package:admin/Config/Config.dart';
import 'package:admin/services/global_notification.dart';
import 'package:admin/services/notification_services.dart';
import 'package:admin/services/services_firebase.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    
    socket =
        IO.io(Config.baseUrl+'', <String, dynamic>{
      //192.168.14.112
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();
    socket.onConnect((_) {
      print('Conectado');
    });
    socket.onConnectError((data) => print("Error de conexión: $data"));
    socket.onError((data) => print("Error: $data"));

    super.initState();
    Navegar_Pantalla_Main();
  }


  Future<void> Navegar_Pantalla_Main() async {
    campaigns = await fetchCampaigns(context);
    //await Future.delayed(const Duration(seconds: 2)); // Espera 2 segundos
    // ignore: use_build_context_synchronously
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MyApp()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Establece el color de fondo de tu splash screen
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white, // Color de fondo del splash screen
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
                height: 500,
                width: 500,
                child: Column(
                  children: [
                    Image.asset(
                      "assets/LogoHorizontal.png",
                      width: MediaQuery.of(context).size.width * 0.9, 
                    ),
                    SizedBox(height: 10),
                  ],
                )
              ),
            //FlutterLogo(size: 150),
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF86ABF9)),
            )
          ],
        ),
      ),
    );
  }
}
