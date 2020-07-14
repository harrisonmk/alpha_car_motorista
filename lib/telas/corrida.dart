import 'dart:async';
import 'dart:io';

import 'package:alpha_car_motorista/modelo/usuario.dart';
import 'package:alpha_car_motorista/util/status_requisicao.dart';
import 'package:alpha_car_motorista/util/usuario_firebase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';



class Corrida extends StatefulWidget {


  String idRequisicao;
  //Construtor
  Corrida(this.idRequisicao);

  @override
  _CorridaState createState() => _CorridaState();
}

class _CorridaState extends State<Corrida> {


  Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _marcadores = {};
  Map<String,dynamic> _dadosRequisicao;
  String _idRequisicao;
  Position _localMotorista;
  String _statusRequisicao = StatusRequisicao.AGUARDANDO;
  StreamSubscription<DocumentSnapshot> _streamSubscriptionRequisicoes;
  Set<Polyline> _polylines = {};



  CameraPosition _posicaoCamera = CameraPosition(
    target: LatLng(-19.009216, -57.631160),
  );

  //Controles para exibicao na tela
  String _textoBotao = "Aceitar Corrida";
  Color _corBotao = Color(0xff1ebbd8);
  Function _funcaoBotao;
  String _mensagemStatus = "";


  _alterarBotaoPrincipal(String texto,Color cor,Function funcao){

    setState(() {
      _textoBotao = texto;
      _corBotao = cor;
      _funcaoBotao = funcao;
    });

  }

  _onMapCreated(GoogleMapController controle){

    _controller.complete(controle);

  }


  _adicionarListenerLocalizacao(){

    var geolocator = Geolocator();
    var locationOptions = LocationOptions(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10
    );

    geolocator.getPositionStream(locationOptions).listen((Position position){

      if(position != null){

        if(_idRequisicao != null && _idRequisicao.isNotEmpty){

          if(_statusRequisicao != StatusRequisicao.AGUARDANDO){

            //Atualiza local do passageiro
            USuarioFirebase.atualizarDadosLocalizacao(_idRequisicao,position.latitude, position.longitude);

          }else{//aguardando
            setState(() {
              _localMotorista = position;
            });
            _statusAguardando();
          }


        }

      }

    });

  }

  //TODO: ARRUMAR PARA PEGAR A LOCALIZACAO DO MOTORISTA
  //TODO: ja esta pegando
  _recuperarUltimaLocalizacaoConhecida()async{

    Position posicao = await Geolocator().getLastKnownPosition(desiredAccuracy: LocationAccuracy.high);

    if(posicao != null){

      //Atualizar localizacao em tempo real do motorista
      _exibirMarcador(posicao,"imagens/motorista.png","Motorista"); //TODO:TROCAR O MOTORISTA PELO NOME DO MOTORISTA
      _posicaoCamera = CameraPosition(
          target: LatLng(posicao.latitude,posicao.longitude),
          zoom: 19
      );
      _localMotorista = posicao;
      _movimentarCamera(_posicaoCamera);

    }

  }

  _movimentarCamera(CameraPosition cameraposicao)async{

    GoogleMapController googleMapController = await _controller.future;
    googleMapController.animateCamera(
      CameraUpdate.newCameraPosition(
          cameraposicao
      ),
    );

  }

  //exibe o marcador do motorista
  _exibirMarcador(Position local,String icone,String infoWindow) async{

    Usuario usu = await USuarioFirebase.getDadosUsuarioLogado();

    double pixelRatio = MediaQuery.of(context).devicePixelRatio;

    BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: pixelRatio),
        icone
    ).then((BitmapDescriptor bitmapDescriptor){

      Marker marcador = Marker(
          markerId: MarkerId(icone),
          position: LatLng(local.latitude,local.longitude),
          infoWindow: InfoWindow(
              title: usu.nome  //exibe o nome do usuario no icone
          ),
          icon:bitmapDescriptor

      );

      setState(() {
        _marcadores.add(marcador);
      });

    });



  }


  _recuperarRequisicao() async{

    String idRequisicao = widget.idRequisicao;

    Firestore db = Firestore.instance;
    DocumentSnapshot documentSnapshot = await db.collection("requisicoes").document(idRequisicao).get(); //com o get recupera o dados apenas uma vez




  }

  _adcionarListenerRequisicao() async{

    Firestore db = Firestore.instance;

    _streamSubscriptionRequisicoes = await db.collection("requisicoes").document(_idRequisicao).snapshots().listen((snapshot){
      if(snapshot.data != null){

        _dadosRequisicao = snapshot.data;

        Map<String,dynamic> dados = snapshot.data;
        _statusRequisicao = dados["status"];

        switch(_statusRequisicao){
          case StatusRequisicao.AGUARDANDO:
            _statusAguardando();
            break;
          case StatusRequisicao.A_CAMINHO:
            _statusACaminho();
            break;
          case StatusRequisicao.VIAGEM:
            _statusEmViagem();
            break;
          case StatusRequisicao.FINALIZADA:
             _statusFinalizada();
            break;
          case StatusRequisicao.CONFIRMADA:
            _statusConfirmada();
            break;
        }


      }
    });


  }

  _statusAguardando(){



    //Metodo
    _alterarBotaoPrincipal("Aceitar corrida",Color(0xff1ebbd8),(){
      _aceitarCorrida();
    });

    if(_localMotorista != null){

      double motoristaLat = _localMotorista.latitude;
      double motoristaLong = _localMotorista.longitude;


      Position position = Position(
          latitude: motoristaLat,
          longitude:motoristaLong
      );

      _exibirMarcador(position,"imagens/motorista.png","Motorista");
      CameraPosition  cameraPosition = CameraPosition(
          target: LatLng(position.latitude,position.longitude),
          zoom: 19
      );
      _movimentarCamera(cameraPosition);
    }



  }


  _statusACaminho(){

    _mensagemStatus = "A caminho do passageiro";
    _alterarBotaoPrincipal("Iniciar Corrida", Color(0xff1ebbd8),(){
      _iniciarCorrida();
    });


    double latitudePassageiro = _dadosRequisicao["passageiro"]["latitude"];
    double longitudePassageiro = _dadosRequisicao["passageiro"]["longitude"];

    double latitudeMotorista = _dadosRequisicao["motorista"]["latitude"];
    double longitudeMotorista = _dadosRequisicao["motorista"]["longitude"];



    //Exibir dois marcadores
    _exibirDoisMArcadores(LatLng(latitudeMotorista,longitudeMotorista),LatLng(latitudePassageiro,longitudePassageiro));

    var nLat,nLong,sLat,sLong;

     if(latitudeMotorista <= latitudePassageiro){
       sLat = latitudeMotorista;
       nLat = latitudePassageiro;
     }else{

       sLat = latitudePassageiro;
       nLat = latitudeMotorista;

     }


    if(longitudeMotorista <= longitudePassageiro){
      sLong = longitudeMotorista;
      nLong = longitudePassageiro;
    }else{

     sLong = longitudePassageiro;
      nLong = longitudeMotorista;

    }

    _movimentarCameraBounds(LatLngBounds(
        northeast: LatLng(nLat,nLong), //nordeste
        southwest:LatLng(sLat,sLong) //sudoeste
    )
    );

  }

  _finalizarCorrida(){

    Firestore db = Firestore.instance;
    db.collection("requisicoes").document(_idRequisicao).updateData({
      "status":StatusRequisicao.FINALIZADA
    });


    String idPassageiro = _dadosRequisicao["passageiro"]["idUsuario"];
    db.collection("requisicao_ativa").document(idPassageiro).updateData({
      "status":StatusRequisicao.FINALIZADA
    });

    String idMotorista = _dadosRequisicao["motorista"]["idUsuario"];
    db.collection("requisicao_ativa_motorista").document(idMotorista).updateData({
      "status":StatusRequisicao.FINALIZADA
    });


  }


  //TODO:TENTAR COLOCAR A API DIRECTIONS DEPOIS
  _statusFinalizada() async{


    //Calcula valor da corrida
    double latitudeDestino = _dadosRequisicao["destino"]["latitude"];
    double longitudeDestino = _dadosRequisicao["destino"]["longitude"];

    double latitudeOrigem = _dadosRequisicao["origem"]["latitude"];
    double longitudeOrigem = _dadosRequisicao["origem"]["longitude"];

    double distanciaEmMetros = await Geolocator().distanceBetween(
        latitudeOrigem,
        longitudeOrigem,
        latitudeDestino,
        longitudeDestino
    );

    //Converte pra KM
    double distanciaKm = distanciaEmMetros / 1000;

    //8 reais eh o valor cobrado por KM
     double valorViagem = distanciaKm * 8;

     //Formatar valor viagem
     var valorFormatado = new NumberFormat("#,##0.00","pt_BR");
     var valorViagemFormatado = valorFormatado.format(valorViagem);


    _mensagemStatus = "Viagem Finalizada";
    _alterarBotaoPrincipal("Confirmar -R\$ ${valorViagemFormatado}", Color(0xff1ebbd8),(){
      _confirmaCorrida();
    });

    _marcadores = {};
    Position position = Position(
        latitude: latitudeDestino,
        longitude:longitudeDestino
    );

    _exibirMarcador(position,"imagens/destino.png","Destino"); //TODO: colocar o nome do destino aqui
    CameraPosition  cameraPosition = CameraPosition(
        target: LatLng(position.latitude,position.longitude),
        zoom: 19
    );
    _movimentarCamera(cameraPosition);


  }


  _statusConfirmada(){

    Navigator.pushReplacementNamed(context,"/painel-motorista");


  }


  _confirmaCorrida(){

    Firestore db = Firestore.instance;
    db.collection("requisicoes").document(_idRequisicao).updateData({

      "status":StatusRequisicao.CONFIRMADA
    });

    String idPassageiro = _dadosRequisicao["passageiro"]["idUsuario"];
    db.collection("requisicao_ativa").document(idPassageiro).delete();


    String idMotorista = _dadosRequisicao["motorista"]["idUsuario"];
    db.collection("requisicao_ativa_motorista").document(idMotorista)..delete();

  }


  _statusEmViagem(){

    _mensagemStatus = "Em Viagem";
    _alterarBotaoPrincipal("Finalizar Corrida", Color(0xff1ebbd8),(){
      _finalizarCorrida();
    });


    double latitudeDestino = _dadosRequisicao["destino"]["latitude"];
    double longitudeDestino = _dadosRequisicao["destino"]["longitude"];

    double latitudeOrigem = _dadosRequisicao["motorista"]["latitude"];
    double longitudeOrigem = _dadosRequisicao["motorista"]["longitude"];



    //Exibir dois marcadores
    _exibirDoisMArcadores(LatLng(latitudeOrigem,longitudeOrigem),LatLng(latitudeDestino,longitudeDestino));

    var nLat,nLong,sLat,sLong;

    if(latitudeOrigem <= latitudeDestino){
      sLat = latitudeOrigem;
      nLat = latitudeDestino;
    }else{

      sLat = latitudeDestino;
      nLat = latitudeOrigem;

    }


    if(longitudeOrigem <= longitudeDestino){
      sLong = longitudeOrigem;
      nLong = longitudeDestino;
    }else{

      sLong = longitudeDestino;
      nLong = longitudeOrigem;

    }

    _movimentarCameraBounds(LatLngBounds(
        northeast: LatLng(nLat,nLong), //nordeste
        southwest:LatLng(sLat,sLong) //sudoeste
    )
    );

  }

  _iniciarCorrida(){

    Firestore db = Firestore.instance;
    db.collection("requisicoes").document(_idRequisicao).updateData({
      "origem":{ //ponde de onde o motorista saiu com o passageiro
        "latitude":_dadosRequisicao["motorista"]["latitude"],
        "longitude":_dadosRequisicao["motorista"]["longitude"]
      },
       "status":StatusRequisicao.VIAGEM
    });

    String idPassageiro = _dadosRequisicao["passageiro"]["idUsuario"];
    db.collection("requisicao_ativa").document(idPassageiro).updateData({
      "status":StatusRequisicao.VIAGEM
    });

    String idMotorista = _dadosRequisicao["motorista"]["idUsuario"];
    db.collection("requisicao_ativa_motorista").document(idMotorista).updateData({
      "status":StatusRequisicao.VIAGEM
    });


  }


  //cria um quadrado entre os dois marcadores
  _movimentarCameraBounds(LatLngBounds latLngBounds)async{

    GoogleMapController googleMapController = await _controller.future;
    googleMapController.animateCamera(
      CameraUpdate.newLatLngBounds(latLngBounds, 100) //100 eh o padding entre o marcador e o canto da tela
    );

  }


  //Metodo para exibir dois marcadores o de motorista e passageiro
  _exibirDoisMArcadores(LatLng latLngMotorista,LatLng latLngPassageiro)async{

    Set<Marker> _listaMarcadores = {};

    Usuario usu = await USuarioFirebase.getDadosUsuarioLogado();

    double pixelRatio = MediaQuery.of(context).devicePixelRatio;

    BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: pixelRatio),
        "imagens/motorista.png"
    ).then((BitmapDescriptor icone){

      Marker marcador1 = Marker(
          markerId: MarkerId("marcador-motorista"),
          position: LatLng(latLngMotorista.latitude,latLngMotorista.longitude),
          infoWindow: InfoWindow(
              title: usu.nome  //exibe o nome do usuario no icone
          ),
          icon:icone

      );
         _listaMarcadores.add(marcador1);




    });


    BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: pixelRatio),
        "imagens/passageiro.png"
    ).then((BitmapDescriptor icone){

      Marker marcador2 = Marker(
          markerId: MarkerId("marcador-passageiro"),
          position: LatLng(latLngPassageiro.latitude,latLngPassageiro.longitude),
          infoWindow: InfoWindow(
              title: usu.nome  //exibe o nome do usuario no icone
          ),
          icon:icone

      );
      _listaMarcadores.add(marcador2);


    });

    setState(() {
      _marcadores = _listaMarcadores;

    });


    Set<Polyline> listaPolylines = {};
    Polyline polyline = Polyline(
        polylineId: PolylineId("polyline"),
        color: Colors.black,
        width: 8,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
        points: [
          LatLng(latLngMotorista.latitude,latLngMotorista.longitude),
          LatLng(latLngPassageiro.latitude,latLngPassageiro.longitude)
        ],


    );

    listaPolylines.add( polyline );
    setState(() {
      _polylines = listaPolylines;
    });


  }


  _aceitarCorrida() async{

    //Recuperar dados do motorista
    Usuario motorista = await USuarioFirebase.getDadosUsuarioLogado();
    motorista.latitude = _localMotorista.latitude;
    motorista.longitude = _localMotorista.longitude;


    Firestore db = Firestore.instance;
    String idRequisicao = _dadosRequisicao["id"];

    db.collection("requisicoes").document(idRequisicao).updateData({
      "motorista":motorista.toMap(),
      "status":StatusRequisicao.A_CAMINHO,
    }).then((_){

      //atualiza requisicao ativa
      String idPassageiro = _dadosRequisicao["passageiro"]["idUsuario"]; //Acessa o documento passageiro e o atributo dentro dele idUsuario
      db.collection("requisicao_ativa").document(idPassageiro).updateData({
        "status":StatusRequisicao.A_CAMINHO,
      });

      //Salva a requisicao ativa para o motorista
      String idMotorista = motorista.idUsuario;
      db.collection("requisicao_ativa_motorista").document(idMotorista).setData({
        "id_requisicao":idRequisicao,
        "id_usuario":idMotorista,
        "status":StatusRequisicao.A_CAMINHO,
      });


    });


  }


  @override
  void initState() {

    super.initState();



    _idRequisicao = widget.idRequisicao;

    //Adicionar listener para mudancas na requisicao
    _adcionarListenerRequisicao();

    _recuperarUltimaLocalizacaoConhecida();//Estava comentado
    _adicionarListenerLocalizacao();



    //_recuperarRequisicao();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Painel Corrida - "+ _mensagemStatus),

      ),
      body: Container(

        child: Stack(
          children: <Widget>[
            GoogleMap( //TODO:alterar aqui depois
              mapType: MapType.normal,
              initialCameraPosition: _posicaoCamera,
              onMapCreated:_onMapCreated,
              //myLocationEnabled: true,
              myLocationButtonEnabled: false, //tira o botaozinho de centralizar minha localizacao
              markers: _marcadores,
              polylines: _polylines,
            ),



            Positioned(
              right: 0,
              left: 0,
              bottom: 0,
              child: Padding(
                padding: Platform.isIOS ? EdgeInsets.fromLTRB(20, 10, 20, 25) : EdgeInsets.all(10),
                child: RaisedButton(
                  child: Text(_textoBotao,style: TextStyle(color: Colors.white,fontSize: 20),),
                  color: _corBotao,
                  padding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                  onPressed: _funcaoBotao,
                ),
              ),
            )
          ],
        ),

      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _streamSubscriptionRequisicoes.cancel();
  }
}

