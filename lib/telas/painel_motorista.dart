import 'dart:async';

import 'package:alpha_car_motorista/util/status_requisicao.dart';
import 'package:alpha_car_motorista/util/usuario_firebase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class PainelMotorista extends StatefulWidget {
  @override
  _PainelMotoristaState createState() => _PainelMotoristaState();
}

class _PainelMotoristaState extends State<PainelMotorista> {

  List<String> itensMenu = [
    "Configuracoes","Deslogar"

  ];

  //Controlador
  final _controller = StreamController<QuerySnapshot>.broadcast();
  StreamSubscription<QuerySnapshot> _streamSubscriptionRequisicoes;

  //Firestore
  Firestore db = Firestore.instance;

  _deslogarUSuario() async{
    FirebaseAuth auth = FirebaseAuth.instance;
    await auth.signOut();
    Navigator.pushReplacementNamed(context, "/");
  }

  _escolhaMenuItem(String escolha){

    switch(escolha){
      case "Deslogar":
        _deslogarUSuario();
        break;
      case "Configuracoes":

        break;

    }

  }


  Stream<QuerySnapshot> _adicionarListenerRequisicoes(){

    final stream = db.collection("requisicoes").where("status",isEqualTo: StatusRequisicao.AGUARDANDO).snapshots();
    _streamSubscriptionRequisicoes = stream.listen((dados) {
     _controller.add(dados);
   });

  }


  _recuperaRequisicaoAtivaMotorista() async{

    //Recupera dados do usuario Logado
    FirebaseUser firebaseUser = await USuarioFirebase.getUsuarioAtual();


    //Recupera requisicao ativa
    DocumentSnapshot documentSnapshot = await db.collection("requisicao_ativa_motorista").document(firebaseUser.uid).get();

    var dadosRequisicao = documentSnapshot.data;
    if(dadosRequisicao == null){
      _adicionarListenerRequisicoes();
    }else{
      String idRequisicao = dadosRequisicao["id_requisicao"];
      Navigator.pushReplacementNamed(context,"/corrida",arguments:idRequisicao ); //nao tem um botao para retornar a tela anterior
    }

  }

  @override
  void initState() {
    super.initState();



    //Recuperar requisicao ativa para verificar se o motorista está
    //atendendo alguma requisicao e envia para a tela de corrida
    _recuperaRequisicaoAtivaMotorista();

  }

  @override
  Widget build(BuildContext context) {

    var mensagemCarregando = Center(
      child: Column(
        children: <Widget>[
          Text("carregando requisicoes"),
          CircularProgressIndicator(),
        ],
      ),
    );

    var mensagemNaoTemDados = Center(
      child: Text("Voce nao tem nenhuma requisicao!",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text("Painel motorista"),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: _escolhaMenuItem,
            itemBuilder: (context){
              return itensMenu.map((String item) {

                return PopupMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList();
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _controller.stream,
        builder: (context,snapshot){

          switch(snapshot.connectionState){
            case ConnectionState.none:
            case ConnectionState.waiting:
              return mensagemCarregando;
              break;
            case ConnectionState.active:
            case ConnectionState.done:

              if(snapshot.hasError){
                return Text("erro ao carregar os dados!");
              }else{
                QuerySnapshot querySnapshot = snapshot.data;

                if(querySnapshot.documents.length == 0){
                return  mensagemNaoTemDados;
                }else{
                  return ListView.separated(
                      itemCount: querySnapshot.documents.length,
                      separatorBuilder: (context,indece)=>Divider(
                        height: 2,
                        color: Colors.grey,
                      ),
                      itemBuilder: (context,indice){

                       List<DocumentSnapshot> requisicoes = querySnapshot.documents.toList();
                       DocumentSnapshot item = requisicoes[indice];

                       //Recupera dados que serao mostrados para o motorista
                        String idrequisicao = item["id"];
                        String nomePassageiro = item["passageiro"]["nome"]; //primero documento // depois atributo
                       String rua = item["destino"]["rua"]; //primero documento // depois atributo
                       String numero = item["destino"]["numero"]; //primero documento // depois atributo

                        return ListTile(
                          title: Text(nomePassageiro),
                          subtitle: Text("destino: $rua, $numero"),
                          onTap: (){
                            //Navega para a tela de corrida atraves da rota nomeada
                           Navigator.pushNamed(context,
                           "/corrida",arguments: idrequisicao
                           );
                          },
                        );

                      }


                  );
                }
              }


              break;
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _streamSubscriptionRequisicoes.cancel();
  }
}
