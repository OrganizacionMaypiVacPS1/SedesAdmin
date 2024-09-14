import 'dart:convert';

import 'package:http/http.dart' as http;

class Carnetizador {
  late int id;

  late int id_Jefe_Brigada;

  Carnetizador({required this.id, required this.id_Jefe_Brigada});
}

final List<Carnetizador> cardholders = [
  Carnetizador(id: 3, id_Jefe_Brigada: 4),
  Carnetizador(id: 5, id_Jefe_Brigada: 4),
  Carnetizador(id: 6, id_Jefe_Brigada: 4),
];


