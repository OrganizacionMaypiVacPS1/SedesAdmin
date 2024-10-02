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
import 'package:intl/intl.dart';

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
  bool isLoadingMessages = false;
  TextEditingController _controller = TextEditingController();
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

  @override
  void initState() {
    super.initState();
    currentChatId = widget.idChat;

    fetchMessage(context, widget.idChat).then((value) {
      if (mounted) {
        setState(() {
          messages = value.reversed.toList();
          isLoadingMessages = true;
        });
      }
    });

    socket.on('chat message', (data) async {
      if (mounted && widget.idChat == data[3]) {
        setState(() {
          messages.insert(0, ChatMessage(
              idPerson: data[0],
              mensaje: data[1],
              idChat: widget.idChat,
              nombres: data[2],
              fechaRegistro: DateTime.now().toUtc().add(Duration(hours: -4)),
          ));
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
    currentChatId = 0;
    super.dispose();
  }

  Widget buildMessage(ChatMessage message) {
    bool isSender = message.idPerson == miembroActual!.id;
    String horaMensaje = DateFormat('HH:mm').format(message.fechaRegistro);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(isSender ? 'Yo' : message.nombres, style: styleNombreMensaje),
          Card(
            color: isSender ? Colors.green : Colors.white,
            elevation: 5.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.mensaje,
                    style: TextStyle(color: isSender ? Colors.white : Colors.black),
                  ),
                  SizedBox(height: 5.0),
                  // Mostrar la hora del mensaje
                  Text(
                    horaMensaje,
                    style: TextStyle(fontSize: 10.0, color: isSender ? Colors.white70 : Colors.black54),
                  ),
                ],
                
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget buildMessageList() {
    return ListView.builder(
      reverse: true,
      controller: _scrollController,
      padding: EdgeInsets.all(10.0),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        ChatMessage currentMessage = messages[index];
        ChatMessage? previousMessage = index < messages.length - 1 ? messages[index + 1] : null;

        bool isNewDay = previousMessage == null ||
            !isSameDay(currentMessage.fechaRegistro, previousMessage.fechaRegistro);

        List<Widget> messageWidgets = [];

        if (isNewDay) {
          messageWidgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Center(
                child: Text(
                  DateFormat('EEEE, MMM d, yyyy').format(currentMessage.fechaRegistro),
                  style: TextStyle(color: Colors.grey, fontSize: 12.0),
                ),
              ),
            ),
          );
        }

        messageWidgets.add(
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.0),
            child: Align(
              alignment: currentMessage.idPerson == miembroActual!.id
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: buildMessage(currentMessage),
            ),
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: messageWidgets,
        );
      },
    );
  }


  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF5C8ECB),
      appBar: AppBar(
        backgroundColor: Color(0xFF5C8ECB),
        title: Row(
          children: [
            if (widget.imageChat != null) CircleAvatar(backgroundImage: FileImage(widget.imageChat!)),
            SizedBox(width: 20),
            Text(widget.nombreChat, style: TextStyle(color: Colors.white)),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoadingMessages
          ? Column(
        children: [
          Expanded(child: buildMessageList()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(color: Color(0xFF4D6596)),
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      hintStyle: TextStyle(color: Color(0xFF4D6596).withOpacity(0.7)),
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
                      _controller.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      )
          : Center(child: SpinKitCircle(color: Colors.white, size: 50.0)),
    );
  }
}


