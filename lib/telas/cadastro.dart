import 'package:alpha_car_motorista/modelo/usuario.dart';
import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Cadastro extends StatefulWidget {
  @override
  _CadastroState createState() => _CadastroState();
}

class _CadastroState extends State<Cadastro> {

  TextEditingController _controleNome = TextEditingController();
  TextEditingController _controleEmail = TextEditingController();
  TextEditingController _controlesenha = TextEditingController();


  bool _tipoUsuario = false;
  String _mensagemErro = "";

  _validarCampos(){

    //Recuperar dados dos campos
    String nome = _controleNome.text;
    String email = _controleEmail.text;
    String senha = _controlesenha.text;

    //validar campos
    if(nome.isNotEmpty){
      if(email.isNotEmpty && email.contains("@")){
        if(senha.isNotEmpty && senha.length > 6){

          Usuario usuario = Usuario();
           usuario.nome = nome;
           usuario.email = email;
           usuario.senha = senha;
           //usuario.tipoUsuario = usuario.verificaTipoUsuario(_tipoUsuario);

           _cadastrarUsuario(usuario);
        }else{
          _mensagemErro = "Preencha a senha digite mais de 6 letras";
        }

      }else{
        setState(() {
          _mensagemErro = "Preencha o E-mail valido";
        });
      }


    }else{
      setState(() {
        _mensagemErro = "Preencha o Nome";
      });
    }

  }

  _cadastrarUsuario(Usuario usuario){

    FirebaseAuth auth = FirebaseAuth.instance;
    Firestore db = Firestore.instance;

    auth.createUserWithEmailAndPassword(email: usuario.email, password: usuario.senha).then((firebaseUser){
      db.collection("usuarios").document(firebaseUser.user.uid).setData(usuario.toMap());

      Navigator.pushNamedAndRemoveUntil( //remove a opcao de voltar
          context,
          "/painel-motorista",
              (_)=>false
      );


    }).catchError((error){
      _mensagemErro = "Erro ao autenticar usuario, verifique e-mail e senha e tente novamente!";
    });

  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: Text("Cadastro"),
      ),
      body: Container(

        padding: EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[ //vai o logo e as caixas de textos
                TextField(
                  controller: _controleNome,
                  autofocus: true,
                  keyboardType: TextInputType.text,
                  style: TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                      hintText: "Nome Completo",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6)
                      )
                  ),
                ),
                SizedBox(height: 16,), //espacamento de 16 de altura
                TextField(
                  controller: _controleEmail,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                      hintText: "E-mail",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6)
                      )
                  ),
                ),
                SizedBox(height: 16,), //espacamento de 16 de altura
                TextField(
                  controller: _controlesenha,
                  obscureText: true, //mascara a senha
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                      hintText: "Senha",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6)
                      )
                  ),
                ),

                Padding(
                  padding: EdgeInsets.only(top: 16,bottom: 10),
                  child: RaisedButton(
                    child: Text("Cadastrar",style: TextStyle(color: Colors.white,fontSize: 20),),
                    color: Color(0xff1ebbd8),
                    padding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                    onPressed: (){
                   _validarCampos();
                    },
                  ),
                ),

                Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(
                    child: Text(_mensagemErro,style: TextStyle(color:Colors.red,fontSize: 20),),
                  ),
                )
              ],
            ),
          ),
        ),
      ),

    );
  }
}
