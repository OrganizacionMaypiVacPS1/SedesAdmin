import 'dart:convert';
import 'package:admin/Implementation/ProfileImp.dart';
import 'package:admin/Models/Profile.dart';
import 'package:admin/presentation/screens/Login.dart';
import 'package:admin/presentation/screens/ProfilePage.dart';
import 'package:admin/services/services_firebase.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:http/http.dart' as http;

class ChangePasswordPage extends StatefulWidget {
  final Member? member;

  ChangePasswordPage({this.member});

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  String _code = '';
  String _password = '';
  String _confirmPassword = '';
  bool _isValidCode = false;
  bool _showPasswordFields =
      false; // Variable para mostrar/ocultar campos de contraseña

  @override
  void initState() {
    super.initState();
  }

  String calculateMD5(String input) {
    return md5.convert(utf8.encode(input)).toString();
  }

  void _validate() async {
    // Verificar si todos los campos están llenos
    print("se esta validando");
    if (_code.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor, ingrese todos los dígitos del código.'),
        ),
      );
      return;
    }

    // Realizar una solicitud HTTP para validar el código
    final isValid = await validate(_code, widget.member?.id ?? 0);

    if (isValid) {
      // El código es válido, habilitar los campos de contraseña y repetir contraseña
      setState(() {
        _isValidCode = true;
        _showPasswordFields = true;
      });
    } else {
      // El código no es válido, mostrar un mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('El código no es válido. Por favor, inténtelo de nuevo.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 92, 142, 203),
        centerTitle: true,
        title: Text('Cambiar Contraseña'),
        leading: isLogin == 0
            ? Builder(
                builder: (context) => IconButton(
                  icon: Icon(Icons.arrow_back,
                      color: Color.fromARGB(255, 92, 142, 203)),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProfilePage(member: widget.member),
                      ),
                    );
                  },
                ),
              )
            : Container(),
      ),
      body: Container(
        color: Color.fromARGB(255, 255, 255, 255),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text('Cambiar Contraseña'),
              SizedBox(height: 10),
              PinCodeTextField(
                appContext: context,
                length: 5,
                onChanged: (value) {
                  setState(() {
                    _code = value;
                    // Ocultar los campos de contraseña si el código no tiene 5 dígitos
                    if (value.length != 5) {
                      _showPasswordFields = false;
                    }
                  });
                },
                onCompleted: (value) {
                  _validate();
                },
                keyboardType: TextInputType.number,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(10),
                  fieldHeight: 50,
                  fieldWidth: 40,
                  borderWidth: 2,
                  activeFillColor: Colors.transparent,
                  inactiveFillColor: Colors.transparent,
                  selectedFillColor: Colors.transparent,
                ),
                cursorColor: Color.fromARGB(255, 92, 142, 203),
                textStyle: TextStyle(
                  color: Color.fromARGB(255, 92, 142, 203),
                  fontSize: 20.0,
                ),
                enableActiveFill: true,
              ),
              SizedBox(height: 16),
              _showPasswordFields
                  ? Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lock, // Icono de candado
                              color: Color.fromARGB(
                                  255, 92, 142, 203), // Color del icono
                            ),
                            SizedBox(
                                width:
                                    10), // Espacio entre el icono y el campo de texto
                            Expanded(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Contraseña',
                                  labelStyle: TextStyle(
                                    fontSize: 16,
                                    color: Color.fromARGB(255, 92, 142, 203),
                                  ),
                                ),
                                onChanged: (value) => _password = value,
                                validator: (value) =>
                                    value!.isEmpty ? 'Campo requerido' : null,
                                obscureText: true,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.lock, // Icono de candado
                              color: Color.fromARGB(
                                  255, 92, 142, 203), // Color del icono
                            ),
                            SizedBox(
                                width:
                                    10), // Espacio entre el icono y el campo de texto
                            Expanded(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Confirmar Contraseña',
                                  labelStyle: TextStyle(
                                    fontSize: 16,
                                    color: Color.fromARGB(255, 92, 142, 203),
                                  ),
                                ),
                                onChanged: (value) => _confirmPassword = value,
                                validator: (value) {
                                  if (value!.isEmpty) return 'Campo requerido';
                                  if (value != _password)
                                    return 'Las contraseñas no coinciden';
                                  return null;
                                },
                                obscureText: true,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: () async {
                            // Verificar si las contraseñas coinciden
                            if (_password != _confirmPassword) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Las contraseñas no coinciden.'),
                                ),
                              );
                              return;
                            }

                            // Calcular el hash MD5 de la contraseña
                            final md5Password = calculateMD5(_password);

                            // Cambiar la contraseña
                            final isChanged = await changePassword(
                                widget.member?.id ?? 0, md5Password);
                            if (isChanged) {
                              if (isLogin == 0) {
                                // Navegar a Login.dart si isLogin es 1
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ProfilePage(member: widget.member),
                                  ),
                                );
                              } else {
                                // Navegar a otra página si isLogin no es 1
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MyApp(),
                                  ),
                                );
                              }

                              // Mostrar el mensaje de confirmación
                              Mostrar_Mensaje(
                                  context, 'Contraseña cambiada con éxito');
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Error al cambiar la contraseña.'),
                                ),
                              );
                            }
                          },
                          child: Text('Guardar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white, // Fondo blanco
                            foregroundColor:
                                Color(0xFF4D6596), // Texto color 0xFF4D6596
                            minimumSize: Size(double.infinity,
                                50), // Ancho igual y altura de 50
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(20), // Radio de borde
                              side: BorderSide(
                                color: Color.fromARGB(
                                    255, 92, 142, 203), // Color del borde
                                width: 2.0, // Ancho del borde
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : SizedBox(),
              SizedBox(height: 16),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (isLogin == 0) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProfilePage(member: widget.member),
                      ),
                    );
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyApp(),
                      ),
                    );
                  }
                },
                child: Text('Cancelar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4D6596), // Fondo color 0xFF4D6596
                  foregroundColor: Color.fromARGB(255, 255, 255, 255), // Texto blanco
                  minimumSize:
                      Size(double.infinity, 50), // Ancho igual y altura de 50
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20), // Radio de borde
                    side: BorderSide(
                      color: Color.fromARGB(
                          255, 92, 142, 203), // Color del borde (blanco)
                      width: 1.0, // Grosor del borde
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
