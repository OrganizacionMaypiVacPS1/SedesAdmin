import 'package:admin/Implementation/ChatImp.dart';
import 'package:admin/Implementation/ConversationImp.dart';
import 'package:admin/Models/ConversationModel.dart';
import 'package:admin/Models/Profile.dart';
import 'package:admin/presentation/screens/Campaign.dart';
import 'package:admin/presentation/screens/ChatPage.dart';
import 'package:admin/Config/Config.dart';
import 'package:admin/services/connectivity_service.dart';
import 'package:admin/services/services_firebase.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:admin/Models/ChatModel.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';



void main() => runApp(Conversations());

class Conversations extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Móvil',
      theme: ThemeData(
        primarySwatch: myColorMaterial,
      ),
      home: ChatScreenState(),
    );
  }
}

  bool isloadingProfile = true;

class ChatScreenState extends StatefulWidget {
  @override
  _ChatScreenStateState createState() => _ChatScreenStateState();
}

class _ChatScreenStateState extends State<ChatScreenState> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final emailController = TextEditingController();
  bool isLoading = true;
  Member? resPersonDestino;
  final ConnectivityService _connectivityService = ConnectivityService();
  Map<int, File?> _selectedImages = {};



  @override
  void initState() {
    super.initState();
    _connectivityService.initialize(context);
    _tabController = TabController(length: 2, vsync: this);
    _tabController?.addListener(_handleTabSelection);
    //loadAllImages();

    if(isConnected.value){
      if(namesChats.isEmpty){
      fetchNamesPersonDestino(context, miembroActual!.id).then((value) => {
        if(mounted){
          setState(() {
            namesChats = value;
          })
        },
        fetchChats(context).then((value) => {
          
          if(mounted){
            setState((){
              chats = value;
              print(chats.toList());
            })
          },
          isLoading = false,
          loadAllImages()
        })
        
      });
      
    }else{
      isLoading=false;
      loadAllImages();
    }
    

    
    
    //namesChats = await fetchNamesPersonDestino(miembroActual!.id);
    socket.on('chat message', (data) async {
      if (!mounted) return; 
      List<dynamic> namesChatsNew = await fetchNamesPersonDestino(context, miembroActual!.id);
      fetchChats(context).then((value) {
        if (mounted) { 
          setState(() {
            chats = value;
            namesChats = namesChatsNew;
          });
        }
      });

      if (mounted) {
        setState(() {
          
        });
      }
    });

  }

  
    }

Future<Member?> getPersonById(int userId) async {
  final response = await http.get(
    Uri.parse(Config.baseUrl+'/getpersonbyid/$userId'),
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = json.decode(response.body);
    final member = Member.fromJson(data);
    return member;
  } else if (response.statusCode == 404) {
    return null; // Persona no encontrada
  } else {
    throw Exception('Error al obtener la persona por ID');
  }
}

  Future<void> loadAllImages() async {
    int idP=0;
    
    for (var chat in chats) {
      if(miembroActual!.id==chat.idPerson){
        idP=chat.idPersonDestino;
      }else if(chat.idPerson!=null){
        idP= chat.idPerson!;
      }else{
        idP=chat.idPersonDestino;
      }
      await addImageToSelectedImages( chat.idChats, idP );
    }
    if(mounted){
      setState(() {
        isloadingProfile = false;
      });
    }
    
  }

  Future<void> addImageToSelectedImages(int idChat,int idPerson) async {
    try {

      String imageUrls = await getImageUrl( idPerson);

      File tempImage = await _downloadImage(imageUrls);


      setState(() {
        _selectedImages[idChat] = tempImage;
      });


    } catch (e) {
      print('Error al obtener y descargar las imágenes: $e');
    }
    isloadingProfile=false;
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


  void _handleTabSelection() {
    if (mounted) {
      setState(() {});  
    }    
  }

  

  @override
  void dispose() {
    _connectivityService.dispose();
    super.dispose();
  }

  Future<void> eliminarChat(int index) async{
    await deleteChat(context, chats[index].idChats);
    setState(() {
      chats.removeAt(index);
    });
  }

  Future<void> addNewChat() async {
    //Registrar Nuevo Chat
    bool canUser = true;
    int idPersonNewChat=0;
    Chat newChat = Chat(idChats: 0, idPerson: 0, idPersonDestino: 0);
    dynamic searchChat;
    setState(() {
      isLoading =true;
    });
    
    await getIdPersonByEMail(emailController.text).then((value) async => {
      idPersonNewChat = value,
      if(value==miembroActual!.id){
        Mostrar_Error(context, "No puede iniciar un chat con su correo"),
        canUser =false
      }else if(value==0){
        Mostrar_Error(context, "No se encontró el correo"),
        canUser = false
      }else{
      newChat = Chat(idChats: 0, idPerson: miembroActual!.id, idPersonDestino: idPersonNewChat),
      await getPersonById(idPersonNewChat).then((value) => {
        resPersonDestino = value,
        searchChat=chats.where((element) => element.idPersonDestino==resPersonDestino!.id||element.idPerson==resPersonDestino!.id).toList(),
        if(searchChat.isNotEmpty){
          Mostrar_Error(context, "El Chat ya existe"),
          canUser = false
        }else if(resPersonDestino?.role=="Cliente"){
          Mostrar_Error(context, "No se encontró el correo"),
          canUser = false
        }
      })
      }
    });
    if(canUser){
      int newIdChat = 0;
      await registerNewChat(context,newChat);
      await getLastIdChat(context).then((value) => {
          newIdChat = value,
          setState(() {
            chats.add(Chat(idChats: newIdChat, idPerson: miembroActual!.id, idPersonDestino: idPersonNewChat));
          })
      });
 
      List<dynamic> namesChatsNew = [];
      //namesChats.clear();
      await fetchNamesPersonDestino(context,miembroActual!.id).then((value) => {
        if(mounted){
          namesChatsNew = value,
          setState(() {
            namesChats = namesChatsNew;
          })
        }
        
      });
    }
    setState(() {
      isLoading =false;
    });
    //
    
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  backgroundColor: Color(0xFF5C8ECB),
  appBar: AppBar(
    backgroundColor: Color(0xFF5C8ECB),
    title: Text('Chats'),
    bottom: TabBar(
      controller: _tabController,
      tabs: [
        Tab(text: 'Soporte'),
        Tab(text: 'Administración'),
      ],
    ),
    leading: Builder(
      builder: (context) => IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    ),
  ),
  body: isConnected.value? isLoading==false
      ? TabBarView(
          controller: _tabController,
          children: [
            
            EstadoList(eliminarChatFunction: eliminarChat, selectedImages: _selectedImages,)
            ,
            ChatList(eliminarChatFunction: eliminarChat, selectedImages: _selectedImages),

          ],
        )
      : Center(
          child: SpinKitCircle(
                      color: Colors.white,
                      size: 50.0,
                    ),
        ): Container(
        color: Color(0xFF5C8ECB),
        
        child: Center(child: Text('Error: Connection failed', style: TextStyle(color: Colors.white),))),
  floatingActionButton: _tabController?.index==1?  FloatingActionButton(
     onPressed: isConnected.value? () {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Iniciar nuevo chat en Administración'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Ingresa el email de la persona con la que quieres chatear:'),
                SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: Color(0xFF4D6596), fontSize: 16),
                  cursorColor: Color(0xFF4D6596),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Color(0xFF4D6596)),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF4D6596), width: 2.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF4D6596).withOpacity(0.5), width: 2.0),
                    ),
                    border: OutlineInputBorder(),
                    hintStyle: TextStyle(color: Color(0xFF4D6596).withOpacity(0.5)),
                    prefixIcon: Icon(Icons.email, color: Color(0xFF4D6596)),
                  ),
                ),
              ],
            ),
            actions: [
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
TextButton(
                child: Text('Cancelar'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Aceptar'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await addNewChat();
                  emailController.clear();
                  loadAllImages();
                },
              ),
              ],),
              
              TextButton(
                child: Text('Abrir Nuevo Chat con Soporte Técnico'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  dynamic res =namesChats.where((element) => element['Nombres']=='erick');
                  emailController.text = "galaxixsum@gmail.com";   
                  await addNewChat();
                  emailController.clear();
                },
              ),
            ],
          );
        },
      );
    }:null,
    child: Icon(Icons.chat), // Icono de chat
    backgroundColor: Color.fromARGB(255, 0, 204, 255),
    foregroundColor: Colors.white,
    tooltip: 'Iniciar nuevo chat',
  ):Container(),
);

  }
}

class ChatList extends StatelessWidget {
  final Function eliminarChatFunction;
  Map<int, File?> selectedImages = {};

  ChatList({required this.eliminarChatFunction, required this.selectedImages});
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: chats.length,
      itemBuilder: (context, index) {
        return chats[index].idPerson!=null&&(namesChats[index]["mensaje"]!=""||chats[index].idPerson==miembroActual!.id)? Card(
          margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          elevation: 5,
          child: InkWell(
            onTap: () async {
              currentChatId =  chats[index].idChats;
              File imageFile = await getImageFileFromAssets('assets/usuario.png');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatPage(idChat: chats[index].idChats, nombreChat: namesChats[index]["Nombres"], idPersonDestino: 0, imageChat: 
                selectedImages[chats[index].idChats]==null?imageFile:selectedImages[chats[index].idChats])),//////////////
              );
            },
            onLongPress: () async {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Eliminar chat?'),
                    content: Icon(Icons.warning, color: Colors.red, size: 50),
                    actions: <Widget>[
                      TextButton(
                        child: Text('Cancelar', style: TextStyle(color: Colors.black)),
                        onPressed: () {
                          Navigator.of(context).pop(0); 
                        },
                      ),
                      TextButton(
                        child: Text('Eliminar', style: TextStyle(color: Colors.red)),
                        onPressed: () async {
                          eliminarChatFunction(index);
                          Navigator.of(context).pop(1); 
                        },
                      ),
                    ],
                  );
                },
              );
            },
            child: ListTile(
              title: Text(namesChats[index]["Nombres"]),
              subtitle: Text(namesChats[index]["mensaje"]),
              leading:   Stack(
                alignment: Alignment.center,
                children: [
                  selectedImages[chats[index].idChats] != null
                            ?Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircleAvatar(
                                    backgroundImage: isloadingProfile?null: FileImage(selectedImages[chats[index].idChats]!),
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
                              )
                            
                            :  Stack(
                                alignment: Alignment.center,
                                children: [
                                   CircleAvatar(
                                    backgroundImage: isloadingProfile?null: AssetImage('assets/usuario.png'),
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
                            
                ],
              ),
            ),
          ),
        ):Container();
      },
    );
  }
}

class EstadoList extends StatelessWidget {
  final Function eliminarChatFunction;
    Map<int, File?> selectedImages = {};
  

  EstadoList({required this.eliminarChatFunction, required this.selectedImages});
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: chats.length, // Ensure this matches the length of chats and namesChats
      itemBuilder: (context, index) {
        // Prevent RangeError by ensuring namesChats has enough elements
        if (index >= namesChats.length || index >= chats.length) {
          return Container(); // Return empty container if index is out of range
        }

        // Handle cases where chats[index].idPerson and namesChats[index]["mensaje"] are null or empty
        if (chats[index].idPerson == null && namesChats[index]["mensaje"] != "") {
          return Card(
            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            elevation: 5,
            child: InkWell(
              onTap: () async {
                print('idPersonDestino:' + chats[index].idPersonDestino.toString());
                File imageFile = await getImageFileFromAssets('assets/usuario.png');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      idChat: chats[index].idChats,
                      nombreChat: namesChats[index]["Nombres"],
                      idPersonDestino: chats[index].idPersonDestino,
                      imageChat: selectedImages[chats[index].idChats] == null
                          ? imageFile
                          : selectedImages[chats[index].idChats],
                    ),
                  ),
                );
              },
              onLongPress: () async {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Eliminar chat?'),
                      content: Icon(Icons.warning, color: Colors.red, size: 50),
                      actions: <Widget>[
                        TextButton(
                          child: Text('Cancelar', style: TextStyle(color: Colors.black)),
                          onPressed: () {
                            Navigator.of(context).pop(0);
                          },
                        ),
                        TextButton(
                          child: Text('Eliminar', style: TextStyle(color: Colors.red)),
                          onPressed: () async {
                            eliminarChatFunction(index);
                            Navigator.of(context).pop(1);
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              child: ListTile(
                title: Text(namesChats[index]["Nombres"] ?? ""),
                subtitle: Text(namesChats[index]["mensaje"] ?? ""),
                leading: Stack(
                  alignment: Alignment.center,
                  children: [
                    selectedImages[chats[index].idChats] != null
                        ? InkWell(
                      onTap: () {},
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            backgroundImage: isloadingProfile
                                ? null
                                : FileImage(selectedImages[chats[index].idChats]!),
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
                      onTap: () {},
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            backgroundImage: isloadingProfile
                                ? null
                                : AssetImage('assets/usuario.png'),
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
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          return Container(); // If no valid data, return an empty container
        }
      },
    );
  }

}