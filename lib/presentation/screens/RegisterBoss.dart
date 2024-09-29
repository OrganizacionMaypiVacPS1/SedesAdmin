import 'dart:io';
import 'package:admin/Implementation/CardholderImp.dart';
import 'package:admin/Implementation/ProfileImp.dart';
import 'package:admin/Models/Cardholder.dart';
import 'package:admin/presentation/screens/List_members.dart';
import 'package:admin/Config/Config.dart';
import 'package:admin/services/services_firebase.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:admin/Models/Profile.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'Campaign.dart';
import 'LocationPicker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

Image? image;
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: RegisterBossPage(
        isUpdate: false,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class RegisterBossPage extends StatefulWidget {
  final Member? userData;
  late final bool isUpdate;

  RegisterBossPage({required this.isUpdate, this.userData});
  @override
  _RegisterBossPageState createState() => _RegisterBossPageState();
}

class _RegisterBossPageState extends State<RegisterBossPage> {
  final _formKey = GlobalKey<FormState>();
  String nombre = '';
  String apellido = '';
  var datebirthday;
  var dateCreation;
  String carnet = '';
  String telefono = '';
  String? selectedRole = 'Administrador';
  String latitude = '';
  String longitude = '';
  String email = '';
  String password = '';
  int status = 1;
  int? idRolSeleccionada;
  String nameJefe = "";
  int idJefe = 0;
  int idPerson = 0;
  Member? jefeDeCarnetizador;
  late String imageBase64;
  String locationName = ''; // Esta variable almacenará la dirección
  late img.Image decodedImage =
      img.Image(1, 1); // Inicialización con una imagen en blanco4
  late img.Image image = img.Image(1, 1);
  late Image flutterImage;
  File? selectedImageFile;
  late bool otherUser = false;
  File? selectedImage;
  bool isLoadingImage=true;
  String address="";
  File? imageLocal;
  GoogleMapController? _controller;

  void initState() {
    super.initState();

    if(widget.isUpdate==false){
      setState(() {
        isLoadingImage=false;
      });
    }
/*
    if(miembroActual!.id!=widget.userData?.id){
      imageProfile=null;
    }*/
    if (widget.userData?.id != null) {
      Cargar_Datos_Persona();
      if(imageProfile==null||miembroActual!.id!=widget.userData?.id){
        addImageToSelectedImages(widget.userData!.id);
      }else{
        imageLocal = imageProfile;
        isLoadingImage=false;
      }
      flutterImage = imagePath != null ? Image.file(File(imagePath!)) : Image.asset('assets/usuario.png');
      if (miembroActual?.id != widget.userData?.id) {
        otherUser = true;
      }
    }
  }

  @override
  void dispose(){
    esCarnetizador=false;
    imageLocal=null;
    super.dispose();
    
  }

    Future<void> addImageToSelectedImages(int idPerson) async {
  try {
    String imageUrl = await getImageUrl(idPerson);
    File tempImage = await _downloadImage(imageUrl);
    
    setState(() {
      imageLocal = tempImage;
      isLoadingImage=false;
    });
  } catch (e) {
    print('Error al obtener y descargar la imagen: $e');
    setState(() {
      isLoadingImage=false;
    });
  }
}

Future<String> getImageUrl(int idPerson) async {
  try {
    Reference storageRef = FirebaseStorage.instance.ref('cliente/$idPerson/imagenUsuario.jpg');
    return await storageRef.getDownloadURL();
  } catch (e) {
    print('Error al obtener URL de la imagen: $e');
    throw e;
  }
}

Future<File> _downloadImage(String imageUrl) async {
  final response = await http.get(Uri.parse(imageUrl));

  if (response.statusCode == 200) {
    final bytes = response.bodyBytes;
    final tempDir = await getTemporaryDirectory();
    final tempImageFile = File('${tempDir.path}/${DateTime.now().toIso8601String()}.jpg');
    await tempImageFile.writeAsBytes(bytes);
    return tempImageFile;
  } else {
    throw Exception('Error al descargar imagen');
  }
}

    Future<bool> uploadImage(File? image, int userId) async {
    try {
      if(widget.isUpdate==false){
        userId = await getNextIdPerson(context);
      }
      
      final firebase_storage.Reference storageRef =
          firebase_storage.FirebaseStorage.instance.ref();
      print("Ultimo ID =======" + "---" + idPerson.toString());
      String carpeta = 'cliente/$userId';

      if (image != null) {
        firebase_storage.Reference imageRef =
            storageRef.child('$carpeta/imagenUsuario.jpg');

        // Comprimir la imagen antes de subirla
        List<int> compressedBytes = await compressImage(image);

        await imageRef.putData(Uint8List.fromList(compressedBytes));
      }

      return true;
    } catch (e) {
      print('Error al subir la imagen: $e');
      return false;
    }
  }

    Future<List<int>> compressImage(File imageFile) async {
    // Leer la imagen
    List<int> imageBytes = await imageFile.readAsBytes();

    // Decodificar la imagen
    img.Image image = img.decodeImage(Uint8List.fromList(imageBytes))!;

    // Comprimir la imagen con una calidad específica (85 en este caso)
    List<int> compressedBytes = img.encodeJpg(image, quality: 85);

    return compressedBytes;
  }


  Future<void> deleteLocalImage() async {
    final file = File(imagePath!);
    if (await file.exists()) {
      await file.delete();
      print('Imagen local eliminada con éxito en $imagePath.');
    } else {
      print('La imagen local no existe en $imagePath.');
    }
  }

  Future<void> downloadBase64ImageAndSave(int imageId) async {
    final url = Uri.parse(Config.baseUrl+'/getImage?id=$imageId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final base64Image = data['imageString'];

      if (base64Image != null) {
        // Decodifica los datos base64 en bytes
        final Uint8List bytes = base64.decode(base64Image);

        // Obtiene la ruta del directorio de documentos
        final documentsDir = await getApplicationDocumentsDirectory();
        imagePath = '${documentsDir.path}/foto-perfil.png';

        // Elimina el archivo existente (si existe)
        await deleteLocalImage();

        // Escribe la nueva imagen
        await File(imagePath!).writeAsBytes(bytes);

        print('Imagen descargada y sobrescrita con éxito en $imagePath.');
      } else {
        print('No se pudo obtener la imagen base64 de la API.');
      }
    } else {
      print(
          'Error al descargar la imagen desde la API: ${response.statusCode}');
    }
  }

  void Cargar_Datos_Persona() async {
    idPerson = widget.userData!.id;
    nombre = widget.userData!.names;
    apellido = widget.userData!.lastnames!;
    datebirthday = widget.userData?.fechaNacimiento;
    dateCreation = widget.userData?.fechaCreacion;
    carnet = widget.userData!.carnet!;
    telefono = widget.userData!.telefono.toString();
    selectedRole = widget.userData!.role;

    latitude = widget.userData!.latitud.toString();
    longitude = widget.userData!.longitud.toString();
    email = widget.userData!.correo;
    address = await getAddressFromLatLng(
      widget.userData!.latitud,
      widget.userData!.longitud,
      'AIzaSyBaqF8pGcAaGUm7oE3KbHWsjUfBdCEBujM',
    );
    locationName = address;
    
    if (esCarnetizador) {
      jefeDeCarnetizador = await getCardByUser(widget.userData!.id);
      nameJefe = jefeDeCarnetizador!.names;
      idJefe = jefeDeCarnetizador!.id;
    }
    if(mounted)
    setState(() {});
  }

  Future<void> registerUser() async {
    final url = Uri.parse(Config.baseUrl+'/register');
    if (selectedRole == 'Administrador') {
      idRolSeleccionada = RoleMember.admin;
    } else if (selectedRole == 'Jefe de Brigada') {
      idRolSeleccionada = RoleMember.jefeBrigada;
    } else if (selectedRole == 'Carnetizador') {
      idRolSeleccionada = RoleMember.carnetizador;
    } else if (selectedRole == 'Cliente'){
      idRolSeleccionada= RoleMember.cliente;
    }
    String md5Password = md5.convert(utf8.encode(password)).toString();
    final response = await http.post(
      url,
      body: jsonEncode({
        'Nombres': nombre,
        'Apellidos': apellido,
        'FechaNacimiento': datebirthday.toIso8601String(),
        'FechaCreacion': dateCreation.toIso8601String(),
        'Carnet': carnet,
        'Telefono': telefono,
        'IdRol': idRolSeleccionada,
        'Latitud': latitude,
        'Longitud': longitude,
        'Correo': email,
        'Password': md5Password,
        'Status': status,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      // Registro exitoso
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar el usuario')),
      );
    }
  }

  Future<void> updateUser() async {
    final url = Uri.parse(
        Config.baseUrl+'/update/' + idPerson.toString()); //
    if (selectedRole == 'Administrador') {
      idRolSeleccionada = RoleMember.admin;
    } else if (selectedRole == 'Jefe de Brigada') {
      idRolSeleccionada = RoleMember.jefeBrigada;
    } else if (selectedRole == 'Carnetizador') {
      idRolSeleccionada = RoleMember.carnetizador;
    } else if (selectedRole == 'Cliente'){
      idRolSeleccionada= RoleMember.cliente;
    }
    final response = await http.put(
      url,
      body: jsonEncode({
        'id': idPerson,
        'Nombres': nombre,
        'Apellidos': apellido,
        'FechaNacimiento': datebirthday.toIso8601String(),
        'Carnet': carnet,
        'Telefono': telefono,
        'IdRol': idRolSeleccionada,
        'Latitud': latitude,
        'Longitud': longitude,
        'Correo': email,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      // Registro exitoso
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al Actualizar el usuario')),
      );
    }

    if (miembroActual!.id == widget.userData!.id) {
      miembroActual!.names = nombre;
      miembroActual!.lastnames = apellido;
      miembroActual!.fechaNacimiento = datebirthday;
      miembroActual!.carnet = carnet;
      miembroActual!.telefono = int.parse(telefono);
      miembroActual!.role = selectedRole!;
      miembroActual!.latitud = double.parse(latitude);
      miembroActual!.longitud = double.parse(longitude);
      miembroActual!.correo = email;
    }
  }

  Future<void> registerJefeCarnetizador() async {
    final url =
        Uri.parse(Config.baseUrl+'/registerjefecarnetizador');

    final response = await http.post(
      url,
      body: jsonEncode({
        'idPerson': idPerson, //

        'idJefeCampaña': idJefe,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      // Registro exitoso
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar el usuario')),
      );
    }
  }

  Future<String> getAddressFromLatLng(
      double lat, double lng, String apiKey) async {
    final url = Uri.https(
      'maps.googleapis.com',
      '/maps/api/geocode/json',
      {'latlng': '$lat,$lng', 'key': apiKey},
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['status'] == 'OK' && json['results'].isNotEmpty) {
        return json['results'][0]['formatted_address'];
      }
    }

    return 'No se pudo obtener la dirección';
  }

  Future<void> updateJefeCarnetizador() async {
    final url = Uri.parse(Config.baseUrl+'/updatejefecarnetizador');

    final response = await http.put(
      url,
      body: jsonEncode({
        'idPerson': idPerson, //

        'idJefeCampaña': idJefe,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      // Registro exitoso
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar el usuario Carnetizador')),
      );
    }
  }

  Future<void> Permisos() async {
    LocationPermission permiso;
    permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        return Future.error('Error');
      }
    }
  }

  Future<String> optimizeImage(String base64String, int maxSizeKB) async {
    int currentQuality = 100; // Calidad inicial al 100%
    int maxTries = 10; // Número máximo de intentos de compresión
    String optimizedBase64 = base64String;

    while (optimizedBase64.length > (maxSizeKB * 1024) &&
        currentQuality > 0 &&
        maxTries > 0) {
      // Decrementa la calidad en 10 unidades (ajusta según tus necesidades)
      currentQuality -= 10;

      // Decodifica la imagen desde Base64
      final decodedImage =
          img.decodeImage(Uint8List.fromList(base64Decode(optimizedBase64)))!;

      // Reduce la calidad de la imagen
      final compressedBase64 =
          base64Encode(img.encodeJpg(decodedImage, quality: currentQuality));

      // Actualiza la imagen optimizada
      optimizedBase64 = compressedBase64;

      maxTries--; // Reduce el número de intentos
    }

    return optimizedBase64;
  }

  Future<void> handleCameraAndImageProcessing(final pickedFile) async {
    if (pickedFile != null) {
      // Carga la imagen desde el archivo
      final File imageFile = File(pickedFile.path);

      // Realiza el procesamiento de la imagen
      final bytes = await imageFile.readAsBytes();
      img.Image image = img.decodeImage(Uint8List.fromList(bytes))!;

      image = img.copyResize(image, width: 720);

      // Convierte la imagen a Base64
      final imageBytes = img.encodeJpg(image, quality: 60);
      final base64String = base64Encode(imageBytes);

      // Optimiza la imagen antes de guardarla
      imageBase64 = await optimizeImage(base64String, 100);

      // Asegúrate de que imageBase64 tenga los datos correctos antes de usarlos
      if (imageBase64.isNotEmpty) {
        // Aquí puedes continuar con el envío de imageBase64 a tu base de datos
        // También puedes llamar a updatePersonaImage() aquí para actualizar la imagen en la base de datos.
      } else {
        // Maneja la situación en la que la conversión a Base64 no fue exitosa
        print('Error al convertir la imagen a Base64');
      }
    }
  }

  Future<void> updatePersonaImage() async {
    final url = Uri.parse(Config.baseUrl+'/Apersonaimage/$idPerson');
    final Map<String, dynamic> requestData = {
      'IdImagen': imageBase64,
    };

    final response = await http.put(
      url,
      body: jsonEncode(requestData),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      // La actualización fue exitosa
      print('Actualización exitosa');
    } else {
      // Manejar errores aquí
      print('Error en la actualización: ${response.statusCode}');
    }
  }

  Future<void> validarPersonaEnBaseDeDatos() async {
    final idPersona = idPerson; // Ajusta esto según tus necesidades
    final url = Uri.parse(Config.baseUrl+'/personaimage/$idPersona');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData.isNotEmpty) {
        // La persona existe en la base de datos, puedes abrir un diálogo para seleccionar una imagen.

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Selecciona una imagen"),
              actions: <Widget>[
                TextButton(
                  child: Text("Galería"),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    final pickedFile = await ImagePicker.platform
                        .pickImage(source: ImageSource.gallery);

                    if (pickedFile != null) {
                      setState(() {
                        selectedImageFile = File(pickedFile.path);
                      });
                      await handleCameraAndImageProcessing(pickedFile);
                    }
                  },
                ),
                TextButton(
                  child: Text("Cámara"),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    final pickedFile = await ImagePicker.platform
                        .pickImage(source: ImageSource.camera);

                    if (pickedFile != null) {
                      // Aquí puedes manejar la imagen capturada desde la cámara.
                      setState(() {
                        selectedImageFile = File(pickedFile.path);
                      });
                      await handleCameraAndImageProcessing(pickedFile);
                    }
                  },
                ),
              ],
            );
          },
        );
      } else {
        // La persona no existe, realiza la inserción en la base de datos.
        final insertUrl = Uri.parse(Config.baseUrl+'/InsIdEnImagen');
        final insertResponse = await http.post(
          insertUrl,
          body: jsonEncode({'IdPersona': idPersona}),
          headers: {'Content-Type': 'application/json'},
        );

        if (insertResponse.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('La persona se insertó en la base de datos')),
          );
          // Aquí puedes abrir la cámara después de la inserción exitosa.
        }
      }
    }
  }

Future<void> _getImageFromGallery() async {
  final picker = ImagePicker();
  final pickedImage = await picker.pickImage(source: ImageSource.gallery);

  if (pickedImage != null) {
    File imageFile = File(pickedImage.path);

    img.Image? image = img.decodeImage(imageFile.readAsBytesSync());

    if (image != null) {
      image = img.bakeOrientation(image);
      await imageFile.writeAsBytes(img.encodeJpg(image));
    }

    setState(() {
      imageLocal = imageFile;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    final title = widget.isUpdate
        ? 'Actualizar Usuario'
        : 'Registrar Usuario'; // Título dinámico

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 92, 142, 203),
        title: Text(title,
            style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.arrow_back,
                color: Color.fromARGB(255, 255, 255, 255)),
            onPressed: () {
              esCarnetizador = false;
              Navigator.pop(context);
            },
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Column(
                children: <Widget>[
                  Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      imageLocal!=null ?InkWell(
                        onTap: () {
                          showPicker(context, (File file) {
                            setState(() {
                              imageLocal = file;
                            });
                          });
                        },
                        child: CircleAvatar(
                          backgroundImage: FileImage(imageLocal!),
                          radius: 100,
                          child: null,
                        ),
                      ): InkWell(
                        onTap: () {
                          showPicker(context, (File file) {
                            setState(() {
                              imageLocal = file;
                            });
                          });
                        },
                        child: Stack(
                          children: [
                            CircleAvatar(
                              backgroundImage: null,
                              radius: 100,
                              child: isLoadingImage ? null : Icon(Icons.camera_alt, size: 50.0),
                            ),
                            if (isLoadingImage)
                              Positioned.fill(
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  alignment: Alignment.center,
                                  child: SizedBox(
                                    width: 60, 
                                    height: 60, 
                                    child: SpinKitCircle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      ),
                      SizedBox(height: 20),
                      selectedImageFile != null
                          ? Image.file(
                              selectedImageFile!,
                              height: 200,
                              width: 200,
                            )
                          : Container(),
                    ],
                  ),
                ),
                  /*if (!otherUser && widget.isUpdate)
                    Center(
                      child: Column(
                        children: [
                          Container(
                            margin: EdgeInsets.only(
                                bottom:
                                    10), // Agrega margen solo en la parte inferior
                            child: CircleAvatar(
                              radius: 60,
                              backgroundImage: selectedImageFile != null
                                  ? FileImage(selectedImageFile!)
                                  : flutterImage.image,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await validarPersonaEnBaseDeDatos();
                            },
                            child: Text('Seleccione/Cambie foto de perfil',
                                style: TextStyle(
                                    color: Color(
                                        0xFF4D6596))), // Cambia el color del texto
                            style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.all(Colors.white),
                              elevation: MaterialStateProperty.all(0),
                              shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: Color(0xFF4D6596),
                                    width: 2.0,
                                  ),
                                ),
                              ),
                              minimumSize: MaterialStateProperty.all(
                                  Size(double.infinity, 50)),
                            ),
                          ),
                        ],
                      ),
                    ),*/
                ],
              ),
              _buildTextField(
                initialData: nombre,
                label: 'Nombres',
                onChanged: (value) => nombre = value,
                validator: (value) =>
                    value!.isEmpty ? 'El nombre no puede estar vacío.' : null,
                icon: Icons.person,
              ),
              _buildTextField(
                initialData: apellido,
                label: 'Apellidos',
                onChanged: (value) => apellido = value,
                validator: (value) =>
                    value!.isEmpty ? 'El nombre no puede estar vacío.' : null,
                icon: Icons.person,
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.date_range, // Cambia esto al icono que prefieras
                    color: Color.fromARGB(255, 92, 142, 203),
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Fecha Nacimiento",
                    style: TextStyle(color: Color.fromARGB(255, 92, 142, 203)),
                  ),
                ],
              ),
              _buildDateOfBirthField(
                label: 'Fecha Nacimiento',
                onChanged: (value) => datebirthday = value,
              ),
              _buildTextField(
                  initialData: carnet,
                  label: 'Carnet de identidad',
                  onChanged: (value) => carnet = value,
                  validator: (value) =>
                      value!.isEmpty ? 'El carnet no puede estar vacío.' : null,
                  icon: Icons.badge),
              _buildTextField(
                initialData: telefono,
                label: 'Teléfono',
                onChanged: (value) => telefono = value,
                validator: (value) =>
                    value!.isEmpty ? 'El Teléfono no puede estar vacía.' : null,
                icon: Icons.call,
                keyboardType: TextInputType.number,
              ),
              if(widget.userData==null||widget.userData!.id!=6)
              widget.userData==null?
              Row(children: [
                Icon(
                  Icons.list_alt, // Cambia esto al icono que prefieras
                  color: Color.fromARGB(255, 92, 142, 203),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: widget.userData==null? DropdownButton<String>(
                    hint: Text('Rol',
                        style: TextStyle(
                            color: Color.fromARGB(255, 92, 142, 203))),
                    value: selectedRole,
                    dropdownColor: Colors.grey[850],
                    style: TextStyle(color: Color.fromARGB(255, 92, 142, 203)),
                    items: <String>[
                      'Jefe de Brigada',
                      'Carnetizador',
                      'Administrador'
                    ].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedRole = newValue!;
                        if (newValue == "Carnetizador") {
                          esCarnetizador = true;
                        } else {
                          esCarnetizador = false;
                        }
                      });
                    },
                  ):Container(),
                )
              ]):Container(),
              esCarnetizador
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.hail, // Cambia esto al icono que prefieras
                              color: Color.fromARGB(255, 92, 142, 203),
                            ),
                            SizedBox(width: 10),
                            Text(
                              "Seleccionar Jefe",
                              style: TextStyle(
                                  color: Color.fromARGB(255, 92, 142, 203)),
                            ),
                          ],
                        ),
                        Container(
                          width: double.infinity,
                          child: ElevatedButton(
                            child:
                                Text(nameJefe == '' ? "Seleccionar" : nameJefe, style: TextStyle(color: Colors.black),),
                            onPressed: () async {
                              esCarnetizador = true;

                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ListMembersScreen()),
                              );

                              if (result != null) {
                                jefeDeCarnetizador = result;
                                nameJefe = jefeDeCarnetizador!.names;
                                idJefe = jefeDeCarnetizador!.id;
                              }
                              setState(() {});
                            },
                            style: ButtonStyle(
                              minimumSize: MaterialStateProperty.all(
                                  Size(double.infinity, 55)), // Adjust the height as needed
                              backgroundColor:
                                  MaterialStateProperty.all(Colors.white), // Fondo blanco
                              elevation: MaterialStateProperty.all(0), // Sin sombra
                              shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10), // Borde redondeado
                                  side: BorderSide(
                                    color: Color.fromARGB(
                                        255, 92, 142, 203), // Color del borde
                                    width: 2.0, // Ancho del borde
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(),
              SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.location_on, // Cambia esto al icono que prefieras
                    color: Color.fromARGB(255, 92, 142, 203),
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Dirección",
                    style: TextStyle(color: Color.fromARGB(255, 92, 142, 203)),
                  ),
                ],
              ),
              ElevatedButton(
                child: Text(
                  "Selecciona una ubicación",
                  style: TextStyle(
                    color: Colors.black, // Color del texto
                  ),
                ),
                onPressed: () async {
                  await Permisos();
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LocationPicker(),
                    ),
                  );
                  if (result != null) {
                    address = await getAddressFromLatLng(
                      result.latitude,
                      result.longitude,
                      'AIzaSyBaqF8pGcAaGUm7oE3KbHWsjUfBdCEBujM',
                    );
                    setState(() {
                      latitude = result.latitude.toString();
                      longitude = result.longitude.toString();
                      locationName = address;
                    });
                  }
                },
                style: ButtonStyle(
                  minimumSize: MaterialStateProperty.all(
                      Size(double.infinity, 55)), // Adjust the height as needed
                  backgroundColor:
                      MaterialStateProperty.all(Colors.white), // Fondo blanco
                  elevation: MaterialStateProperty.all(0), // Sin sombra
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10), // Borde redondeado
                      side: BorderSide(
                        color: Color.fromARGB(
                            255, 92, 142, 203), // Color del borde
                        width: 2.0, // Ancho del borde
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Text(
                  locationName,
                  style: TextStyle(color: Color.fromARGB(255, 92, 142, 203)),
                ),
              ),
              _buildTextField(
                initialData: email,
                label: 'Email',
                onChanged: (value) => email = value,
                validator: (value) =>
                    value!.isEmpty ? 'El email no puede estar vacío.' : null,
                icon: Icons.mail,
                keyboardType: TextInputType.emailAddress,
              ),
              widget.isUpdate
                  ? Container()
                  : _buildTextField(
                      initialData: "",
                      label: 'Contraseña',
                      onChanged: (value) => password = value,
                      obscureText: true,
                      icon: Icons.password),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  dateCreation = DateTime.now();
                  status = 1;
                  if (esCarnetizador &&
                      _formKey.currentState!.validate() &&
                      latitude != '' &&
                      selectedRole != '' &&
                      datebirthday != null &&
                      nameJefe != '') {
                    if (widget.isUpdate) {
                      await showLoadingDialog(context, () async{
                        await updateUser();
                        await updateJefeCarnetizador();
                        //await updatePersonaImage();
                        if(idPerson==miembroActual!.id){
                        imageProfile = imageLocal;}
                        await uploadImage(imageLocal, idPerson);
                        //await downloadBase64ImageAndSave(idPerson);
                        //closeLoadingDialog(context);

                      });
                      showSnackbar(context, "Actualización Completado");
                      Navigator.pop(context);
                      //Mostrar_Finalizado(context, "Actualización Completado");
                    } else if (password != "") {
                      await showLoadingDialog(context, () async{
                        dateCreation = DateTime.now();
                        status = 1;
                        await registerUser();
                        idPerson = await getNextIdPerson(context);
                        await registerJefeCarnetizador();
                        if(idPerson==miembroActual!.id){
                        imageProfile = imageLocal;}
                        await uploadImage(imageLocal, idPerson);
                        //closeLoadingDialog(context);

                      });
                      showSnackbar(context, "Registro Completado");
                      Navigator.pop(context);
                      //Mostrar_Finalizado(context, "Registro Completado");
                    }
                    esCarnetizador = false;
                  } else {
                    if (esCarnetizador == false &&
                        _formKey.currentState!.validate() &&
                        latitude != '' &&
                        selectedRole != '' &&
                        datebirthday != null) {
                      if (widget.isUpdate) {
                        await showLoadingDialog(context, () async{
                          await updateUser();
                          //await updatePersonaImage();
                          if(idPerson==miembroActual!.id){
                          imageProfile = imageLocal;}
                          await uploadImage(imageLocal, idPerson);
                          //await downloadBase64ImageAndSave(idPerson);
                          //closeLoadingDialog(context);
                          
                        });
                        showSnackbar(context, "Actualización Completado");
                        Navigator.pop(context);

                        //Mostrar_Finalizado(context, "Actualización Completado");
                      } else if (password != "") {
                        await showLoadingDialog(context, () async{
                          dateCreation = DateTime.now();
                          status = 1;
                          await registerUser();
                          if(idPerson==miembroActual!.id){
                          imageProfile = imageLocal;}
                          await uploadImage(imageLocal, idPerson);
                          //closeLoadingDialog(context);

                        });
                        showSnackbar(context, "Registro Completado");
                        Navigator.pop(context);
                        //Mostrar_Finalizado(context, "Registro Completado");
                      }

                      esCarnetizador = false;
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Ingrese todos los campos')),
                      );
                    }
                  }
                },
                child: Text(
                  widget.isUpdate ? 'Actualizar' : 'Registrar',
                  style: TextStyle(
                      color: Color.fromARGB(
                          255, 92, 142, 203)), // Cambia el color del texto
                ),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.white),
                  elevation: MaterialStateProperty.all(0),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: Color.fromARGB(255, 92, 142, 203),
                        width: 2.0,
                      ),
                    ),
                  ),
                  minimumSize:
                      MaterialStateProperty.all(Size(double.infinity, 50)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateOfBirthField({
    required String label,
    required Function(DateTime?) onChanged,
  }) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white, // Fondo blanco
            borderRadius: BorderRadius.circular(10), // Borde redondeado
            border: Border.all(
              color: Color.fromARGB(255, 92, 142, 203), // Color del borde
              width: 2.0, // Ancho del borde
            ),
          ),
          child: ElevatedButton(
            onPressed: () async {
              datebirthday = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );

              if (datebirthday != null) {
                onChanged(datebirthday);
                setState(() {});
              }
            },
            child: Text(
              datebirthday != null
                  ? "${datebirthday.day}/${datebirthday.month}/${datebirthday.year}"
                  : label,
              style: TextStyle(
                color: Colors.black,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent, // Fondo transparente
              elevation: 0, // Sin sombra
            ),
          ),
        ),
        SizedBox(height: 15),
      ],
    );
  }

  Widget _buildTextField({
    required String initialData,
    required String label,
    required Function(String) onChanged,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    IconData? icon, // El IconData del icono que deseas agregar
  }) {
    return Column(
      children: [
        Row(
          children: [
            if (icon != null)
              // Verifica si se proporcionó un icono
              Padding(
                padding: const EdgeInsets.all(
                    0), // Ajusta el espacio según sea necesario
                child: Icon(
                  icon,
                  color: Color.fromARGB(255, 92, 142,
                      203), // Establece el color del icono como blanco
                ),
              ),
            Expanded(
              child: TextFormField(
                initialValue: initialData,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle:
                      TextStyle(color: Color.fromARGB(255, 92, 142, 203)),
                ),
                onChanged: onChanged,
                validator: validator,
                keyboardType: keyboardType,
                obscureText: obscureText,
              ),
            ),
          ],
        ),
        SizedBox(height: 15),
      ],
    );
  }
}
