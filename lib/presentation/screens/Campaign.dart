import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:admin/Implementation/CampaignImplementation.dart';
import 'package:admin/Implementation/ChatImp.dart';
import 'package:admin/Implementation/ConversationImp.dart';
import 'package:admin/Implementation/TokensImp.dart';
import 'package:admin/Models/ChatModel.dart';
import 'package:admin/Models/ConversationModel.dart';
import 'package:admin/Models/Profile.dart';
import 'package:admin/presentation/screens/List_members.dart';
import 'package:admin/presentation/screens/Login.dart';
import 'package:admin/presentation/screens/ProfilePage.dart';
import 'package:admin/presentation/screens/RegisterBoss.dart';
import 'package:admin/presentation/screens/ChatPage.dart';
import 'package:admin/presentation/screens/Conversations.dart';
import 'package:admin/presentation/screens/RegisterCampaign.dart';
import 'package:admin/presentation/screens/RegisterCardholders.dart';
import 'package:admin/services/services_firebase.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:admin/Models/CampaignModel.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart'; 

int estadoPerfil = 0;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CampaignProvider(),
      child: MaterialApp(
        title: 'Campañas',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: CampaignPage(),
      ),
    );
  }
}

class CampaignProvider extends ChangeNotifier {
  List<Campaign> campaigns1 = campaigns;
  bool showAllCampaigns = false;

  CampaignProvider() {
    loadCampaigns();
  }

  Future<void> loadCampaigns() async {
    campaigns1 = campaigns;
    //campaigns1 = await fetchCampaigns();

    notifyListeners();
  }

  void toggleShowAll() {
    showAllCampaigns = !showAllCampaigns;
    notifyListeners();
  }

  void searchCampaign(String query) async {
    //campaigns1 = await fetchCampaigns();

    campaigns1 = campaigns
        .where((campaign) =>
            campaign.nombre.toLowerCase().contains(query.toLowerCase()))
        .toList();

    notifyListeners();
  }
}

class CampaignPage extends StatefulWidget {
  @override
  _CampaignStateState createState() => _CampaignStateState();
}

class _CampaignStateState extends State<CampaignPage>
    with SingleTickerProviderStateMixin {
  bool isloadingProfile = true;
  String selectedCategory = 'Vacuna'; 
  List<String> categories = ['Vacuna', 'Carnetizacion', 'Control de Foco', 'Vacunación Continua', 'Rastrillaje']; 

  
  final now = DateTime.now();
  @override
  void initState() {
    super.initState();
    if(imageProfile==null){
      addImageToSelectedImages(miembroActual!.id);
    }else{
      isloadingProfile=false;
    }
    
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      setState(() {
      });
    }
  }

  @override
  void didUpdateWidget(covariant CampaignPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      // Tu widget está activo de nuevo, actualiza según sea necesario
      setState(() {
        // Actualiza tu UI o los datos necesarios aquí
      });
    }
  }





  Color getStatusColor(DateTime start, DateTime end) {

    if (now.isAfter(end)) {
      return Colors.red; 
    } else if (now.isBefore(start)) {
      return Colors.blue; 
    } else {
      return Colors.green; 
    }
  }


  Future<File?> addImageToSelectedImages(int idPerson) async {
    try {
      String imageUrl = await getImageUrl(idPerson);
      File tempImage = await _downloadImage(imageUrl);
      
      setState(() {
        imageProfile = tempImage;
        isloadingProfile=false;
      });
      return imageProfile;
    } catch (e) {
      print('Error al obtener y descargar la imagen: $e');
      setState(() {
        isloadingProfile=false;
      });
    }
    
    return null;
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

  @override
  Widget build(BuildContext context) {
    final searchField = Padding(
      padding: const EdgeInsets.all(12),
      child: TextFormField(
        style: TextStyle(color: Color.fromARGB(255, 92, 142, 203)),
        decoration: InputDecoration(
          hintText: 'Buscar',
          hintStyle: TextStyle(color: Color.fromARGB(255, 92, 142, 203)),
          prefixIcon:
              Icon(Icons.search, color: Color.fromARGB(255, 92, 142, 203)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide(color: Color.fromARGB(255, 92, 142, 203)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide(color: Color.fromARGB(255, 92, 142, 203)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide(color: Color.fromARGB(255, 92, 142, 203)),
          ),
        ),
        onChanged: (value) {
          context.read<CampaignProvider>().searchCampaign(value);
        },
      ),
    );

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 92, 142, 203),
        title: Text('Actividades', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
                decoration: BoxDecoration(
                  color: Color.fromRGBO(77, 101, 150, 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LayoutBuilder(
                        builder: (context, constraints) {
                          double avatarRadius = constraints.maxWidth * 0.15;
                          
                          return imageProfile != null
                            ? InkWell(
                              onTap: () {
                                Navigator.of(context).pop();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RegisterBossPage(
                                      isUpdate: true,
                                      userData: miembroActual,
                                    )),
                                );
                              },
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircleAvatar(
                                    backgroundImage: isloadingProfile?null: FileImage(imageProfile!),
                                    radius: avatarRadius,
                                  ),
                                  if (isloadingProfile)
                                    SizedBox(
                                      width: 60, 
                                      height: 60, 
                                      child: SpinKitCircle(
                                        color: Colors.white,
                                      ),
                                    ),
                                ],
                              ),
                            )
                            : InkWell(
                              onTap: () {
                                Navigator.of(context).pop();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RegisterBossPage(
                                      isUpdate: true,
                                      userData: miembroActual,
                                    )),
                                );
                              },
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                   CircleAvatar(
                                    backgroundImage: isloadingProfile?null: AssetImage('assets/usuario.png'),
                                    radius: avatarRadius,
                                  ),
                                  if (isloadingProfile)
                                    SizedBox(
                                      width: 60, 
                                      height: 60, 
                                      child: SpinKitCircle(
                                        color: Colors.white,
                                      ),
                                    ),
                                ],
                              ),
                            );
                        },
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 10),
                        Column(
                          children: [
                            Text(
                              miembroActual!.names,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              miembroActual!.correo,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                )),
            ListTile(
              leading: Icon(Icons.campaign),
              title: Text('Registrar Actividad'),
              onTap: () async {
                Navigator.of(context).pop();
                var res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => RegisterCampaignPage(
                            initialData: Campaign(
                                id: 0,
                                nombre: "",
                                descripcion: "",
                                categoria: "",
                                dateStart: DateTime.now(),
                                dateEnd: DateTime.now(),
                                userId: 0),
                          )),
                );
                if (res != null) {
                  setState(() {
                  });
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.person_add_alt),
              title: Text('Registrar Usuario'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => RegisterBossPage(
                            isUpdate: false,
                          )),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.message),
              title: Text('Mensaje'),
              onTap: () async {
                Navigator.of(context).pop();
                if (miembroActual!.role == 'Cliente') {
                  Chat chatCliente = Chat(
                      idChats: 0,
                      idPerson: null,
                      idPersonDestino: miembroActual!.id,
                      );
                  int lastId = 0;
                  List<Chat> filteredList = [];
                  await fetchChatsClient(context).then((value) => {
                        filteredList = value
                            .where((element) =>
                                element.idPersonDestino == miembroActual!.id)
                            .toList(),
                        if (filteredList.isEmpty)
                          {
                            registerNewChat(context, chatCliente).then((value) => {
                                  getLastIdChat(context).then((value) => {
                                        lastId = value,
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => ChatPage(
                                                    idChat: lastId,
                                                    nombreChat: 'Soporte',
                                                    idPersonDestino: 0,
                                                  )),
                                        )
                                      })
                                })
                          }
                        else
                          {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ChatPage(
                                        idChat: filteredList[0].idChats,
                                        nombreChat: 'Soporte',
                                        idPersonDestino: 0,
                                      )),
                            )
                          }
                      });
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ChatScreenState()),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.account_circle),
              title: Text('Perfil'),
              onTap: () {
                Navigator.of(context).pop();
                estadoPerfil = 0;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ProfilePage(member: miembroActual)),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.account_tree),
              title: Text('Cuentas'),
              onTap: () {
                Navigator.of(context).pop();
                estadoPerfil = 1;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ListMembersScreen()),
                );
              },
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: ListTile(
                leading: Icon(Icons.logout),
                title: Text('Cerrar Sesión'),
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  prefs.setInt('miembroLocal', 0);
                  esCarnetizador=false;
                  tokenClean();
                  chats.clear();
                  namesChats.clear();
                  imageProfile = null;
                  miembroActual = null;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body:
        Consumer<CampaignProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              Column(
                children: [
                  searchField,
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                          color: Color.fromARGB(255, 92, 142, 203),
                          width: 2.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true, 
                                value: selectedCategory,
                                icon: const Icon(Icons.arrow_drop_down),
                                iconSize: 24,
                                elevation: 16,
                                style: const TextStyle(color: Color(0xFF4D6596)),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedCategory = newValue!;
                                  });
                                },
                                items: categories.map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Expanded(
                    child: ListView.builder(
                      itemCount: provider.campaigns1.length,
                      itemBuilder: (context, index) {
                          if(provider.campaigns1[index].categoria!=selectedCategory){
                            return SizedBox.shrink();
                          }
                          return Card(
                                  elevation: 4.0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    side: BorderSide(
                                      color: Color.fromARGB(255, 92, 142, 203),
                                      width: 2.0,
                                    ),
                                  ),
                                  margin: const EdgeInsets.all(10.0),
                                  child: ListTile(
                                    title: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            provider.campaigns1[index].nombre,
                                            style: TextStyle(
                                              color: Color(0xFF4D6596),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                          decoration: BoxDecoration(
                                            color: getStatusColor(
                                              provider.campaigns1[index].dateStart,
                                              provider.campaigns1[index].dateEnd,
                                            ),
                                            borderRadius: BorderRadius.circular(5.0),
                                          ),
                                          child: Text(
                                            now.isAfter(provider.campaigns1[index].dateEnd)
                                                ? 'Finalizado'
                                                : now.isBefore(provider.campaigns1[index].dateStart)
                                                    ? 'En espera'
                                                    : 'En curso',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          provider.campaigns1[index].descripcion,
                                          style: TextStyle(color: Color(0xFF4D6596)),
                                        ),
                                        Text(
                                          "${DateFormat('dd/MM/yy').format(provider.campaigns1[index].dateStart)} - ${DateFormat('dd/MM/yy').format(provider.campaigns1[index].dateEnd)}",
                                          style: TextStyle(
                                            color: Color(0xFF4D6596),
                                            fontSize: 12.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () async {
                                      var res = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => RegisterCampaignPage(
                                            initialData: provider.campaigns1[index],
                                          ),
                                        ),
                                      );
                                      if (res != null) {
                                        setState(() {
                                        });
                                      }
                                    },
                                  ),
                                );
                      },
                    ),
                  ),
                ],
              ),
              
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          var res = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => RegisterCampaignPage(
                      initialData: Campaign(
                          id: 0,
                          nombre: "",
                          descripcion: "",
                          categoria: "",
                          dateStart: DateTime.now(),
                          dateEnd: DateTime.now(),
                          userId: 0),
                    )),
          );
          if (res != null) {
            setState(() {
            });
          }
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF4C6596),
      ),
    );
  }
}
