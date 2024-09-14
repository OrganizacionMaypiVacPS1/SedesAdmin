class EUbication {
  final String name;
  final String latitude;
  final String longitude;

  EUbication({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  // Convertir a Json
  Map<String, dynamic> toJson() => {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
      };
}
