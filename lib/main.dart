/// <summary>
/// Nombre de la aplicación: AdminMaYpiVaC
/// Nombre del desarrollador: Equipo-Sedes-Univalle
/// Fecha de creación: 18/08/2023
/// </summary>
/// 
// <copyright file="main.dart" company="Sedes-Univalle">
// Esta clase está restringida para su uso, sin la previa autorización de Sedes-Univalle.
// </copyright>


//import 'dart:js';

import 'package:admin/Presentation/Screens/SplashScreen.dart';
import 'package:admin/services/notification_services.dart';
import 'package:admin/services/global_notification.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import '../firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await PushNotificationService.initializeApp();
  //PushNotificationService.messagesStream.listen((message){
  //  print('MyApp: $message');
  //});

  runApp(

    MultiProvider(providers: [
      Provider<LocalNotificationService>(create: (context) => LocalNotificationService()),
      //Provider<PushNotificationService>(create: (context) => PushNotificationService(),)
    ],
    child: const MainApp(),)
    );
}


class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);
  
  
  @override

  Widget build(BuildContext  context) {
    return  MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/home',
        routes: {
          '/home': (context) => const SplashScreen(),
        },
      );
  }
}

 