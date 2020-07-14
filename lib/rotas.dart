import 'package:alpha_car_motorista/telas/Home.dart';
import 'package:alpha_car_motorista/telas/cadastro.dart';
import 'package:alpha_car_motorista/telas/corrida.dart';
import 'package:alpha_car_motorista/telas/painel_motorista.dart';
import 'package:flutter/material.dart';


class Rotas {
  static Route<dynamic> gerarRotas(RouteSettings settings) {

    final argumentos = settings.arguments;

    switch (settings.name) {
      case "/":
        return MaterialPageRoute(builder: (_) => Home());
      case "/cadastro":
        return MaterialPageRoute(builder: (_) => Cadastro());
      case "/painel-motorista":
        return MaterialPageRoute(builder: (_) => PainelMotorista());
      case "/corrida":
        return MaterialPageRoute(builder: (_) => Corrida(argumentos));
      default:
        _erroRota();
    }
  }

  static Route<dynamic> _erroRota(){

    return MaterialPageRoute(
      builder: (_){
        return Scaffold(
          appBar: AppBar(title: Text("Tela nao encontrada!"),),
          body: Center(
            child: Text("Tela Nao Encontrada"),
          ),
        );
      }
    );

  }

}
