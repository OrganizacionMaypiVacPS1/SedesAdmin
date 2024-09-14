import 'dart:convert';

import 'package:admin/Models/Profile.dart';
import 'package:admin/services/Config.dart';
import 'package:http/http.dart' as http;
import 'package:admin/services/services_firebase.dart';

  Future<List<Member>> fetchMembers() async {
    final response = await http.get(
        Uri.parse(Config.baseUrl+'/allaccounts'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final members =
          data.map((memberData) => Member.fromJson(memberData)).toList();
      return members;
    } else {
      throw Exception('Failed to load members');
    }
  }

    Future<Member?> fetchMemberById(int memberId) async {
    final url =
        Uri.parse(Config.baseUrl+'/userbyid?idUser=$memberId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final member = Member.fromJson(data);
      return member;
    } else {
      return null;
    }
  }

  Future<Member> getCardByUser(int id) async {

  final response = await http.get(Uri.parse(

      Config.baseUrl+'/cardholderbyuser/' + id.toString()));

 

  if (response.statusCode == 200) {

    final data = json.decode(response.body);

    final member = Member.fromJson(data);

    return member;

  } else {

    throw Exception('Failed to load members');

  }

}

Future<void> deleteAccount(int id) async {
  final accountJson = json.encode({'idPerson': id});
  final response = await http.put(
    Uri.parse(Config.baseUrl+'/accountdelete'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: accountJson,
  );

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception(response);
  }
  members=fetchMembers();

}

  Future<bool> validate(String code, int userId) async {
    final url = Uri.parse(
        Config.baseUrl+'/validateCode?userId=$userId&code=$code');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['success']; // Debe devolver true si el código es válido
    } else {
      throw Exception('Error al validar el código OTP');
    }
  }

  Future<bool> changePassword(int userId, String newPassword) async {
    final url = Uri.parse(Config.baseUrl+'/changePassword');

    final response = await http.put(
      url,
      body: json.encode({
        'userId': userId,
        'newPassword': newPassword,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data[
          'success']; // Debe devolver true si la contraseña se cambió con éxito
    } else {
      throw Exception('Error al cambiar la contraseña');
    }
  }

  

 

