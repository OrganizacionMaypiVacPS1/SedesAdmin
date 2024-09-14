import 'dart:convert';
import 'package:admin/Implementation/ProfileImp.dart';
import 'package:admin/services/services_firebase.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:admin/Models/Profile.dart';
import 'package:admin/presentation/screens/Campaign.dart';
import 'package:admin/presentation/screens/ProfilePage.dart';
import 'package:provider/provider.dart';

class ListMembersScreen extends StatefulWidget {
  @override
  _ListMembersScreenState createState() => _ListMembersScreenState();
}

class _ListMembersScreenState extends State<ListMembersScreen> {
  final List<String> roles = [
    "Todos",
    "Administrador",
    "Jefe de Brigada",
    "Carnetizador",
    //"Clientes"
  ];
  String selectedRole = esCarnetizador ? "Jefe de Brigada" : "Todos";
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    selectedRole = esCarnetizador ? "Jefe de Brigada" : "Todos";
    members = fetchMembers();
  }

  List<Member> filteredMembers(List<Member> allMembers) {
    if (selectedRole == "Todos") {
      return allMembers.where((member) {
        final lowerCaseName = member.names.toLowerCase();
        final lowerCaseCarnet = member.carnet?.toLowerCase();
        final lowerCaseQuery = searchQuery.toLowerCase();

        return lowerCaseName.contains(lowerCaseQuery) ||
            lowerCaseCarnet!.contains(lowerCaseQuery);
      }).toList();
    } else {
      return allMembers.where((member) {
        final lowerCaseName = member.names.toLowerCase();
        final lowerCaseCarnet = member.carnet?.toLowerCase();
        final lowerCaseRole = member.role?.toLowerCase();
        final lowerCaseQuery = searchQuery.toLowerCase();

        return (lowerCaseName.contains(lowerCaseQuery) ||
                lowerCaseCarnet!.contains(lowerCaseQuery)) &&
            lowerCaseRole == selectedRole.toLowerCase();
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF4D6596),
        title: Text('Cuentas',
            style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);

            },
          ),
        ),
      ),
      body: Container(
        color: Color.fromARGB(255, 255, 255, 255),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Theme(
                  data: ThemeData(
                    canvasColor: Color.fromARGB(255, 255, 255, 255),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: selectedRole,
                    items: roles.map((role) {
                      return DropdownMenuItem<String>(
                        value: role,
                        child: Text(
                          role,
                          style: TextStyle(
                              color: Color.fromARGB(255, 92, 142, 203)),
                        ),
                      );
                    }).toList(),
                    onChanged: esCarnetizador
                        ? null
                        : (newValue) {
                            setState(() {
                              selectedRole = newValue!;
                            });
                          },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color.fromARGB(255, 255, 255, 255),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            10.0), // Personaliza el radio del borde
                        borderSide: BorderSide(
                          color: Color.fromARGB(
                              255, 92, 142, 203), // Color del borde
                          width: 2.0, // Ancho del borde
                        ),
                      ),
                    ),
                  )),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (query) {
                  setState(() {
                    searchQuery = query;
                  });
                },
                style: TextStyle(color: Color.fromARGB(255, 92, 142, 203)),
                decoration: InputDecoration(
                  labelText: 'Buscar por nombre o carnet',
                  labelStyle:
                      TextStyle(color: Color.fromARGB(255, 92, 142, 203)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        10.0), // Personaliza el radio del borde
                    borderSide: BorderSide(
                      color:
                          Color.fromARGB(255, 92, 142, 203), // Color del borde
                      width: 2.0, // Ancho del borde
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Member>>(
                future: members,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    final allMembers = snapshot.data ?? [];
                    final filtered = filteredMembers(allMembers);

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final member = filtered[index];
                        if (miembroActual == null || miembroActual!.id == member.id) {
                          return SizedBox.shrink(); 
                        }
                        return Container(
                          margin: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color.fromARGB(
                                    255, 255, 255, 255), // 20% del otro color
                                Color.fromARGB(
                                    255, 255, 255, 255), // 20% del otro color
                                Color.fromARGB(255, 92, 142, 203), // 80% blanco
                              ],
                              stops: [
                                0.2,
                                0.75,
                                1
                              ], // Establece los puntos de parada del color
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Color.fromARGB(255, 92, 142, 203),
                              width: 2.0,
                            ),
                          ),
                          child:  Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      member.names,
                                      style: TextStyle(
                                        color:
                                            Color.fromARGB(255, 92, 142, 203),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "${member.fechaCreacion?.day}/${member.fechaCreacion?.month}/${member.fechaCreacion?.year}",
                                      style: TextStyle(
                                        color:
                                            Color.fromARGB(255, 92, 142, 203),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Carnet: ${member.carnet}",
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 92, 142, 203),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Rol: ${member.role}",
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 92, 142, 203),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: esCarnetizador
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.of(context)
                                                    .pop(member);
                                              },
                                              child: Text("Seleccionar"),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            ElevatedButton(
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return AlertDialog(
                                                      title: Text(
                                                          'Eliminar Usuario?'),
                                                      content: Icon(
                                                        Icons.warning,
                                                        color: Colors.red,
                                                        size: 50,
                                                      ),
                                                      actions: <Widget>[
                                                        TextButton(
                                                          child: Text(
                                                            'Cancelar',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .black),
                                                          ),
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop(0);
                                                          },
                                                        ),
                                                        TextButton(
                                                          child: Text(
                                                            'Eliminar',
                                                            style: TextStyle(
                                                                color:
                                                                    Colors.red),
                                                          ),
                                                          onPressed: () async {
                                                            Navigator.of(
                                                                    context)
                                                                .pop(1);
                                                            await deleteAccount(
                                                                member.id);
                                                            setState(() {});
                                                          },
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                              child: Text("Eliminar"),
                                            ),
                                            SizedBox(width: 10),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ProfilePage(
                                                            member: member),
                                                  ),
                                                );
                                              },
                                              child: Text("Ver Perfil"),
                                            ),
                                          ],
                                        ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(home: ListMembersScreen()));
}
