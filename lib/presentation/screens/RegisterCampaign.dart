import 'package:admin/Implementation/CampaignImplementation.dart';
import 'package:admin/Models/CampaignModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'HomeClient.dart';
import 'package:admin/presentation/screens/Campaign.dart';
import 'package:admin/services/services_firebase.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';
import 'package:xml/xml.dart';
import 'dart:convert';
import 'package:admin/Models/Ubication.dart';

class RegisterCampaignPage extends StatefulWidget {
  final Campaign initialData;

  RegisterCampaignPage({Key? key, required this.initialData}) : super(key: key);

  @override
  _RegisterCampaignPageState createState() => _RegisterCampaignPageState();
}

class _RegisterCampaignPageState extends State<RegisterCampaignPage> {
  final _formKey = GlobalKey<FormState>();
  String nombre = '';
  String descripcion = '';
  String? categoria;
  String kml = '';
  List<EUbication> Ubicaciones = [];
  bool estaCargando = false;
  bool actualizar = false;
  var id;
  DateTime? dateStart = DateTime.now();
  DateTime? dateEnd = DateTime.now();
  TextEditingController _textController = TextEditingController();
  FocusNode _focusNode = FocusNode();

  String? nameMessage;
  String? descriptionMessage;
  String? categoryMessage;
  String? kmlMessage;
  String? dateMessage;

  DateTime currentDateInGMT4 = DateTime.now().toUtc().subtract(Duration(hours: 4));

  void initState() {
    super.initState();
    if (widget.initialData.nombre != "") {
      Cargar_Datos();
    }
  }

  void Cargar_Datos() {
    id = widget.initialData.id;
    actualizar = true;
    nombre = widget.initialData.nombre;
    descripcion = widget.initialData.descripcion;
    categoria = widget.initialData.categoria;
    dateStart = widget.initialData.dateStart;
    dateEnd = widget.initialData.dateEnd;
  }

  void Importar_Archivo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['kml'],
    );

    if (result != null) {
      var path = result.files.single.path;
      kml = result.files.single.name;
      if (path != null && File(path).existsSync()) {
        var fileBytes = File(path).readAsBytesSync();
        if (path.endsWith('.kml')) {
          var xmlDocument =
              XmlDocument.parse(const Utf8Decoder().convert(fileBytes));
          var placemarks = xmlDocument.findAllElements('Placemark');
          print(placemarks);
          for (var placemark in placemarks) {
            var lookAtElement =
                placemark.childElements.last.findElements('coordinates');

            var nameElement = placemark.findElements('name');
            String name = nameElement.isNotEmpty ? nameElement.first.text : '';
            String longitude;
            String latitude;
            for (var coordinatesElement in lookAtElement) {
              // Obtiene el contenido de texto de la etiqueta <coordinates>
              String coordinatesText = coordinatesElement.text;

              // Divide el texto por las comas
              List<String> splitCoordinates = coordinatesText.split(',');
              name = name.replaceAll('Ã³', 'ó');
              name = name.replaceAll('Vacunacion', 'Vacunación');
              name = name.replaceAll('vacunacion', 'Vacunación');
              name = name.replaceAll('VACUNACION', 'VACUNACIÓN');

              if (splitCoordinates.length >= 2) {
                longitude = splitCoordinates[0];
                latitude = splitCoordinates[1];
                Ubicaciones.add(EUbication(
                    name: name, latitude: latitude, longitude: longitude));
              }
            }
          }
        }
      }
      setState(() {
        // Validación del archivo KML
        if (kml.isEmpty) {
          kmlMessage = 'Debes cargar un archivo KML.';
        } else {
          kmlMessage = ' ';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 92, 142, 203),
        title: Text(actualizar ? 'Actualizar Actividad' : 'Registrar Actividad',
            style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.arrow_back,
                color: Color.fromARGB(255, 255, 255, 255)),
            onPressed: () {
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
              Center(
                child: Image.asset(
                  'assets/LogoNew.png',
                  height: 100,
                  width: 100,
                ), // Ajusta la ruta y las dimensiones según lo necesites
              ),
              Row(
                children: [
                  Icon(
                    Icons.holiday_village,
                    color: Color.fromARGB(255, 92, 142, 203),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        initialValue: nombre,
                        style:
                        TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Nombre de la Actividad',
                          labelStyle:
                          TextStyle(color: Color.fromARGB(255, 92, 142, 203)),
                          counterText: "${nombre.length}/50",
                          counterStyle: TextStyle(
                              color: Color.fromARGB(
                                  255, 92, 142, 203)), // Estilo del contador
                          // Contador de caracteres
                        ),
                        maxLength: 50, // Límite máximo de caracteres
                        onChanged: (value) {
                          setState(() {
                            nameMessage = (value.isEmpty) ? 'El nombre no puede estar vacío.' : null;
                            if (value.length > 50) {
                              nombre = value.substring(0, 50);
                            }else{
                              nombre = value;
                            }
                          });
                        },
                        keyboardType: TextInputType.multiline, // Teclado multilínea
                        maxLines: null, // Permite varias líneas de texto
                      ),
                      if (nameMessage != null)
                        Text(
                          nameMessage!,
                          style: TextStyle(
                            color: Color.fromARGB(255, 178, 42, 42),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Row(
                children: [
                  Icon(
                    Icons.description,
                    color: Color.fromARGB(255, 92, 142, 203),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          initialValue: descripcion,
                          style:
                          TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Descripción',
                            labelStyle:
                            TextStyle(color: Color.fromARGB(255, 92, 142, 203)),
                            counterText:
                            "${descripcion.length}/160", // Contador de caracteres
                            counterStyle:
                            TextStyle(color: Color.fromARGB(255, 92, 142, 203)),
                          ),
                          maxLength: 160, // Límite máximo de caracteres
                          onChanged: (value) {
                            setState(() {
                              descriptionMessage = (value.isEmpty) ? 'La descripción no puede estar vacía.' : null;
                              if (value.length > 160) {
                                descripcion = value.substring(0, 160);
                              } else {
                                descripcion = value;
                              }
                            });
                          },
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                        ),
                        if (descriptionMessage != null)
                          Text(
                            descriptionMessage!,
                            style: TextStyle(
                              color: Color.fromARGB(255, 178, 42, 42),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Row(
                children: [
                  Icon(
                    Icons.list_alt,
                    color: Color.fromARGB(255, 92, 142, 203),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButton<String>(
                          hint: Text(
                            'Selecciona un Tipo de Actividad',
                            style: TextStyle(color: Color.fromARGB(255, 92, 142, 203)),
                          ),
                          value: categoria,
                          dropdownColor: Colors.grey[850],
                          style: TextStyle(color: Color.fromARGB(255, 92, 142, 203)),
                          items: <String>[
                            'Vacuna',
                            'Carnetizacion',
                            'Control de Foco',
                            'Vacunación Continua',
                            'Rastrillaje'
                          ].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              categoria = newValue;
                              categoryMessage = null;
                            });
                          },
                        ),
                        if (categoryMessage != null)
                          Text(
                            categoryMessage!,
                            style: TextStyle(
                              color: Color.fromARGB(255, 178, 42, 42),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
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
                    "Fecha Inicio",
                    style: TextStyle(color: Color.fromARGB(255, 92, 142, 203)),
                  ),
                ],
              ),
              _buildDateOfBirthField(
                initialDate: dateStart,
                label: 'Fecha Inicio',
                onChanged: (value) {
                  setState(() {
                    dateStart = value;
                    ValidateDates();
                  });
                },
                fecha: dateStart,
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
                    "Fecha Final",
                    style: TextStyle(color: Color.fromARGB(255, 92, 142, 203)),
                  ),
                ],
              ),
              _buildDateOfBirthField(
                  initialDate: dateEnd,
                  label: 'Fecha Fin',
                  onChanged: (value) {
                    setState(() {
                      dateEnd = value;
                      ValidateDates();
                    });
                  },
                  fecha: dateEnd),
              if (dateMessage != null)
                Text(
                  dateMessage!,
                  style: TextStyle(
                    color: Color.fromARGB(255, 178, 42, 42),
                    fontSize: 12,
                  ),
                ),
              SizedBox(height: 15),
              ElevatedButton(
                onPressed: estaCargando ? null : Importar_Archivo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // Fondo blanco
                  foregroundColor:
                      Color.fromARGB(255, 92, 142, 203), // Color del texto
                  elevation: 0, // Sin sombra
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0), // Borde redondeado
                    side: BorderSide(
                      color: Color.fromARGB(255, 92, 142, 203), // Color del borde
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.cloud_upload,
                      color: Color.fromARGB(255, 92, 142, 203),
                    ),
                    SizedBox(width: 8), // Espacio entre el icono y el texto
                    Text(
                      'Importar KML',
                      style: TextStyle(color: Colors.black),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(kml,style:TextStyle(color: Color.fromARGB(255, 92, 142, 203))),
                ],
              ),
              // Mensaje de error para el archivo KML
              if (kmlMessage != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    kmlMessage!,
                    style: TextStyle(
                      color: Color.fromARGB(255, 178, 42, 42),
                      fontSize: 12,
                    ),
                  ),
                ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      if (actualizar &&
                          _formKey.currentState!.validate() &&
                          (dateStart!.isBefore(dateEnd!) ||
                              dateStart!.isAtSameMomentAs(dateEnd!))) {

                        await showLoadingDialog(context, () async {
                          Campaign updatedCampaign = Campaign(
                            id: id,
                            nombre: nombre,
                            descripcion: descripcion,
                            categoria: categoria!,
                            dateStart: dateStart!,
                            dateEnd: dateEnd!,
                            userId: miembroActual!.id);
                          await updateCampaignById(context, updatedCampaign); // Actualiza la campaña

                          if (kml != '') {
                            await Subir_Json_Firebase(id, Ubicaciones); // Sube el archivo KML
                            Ubicaciones.clear();
                          }

                        });
                        showSnackbar(context, "Se ha actualizado con éxito");
                        Navigator.pop(context, 1);
                        //Mostrar_Finalizado(
                           // context, "Se ha actualizado con éxito");
                      } else if ( nombre != '' &&
                          descripcion != '' &&
                          categoria != null &&
                          kml != '' &&
                          (dateStart!.isBefore(dateEnd!) ||
                              dateStart!.isAtSameMomentAs(dateEnd!))) {
                        //Registrar
                        await showLoadingDialog(context, () async{
                          Campaign newCampaign = Campaign(
                              id: 0,
                              nombre: nombre,
                              descripcion: descripcion,
                              categoria: categoria!,
                              dateStart: dateStart!,
                              dateEnd: dateEnd!,
                              userId: miembroActual!.id);
                          await registerNewCampaign(context, newCampaign);
                          int idNextCamp = await getNextIdCampana(context);
                          await Subir_Json_Firebase(idNextCamp, Ubicaciones);
                          Ubicaciones.clear();
                        });
                        showSnackbar(context, "Se ha registrado con éxito");
                        Navigator.pop(context, 1);

                      } else {
                        ValidateEmpty();
                        Mostrar_Error(context, "Ingrese todos los campos");
                      }
                    },
                    child: Text(actualizar ? 'Actualizar' : 'Registrar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 92, 142, 203),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if(actualizar){
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Eliminar Campaña?'),
                            content: Icon(Icons.warning,
                                color: Color(0xFF1A2946), size: 50),
                            actions: <Widget>[
                              TextButton(
                                child: Text('Cancelar',
                                    style: TextStyle(color: Colors.black)),
                                onPressed: () {
                                  Navigator.of(context).pop(0);
                                },
                              ),
                              TextButton(
                                child: Text('Eliminar',
                                    style: TextStyle(color: Color(0xFF1A2946))),
                                onPressed: () async {
                                  CampaignProvider().loadCampaigns();
                                  await deleteCampaignById(context, id, miembroActual!.id);
                                  await eliminarArchivoDeStorage(id);
                                  Mostrar_Finalizado(
                                      context, "Se ha Elminado con éxito");
                                  Navigator.of(context).pop(1);
                                },
                              ),
                            ],
                          );
                        },
                      );}
                      else{
                        Navigator.of(context).pop(0);
                      }
                    },
                    child: Text(actualizar?'Eliminar':'Cancelar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1A2946),
                    ),
                  ),
                ],
              ),
              if (estaCargando)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0), // Agrega padding a los costados
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        SizedBox(
                          height:
                              20.0, // Ajusta este valor según el grosor deseado para la barra
                          child: LinearProgressIndicator(
                            value: proceso,
                            backgroundColor: Colors.grey[200],
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        ),
                        SizedBox(height: 10),
                        Text('${(proceso! * 100).toStringAsFixed(1)}%'),
                      ],
                    ),
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
    DateTime? initialDate,
    DateTime? fecha,
  }) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white, // Fondo blanco
            border: Border.all(
              color: Color.fromARGB(255, 92, 142, 203), // Color del borde
            ),
            borderRadius: BorderRadius.circular(5.0), // Borde redondeado
          ),
          child: ElevatedButton(
            onPressed: () async {
              fecha = await showDatePicker(
                context: context,
                initialDate: initialDate ?? DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100), // Fecha futura permitida hasta el año 2100
              );

              if (fecha != null) {
                onChanged(fecha);
                setState(() {});
              }
            },
            child: Text(
              initialDate != null
                  ? "${initialDate.day}/${initialDate.month}/${initialDate.year}"
                  : label,
              style: TextStyle(color: Colors.black),
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

  void ValidateDates() {
    if ((dateEnd!.isAfter(dateStart!) || dateStart!.isAtSameMomentAs(dateEnd!))
        && !(DateTime(dateEnd!.year, dateEnd!.month, dateEnd!.day).isBefore
          (DateTime(currentDateInGMT4.year, currentDateInGMT4.month, currentDateInGMT4.day)))){
      dateMessage = null;
    }
    else{
      dateMessage = (DateTime(dateEnd!.year, dateEnd!.month, dateEnd!.day).isBefore
        (DateTime(currentDateInGMT4.year, currentDateInGMT4.month, currentDateInGMT4.day))) ?
       'No puede crear campañas finalizadas.' : 'Fecha Final debe de ser posterior o igual a inicio.';
    }
  }

  void ValidateEmpty(){
    if (nombre == '') {
      setState(() {
        nameMessage = 'El nombre no puede estar vacío.';
      });
    }
    if (descripcion == '') {
      setState(() {
        descriptionMessage = 'La descripción no puede estar vacía.';
      });
    }
    if (categoria == null) {
      setState(() {
        categoryMessage = 'Debe seleccionar una categoría.';
      });
    }
    if (kml == '') {
      setState(() {
        kmlMessage = 'Debe cargar un archivo KML.';
      });
    }

    if ((dateEnd!.isBefore(dateStart!))){
      setState(() {
        dateMessage = 'Fecha Final debe de ser posterior o igual a inicio.';
      });
    }

    if (DateTime(dateEnd!.year, dateEnd!.month, dateEnd!.day).isBefore
      (DateTime(currentDateInGMT4.year, currentDateInGMT4.month, currentDateInGMT4.day))) {
      setState(() {
        dateMessage = 'No puede crear campañas finalizadas.';
      });
    }

  }

}
