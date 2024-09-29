import 'package:admin/Models/Profile.dart';

class Config {
  static const String baseUrl = 'http://192.168.0.155:3000';
}

class RoleMember {
  static const int admin  = 5;
  static const int jefeBrigada  = 6;
  static const int carnetizador  = 7;
  static const int cliente  = 8;
}

Member superAdmin = new Member(names: 'admin', id: 0, role:'Admin', correo: 'admin',
    contrasena: 'admin', latitud: -66.1770384, longitud: -66.1770384);