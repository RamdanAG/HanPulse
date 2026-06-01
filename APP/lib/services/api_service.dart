import 'package:dio/dio.dart';

class ApiService {
  final dio = Dio(
    BaseOptions(
      baseUrl: "",
      sendTimeout: Duration(seconds: 10)
    )
  );
}