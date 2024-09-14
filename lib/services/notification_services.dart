import 'dart:async';
import 'package:admin/services/global_notification.dart';
import 'package:admin/services/services_firebase.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import '../firebase_options.dart';


class PushNotificationService {
  static FirebaseMessaging messaging = FirebaseMessaging.instance;
  static StreamController<String> _messageStream = new StreamController.broadcast();
  static Stream<String> get messagesStream=> _messageStream.stream;
  static final FlutterLocalNotificationsPlugin localNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static final LocalNotificationService localNotificationService = LocalNotificationService();



  static Future _backgroundHandler( RemoteMessage message )async{
    print('onBackGround Handler ${message.messageId}');
    var idPerson = message.data['idChat'];
    _messageStream.add(message.notification?.title ?? 'No title');
    print(idPerson);
    print(currentChatId);
    

    if(idPerson.toString()!=currentChatId.toString()){
      CustomNotification customNotification = CustomNotification(
        id: 0, 
        title: message.notification?.title,
        body: message.notification?.body,
      );
      localNotificationService.showNotification(customNotification);
    }
  }

  static Future _onMessageHandler(RemoteMessage message) async {
    print('onMessage Handler ${message.messageId}');
    var idPerson = message.data['idChat'];
    _messageStream.add(message.notification?.title ?? 'No title');
    print(idPerson);
    print(currentChatId);
    

    if(idPerson.toString()!=currentChatId.toString()){
      CustomNotification customNotification = CustomNotification(
        id: 0, 
        title: message.notification?.title,
        body: message.notification?.body,
      );
      localNotificationService.showNotification(customNotification);
    }
    
}


  static Future _onMessageOpenApp( RemoteMessage message )async{
    print('onMessageOpenApp Handler ${message.messageId}');
    var idPerson = message.data['idChat'];
    _messageStream.add(message.notification?.title ?? 'No title');
    print(idPerson);
    print(currentChatId);
    

    if(idPerson.toString()!=currentChatId.toString()){
      CustomNotification customNotification = CustomNotification(
        id: 0, 
        title: message.notification?.title,
        body: message.notification?.body,
      );
      localNotificationService.showNotification(customNotification);
    }
  }

  static Future initializeApp() async {
    token = await FirebaseMessaging.instance.getToken();

    print('token: $token');
    //var initializationSettingsAndroid = AndroidInitializationSettings('ic_launcher');
    //var initializationSettingsIOS = DarwinInitializationSettings();
    //var initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

    //localNotificationsPlugin.initialize(initializationSettings);
    

    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
    FirebaseMessaging.onMessage.listen(_onMessageHandler);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenApp);


  }

  static closeStreams(){
    _messageStream.close();
  }
}