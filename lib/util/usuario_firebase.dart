
import 'package:alpha_car_motorista/modelo/usuario.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class USuarioFirebase {


  //Metodo statico para pegar o usuario logado
  static Future<FirebaseUser> getUsuarioAtual() async {

    FirebaseAuth auth = FirebaseAuth.instance;
    return await auth.currentUser();


  }

  //Metodo statico para pegar os dados do usuario logado
  static Future<Usuario> getDadosUsuarioLogado() async {


    FirebaseUser firebaseUser = await getUsuarioAtual();
    String idUsuario = firebaseUser.uid;
    Firestore db = Firestore.instance;

    DocumentSnapshot snapshot = await db.collection("usuarios").document(idUsuario).get();

    Map<String,dynamic> dados = snapshot.data;
    String tipoUsuario = dados["tipoUsuario"];
    String email = dados["email"];
    String nome = dados["nome"];

    Usuario usuario = Usuario();
    usuario.idUsuario = idUsuario;
    usuario.tipoUsuario = tipoUsuario;
    usuario.email = email;
    usuario.nome = nome;

    return usuario;


  }

  static atualizarDadosLocalizacao(String idRequisicao,double lat,double long) async{

    Firestore db = Firestore.instance;

    Usuario motorista = await getDadosUsuarioLogado();
    motorista.latitude = lat;
    motorista.longitude = long;

    db.collection("requisicoes").document(idRequisicao).updateData({
      "motorista":motorista.toMap()
    });

  }


}
