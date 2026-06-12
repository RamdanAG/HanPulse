import 'package:flutter/material.dart';
import 'package:message/services/api_service.dart';
import 'package:message/services/websocket_service.dart';

class AuthViewmodel extends ChangeNotifier {
  final _apiService = ApiService();
  final _websocketService = WebsocketService();
  bool isLoading = false;
  String? message;

  Future<bool> login(String email, String password)async{
    isLoading = true;
    message = null;
    notifyListeners();
    final response = await _apiService.login(email, password);
    if(response['success'] == true){
      _websocketService.connect();
    }
    isLoading = false;
    message = (response['success'] as bool) ? "${response['message']}, Selamat datang ${response['data']['name']}" : response['message'];
    notifyListeners();
    return(response['success'] as bool);
  }

  Future<bool> register(String name, String email, String password, String? profilePath)async{
    isLoading = true;
    message = null;
    notifyListeners();
    final response = await _apiService.register(name, email, password, profilePath);
    if(response['success'] == true){
      _websocketService.connect();
    }
    isLoading = false;
    message = (response['success'] as bool) ? "${response['message']}, Selamat datang ${response['data']['name']}" : response['message'];
    notifyListeners();
    return(response['success'] as bool);
  }
  
  void initWebscoket(){
    _websocketService.connect();
  }
}