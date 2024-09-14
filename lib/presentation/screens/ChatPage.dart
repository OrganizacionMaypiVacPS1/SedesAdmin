import 'dart:io';

import 'package:admin/Implementation/ChatImp.dart';
import 'package:admin/Models/ConversationModel.dart';
import 'package:admin/presentation/screens/Campaign.dart';
import 'package:admin/services/global_notification.dart';
import 'package:admin/services/services_firebase.dart';
import 'package:flutter/material.dart';
import 'package:admin/Models/ChatModel.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_spinkit/flutter_spinkit.dart';


void main() => runApp(ChatApp());

class ChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Móvil',
      theme: ThemeData(
        primarySwatch: myColorMaterial,
      ),
      home: ChatPage(
        idChat: 0,
        nombreChat: '',
        idPersonDestino: 0,
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  final int idChat;
  final String nombreChat;
  final int idPersonDestino;
  final File? imageChat;
  ChatPage({required this.idChat, required this.nombreChat, required this.idPersonDestino, this.imageChat});
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  ScrollController _scrollController = ScrollController();
  bool isLoadingMessages=false;
  TextStyle styleNombreMensaje = TextStyle(
      color: Colors.grey[350],
      fontSize: 18.0,
      fontWeight: FontWeight.bold,
      fontStyle: FontStyle.italic, 
      shadows: [
        Shadow(
          blurRadius: 2.0,
          color: Colors.black38,
          offset: Offset(1.0, 1.0),
        ),
      ],
    );




  TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    currentChatId = widget.idChat;

    fetchMessage(context, widget.idChat).then((value) => {
      if(mounted){
        setState((){
          messages = value;
          messages = messages.reversed.toList();
          print(messages.toString());
          print(miembroActual!.id);
          isLoadingMessages=true;
        })
      }
    });
  
    socket.on('chat message', (data) async {
      //ChatMessage chat = ChatMessage(idPerson: miembroActual!.id, mensaje: data, idChat: widget.idChat);
      int chatId = widget.idChat;
      if (mounted) {
        setState(() {
          if(chatId == data[3])
          messages.insert(0, ChatMessage(idPerson: data[0], mensaje: data[1], idChat: chatId, nombres: data[2]));
        });
        _scrollController.animateTo(
          0.0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      
    });
  }



  @override
  void dispose() {
    currentChatId=0;
    super.dispose();
    
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF5C8ECB),
      appBar: AppBar(
        backgroundColor: Color(0xFF5C8ECB),
        title: Row(children: [
          CircleAvatar(
            backgroundImage: FileImage(widget.imageChat!),
          ),
          SizedBox(width: 20,),
          Text(widget.nombreChat, style: TextStyle(color: Colors.white)),
        ],) ,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
      body: isLoadingMessages? Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              reverse: true,
              controller: _scrollController,
              padding: EdgeInsets.all(10.0),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5.0),
                  child: Column(
                    crossAxisAlignment:
                        widget.idPersonDestino!=0?
                         (messages[index].idPerson != widget.idPersonDestino
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start):
                            (messages[index].idPerson == miembroActual!.id?CrossAxisAlignment.end
                            : CrossAxisAlignment.start),
                    children: <Widget>[
                      widget.idPersonDestino!=0?
                      (messages[index].idPerson != widget.idPersonDestino
                        && messages[index].idPerson == miembroActual!.id
                        ? Text('Yo', style: styleNombreMensaje)
                        : Text(messages[index].nombres, style: styleNombreMensaje)
                      )
                      :
                      (messages[index].idPerson == miembroActual!.id
                        ? Text('Yo', style: styleNombreMensaje)
                        : Text(messages[index].nombres, style: styleNombreMensaje)
                      ),  
                      Card(
                        color: 
                        widget.idPersonDestino!=0?
                        (messages[index].idPerson != widget.idPersonDestino
                            ? Colors.green
                            : Colors.white):(messages[index].idPerson == miembroActual!.id
                            ? Colors.green
                            : Colors.white),
                        elevation: 5.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 15.0, vertical: 10.0),
                          child: Text(
                            messages[index].mensaje,
                            style: TextStyle(
                              color:
                                  widget.idPersonDestino!=0?
                                  (messages[index].idPerson != widget.idPersonDestino //messages[index].idPerson == miembroActual!.id
                                      ? Colors.white
                                      : Colors.black):(messages[index].idPerson == miembroActual!.id
                                      ? Colors.white
                                      : Colors.black),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(color: Color(0xFF4D6596)),
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      hintStyle:
                          TextStyle(color: Color(0xFF4D6596).withOpacity(0.7)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF5C8ECB), width: 1.0),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.white),
                  onPressed: () async {
                    if (_controller.text.isNotEmpty) {
                      await sendMessage(context, miembroActual!.id, _controller.text, widget.idChat);
                      //socket.emit('chat message', _controller.text);
                      _controller.clear();
                    }
                  },
                )
              ],
            ),
          )
        ],
      ):Center(child: SpinKitCircle(
                      color: Colors.white,
                      size: 50.0,
                    ),),
    );
  }
}

