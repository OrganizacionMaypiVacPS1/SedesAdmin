import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:admin/services/services_firebase.dart';

 

class Member {

  late String names;

  late String? lastnames;

  late DateTime? fechaNacimiento;

  late int id;

  late String? role;

  late String? contrasena; // Nuevo atributo

  late String correo;

  late int? telefono;

  late String? carnet;

  late double longitud;

  late double latitud;

  late DateTime? fechaCreacion;

  late int? status;

  // Nuevo atributo

 

  Member(

      {required this.names,

      this.lastnames,

      this.fechaNacimiento,

      required this.id,

      this.role,

      this.contrasena, // Nuevo atributo

      required this.correo, // Nuevo atributo

      this.telefono,

      this.carnet,

      required this.latitud,

      required this.longitud,

      this.fechaCreacion,

      this.status});

 

  factory Member.fromJson2(Map<String, dynamic> json) {

    final result = json['result'];

    return Member(

      names: result['Nombres'],

      id: result['idPerson'],

      correo: result['Correo'],

      latitud: result['Latitud'],

      longitud: result['Longitud'],

      fechaCreacion: result['FechaCreacion'] != null

          ? DateTime.parse(result['FechaCreacion'])

          : null,

    );

  }

 

  factory Member.fromJson(Map<String, dynamic> json) {

    return Member(

        id: json['idPerson'],

        names: json['Nombres'],

        lastnames: json['Apellidos'],

        fechaNacimiento: DateTime.parse(json['FechaNacimiento']),

        correo: json['Correo'],

        contrasena: json['Password'],

        carnet: json['Carnet'],

        telefono: json['Telefono'],

        fechaCreacion: DateTime.parse(json['FechaCreacion']),

        status: json['Status'],

        longitud: json['Longitud'],

        latitud: json['Latitud'],

        role: json['NombreRol']);

  }

 

  

}

