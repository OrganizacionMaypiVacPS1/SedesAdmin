
import 'dart:convert';

import 'package:admin/Config/Config.dart';
import 'package:admin/services/services_firebase.dart';
import 'package:http/http.dart' as http;


  Future<void> tokenClean() async {
    final url = Config.baseUrl+'/logouttoken';
    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'token': token,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al enviar el mensaje');
    }
  }