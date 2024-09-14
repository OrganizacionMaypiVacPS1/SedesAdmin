import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class CustomNotification{
  final int id;
  final String? title;
  final String? body;
  
  CustomNotification({ required this.id, required this.title, required this.body});
}

class LocalNotificationService{
  late FlutterLocalNotificationsPlugin localNotificationsPlugin;
  late AndroidNotificationDetails androidDetails;

  LocalNotificationService(){
    localNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _setupNotifications();
  }

  _setupNotifications() async {
    await _initializeNotifications();
  }

  _initializeNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    await localNotificationsPlugin.initialize(
      const InitializationSettings(
        android:  android,
      ),
      //_onSelectNotification
    );
  }

  showNotification(CustomNotification notification){
    androidDetails = const AndroidNotificationDetails(
      'channel id',
      'channel name',
      channelDescription: "Your description",
      importance: Importance.max,
      icon: 'icon',  
    );

    localNotificationsPlugin.show(notification.id, notification.title, notification.body, 
    NotificationDetails(
      android: androidDetails
    ));
  }

  checkForNotifications() async {
    final details = await localNotificationsPlugin.getNotificationAppLaunchDetails();
    if(details!=null&&details.didNotificationLaunchApp){
      //_onSelectNotification
    }
  }
}