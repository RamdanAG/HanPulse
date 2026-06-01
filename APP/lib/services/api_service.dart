import 'package:dio/dio.dart';

class ApiService {
  final dio = Dio(
    BaseOptions(
      baseUrl: "http://127.0.0.1:8000/api",
      sendTimeout: Duration(seconds: 20),
      receiveTimeout: Duration(seconds: 20),
    )
  );

  ApiService(){}

  Future<Map<String, dynamic>> login(String email, String password)async{
    try{
      final response = await dio.post("/login", data: {
        "email": email,
        "password": password
      });
    }
  }
}