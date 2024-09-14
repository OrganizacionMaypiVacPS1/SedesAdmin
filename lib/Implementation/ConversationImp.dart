import 'dart:convert';

import 'package:admin/Models/ConversationModel.dart';
import 'package:admin/services/Config.dart';
import 'package:admin/services/services_firebase.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;



Future<List<Chat>> fetchChats(BuildContext context) async {
  final response = await http.get(Uri.parse(
      Config.baseUrl+'/getchats/' +
          miembroActual!.id.toString()));
  if (response.statusCode == 200) {
    List<dynamic> jsonResponse = json.decode(response.body);
    return jsonResponse.map((data) => Chat.fromJson(data)).toList();
  } else {
      showSnackbar(context, "Error: " + response.body.toString());
      return[];
  }
}


Future<List<Chat>> fetchChatsClient(BuildContext context) async {
  final response = await http.get(Uri.parse(
      Config.baseUrl+'/getchatcliente/' +
          miembroActual!.id.toString()));
  if (response.statusCode == 200) {
    List<dynamic> jsonResponse = json.decode(response.body);
    return jsonResponse.map((data) => Chat.fromJson(data)).toList();
  } else {
    showSnackbar(context, "Error: " + response.body.toString());
    return[];
  }
}


Future<List<dynamic>> fetchNamesPersonDestino(BuildContext context, int idPersonDestino) async {
  final response = await http.get(Uri.parse(
      Config.baseUrl+'/getnamespersondestino/' +
          idPersonDestino.toString()));
  if (response.statusCode == 200) {
    List<dynamic> jsonResponse = json.decode(response.body);
    return jsonResponse;
  } else {
    showSnackbar(context, "Error: " + response.body.toString());
    return[];
  }
}
