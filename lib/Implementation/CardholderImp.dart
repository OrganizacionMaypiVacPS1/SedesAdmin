import 'dart:convert';
import 'package:admin/services/Config.dart';
import 'package:admin/services/services_firebase.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

Future<int> getNextIdPerson(BuildContext context) async {
  final response = await http.get(Uri.parse(
      Config.baseUrl+'/nextidperson')); //////
  if (response.statusCode == 200) {
    List<dynamic> jsonResponse = json.decode(response.body);
    print(jsonResponse[0]['AUTO_INCREMENT']);
    var res = jsonResponse[0]['AUTO_INCREMENT'];
    return res;
  } else {
    showSnackbar(context, "Error: "+ response.body.toString());
    return 0;
  }
}