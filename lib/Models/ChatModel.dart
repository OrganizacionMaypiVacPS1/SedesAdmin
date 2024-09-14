import 'dart:convert';

import 'package:admin/Models/ConversationModel.dart';
import 'package:admin/services/services_firebase.dart';
import 'package:http/http.dart' as http;

class ChatMessage {
  final int idPerson;
  final String mensaje;
  final int idChat;
  final String nombres;

  ChatMessage({required this.idPerson,required this.mensaje, required this.idChat, required this.nombres});

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      idPerson: json['idPerson'],
      mensaje: json['mensaje'],
      idChat: json['idChat'],
      nombres: json['Nombres'],
    );
  }

  @override
  String toString() {
    return 'ChatMessage(id: $idPerson, message: $mensaje, idChat: $idChat, Nombres: $nombres)';
  }

}

