import 'dart:convert';

import 'package:admin/Models/ConversationModel.dart';
import 'package:admin/services/services_firebase.dart';
import 'package:http/http.dart' as http;

class ChatMessage {
  final int idPerson;
  final String mensaje;
  final int idChat;
  final String nombres;
  final DateTime fechaRegistro;

  ChatMessage({required this.idPerson,required this.mensaje, required this.idChat, required this.nombres, required this.fechaRegistro,});

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      idPerson: json['idPerson'],
      mensaje: json['mensaje'],
      idChat: json['idChat'],
      nombres: json['Nombres'],
      fechaRegistro: DateTime.parse(json['fechaRegistro']).toUtc().add(Duration(hours: -4)),
    );
  }

  @override
  String toString() {
    return 'ChatMessage(id: $idPerson, message: $mensaje, idChat: $idChat, Nombres: $nombres)';
  }

}

