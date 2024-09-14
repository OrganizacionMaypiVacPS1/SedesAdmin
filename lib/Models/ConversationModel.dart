import 'dart:convert';

import 'package:admin/services/services_firebase.dart';
import 'package:http/http.dart' as http;

class Chat {
  final int idChats;
  final int? idPerson;
  final int idPersonDestino;

  Chat(
      {required this.idChats,
      required this.idPerson,
      required this.idPersonDestino,
      });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      idChats: json['idChats'],
      idPerson: json['idPerson'],
      idPersonDestino: json['idPersonDestino'],
    );
  }

  @override
  String toString() {
    return 'ChatMessage(idChats: $idChats, idPerson: $idPerson, idPersonDestino: $idPersonDestino)';
  }
}
