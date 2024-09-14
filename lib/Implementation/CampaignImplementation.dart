import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:admin/services/Config.dart';
import 'package:admin/services/services_firebase.dart';
import 'package:admin/Models/CampaignModel.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

Future<List<Campaign>> fetchCampaigns(BuildContext context) async {
  try{
      final response =
      await http.get(Uri.parse(Config.baseUrl+'/campanas'));
    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Campaign.fromJson(data)).toList();
    } else {
      showSnackbar(context, "Error: fallo al obtener Campañas");
      return [];
    }
  }catch (e){
    showSnackbar(context, "Error: " + e.toString());
    return [];
    
  }

}

Future<int> getNextIdCampana(BuildContext context) async {
  final response = await http
      .get(Uri.parse(Config.baseUrl+'/nextidcampanas')); //////
  if (response.statusCode == 200) {
    List<dynamic> jsonResponse = json.decode(response.body);
    print(jsonResponse[0]['AUTO_INCREMENT']);
    var res = jsonResponse[0]['AUTO_INCREMENT'];
    return res;
  } else {
    showSnackbar(context, "Error: fallo al obtener siguiente id Campaña");
    return 0;
  }
}

Future<Widget> loadProfileImage() async {
  final directory = await getTemporaryDirectory();
  final filePath = '${directory.path}/foto-perfil.png';

  if (await File(filePath).exists()) {
    final bytes = await File(filePath).readAsBytes();
    final image = img.decodeImage(Uint8List.fromList(bytes));

    if (image != null) {
      return CircleAvatar(
        backgroundImage: MemoryImage(Uint8List.fromList(bytes)),
        radius: 30,
      );
    }
  }

  // Si la imagen no está disponible, usa una imagen de respaldo
  return CircleAvatar(
    backgroundImage: AssetImage('assets/perritoProfile.png'),
    radius: 30,
  );
}

Future<void> registerNewCampaign(BuildContext context, Campaign newCampaign) async {
  // Convertir tu objeto Campaign a JSON.
  final campaignJson = json.encode({
//'idCampañas': newCampaign.id,
    'NombreCampaña': newCampaign.nombre,
    'Descripcion': newCampaign.descripcion,
    'Categoria': newCampaign.categoria,
    'FechaInicio': newCampaign.dateStart.toString(),
    'FechaFinal': newCampaign.dateEnd.toString(),
    'userId': newCampaign.userId
  });
  final response = await http.post(
    Uri.parse(Config.baseUrl+'/campanas'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: campaignJson,
  );
  if (response.statusCode != 200 && response.statusCode != 201) {
    showSnackbar(context, "Error: "+ response.body.toString());
  }
  campaigns.add(newCampaign);
}

Future<void> updateCampaignById(BuildContext context, Campaign updatedCampaign) async {
  // Convertir tu objeto Campaign a JSON.
  var id = updatedCampaign.id;
  final campaignJson = json.encode({
    'idCampañas': updatedCampaign.id,
    'NombreCampaña': updatedCampaign.nombre,
    'Descripcion': updatedCampaign.descripcion,
    'Categoria': updatedCampaign.categoria,
    'FechaInicio': updatedCampaign.dateStart.toString(),
    'FechaFinal': updatedCampaign.dateEnd.toString(),
    'userId': updatedCampaign.userId
  });
  final response = await http.put(
    Uri.parse(Config.baseUrl+'/campanas/$id'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: campaignJson,
  );

  if (response.statusCode != 200 && response.statusCode != 201) {
    showSnackbar(context, "Error: "+ response.body.toString());
  }
  // Actualizar el objeto Campaign en tu lista local.
  int index = campaigns.indexWhere((campaign) => campaign.id == id);
  if (index != -1) {
    campaigns[index] = updatedCampaign;
  }
}

Future<void> deleteCampaignById(BuildContext context, int id, int userId) async {
  // Convertir tu objeto Campaign a JSON.
  final campaignJson = json.encode({'idCampañas': id, 'userId': userId});
  final response = await http.put(
    Uri.parse(Config.baseUrl+'/campanas/delete/$id'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: campaignJson,
  );

  if (response.statusCode != 200 && response.statusCode != 201) {
    showSnackbar(context, "Error: "+ response.body.toString());
  }
  // Actualizar el objeto Campaign en tu lista local.
  int index = campaigns.indexWhere((campaign) => campaign.id == id);
  if (index != -1) {
    campaigns.removeAt(index);
  }
}
