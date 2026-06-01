import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:message/models/user.dart';

class ApiService {
  final dio = Dio(
    BaseOptions(
      baseUrl: "http://127.0.0.1:8000/api",
      sendTimeout: Duration(seconds: 20),
      receiveTimeout: Duration(seconds: 20),
    )
  );

  ApiService(){
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async{
        final key = await SharedPreferences.getInstance();
        final token = key.getString("token");
        if(token != null){
          options.headers['Authorization'] = "Bearer $token";
        }
        handler.next(options);
      },
    ));
  }

  Future<Map<String, dynamic>> login(String email, String password)async{
    try{
      final response = await dio.post("/login", data: {
        "email": email,
        "password": password
      });

      if(response.data['success'] == true && response.statusCode == 200){
        final key = await SharedPreferences.getInstance();
        await key.setString("token", response.data['data']['token']);
        await key.setBool("statusLogin", true);
      }
      return response.data;
    }on DioException catch(e){
      return{
        "success": false,
        "message": e.response?.data['message'].toString() ?? "Terjadi kesalahan"
      };
    }
  }

  Future<Map<String, dynamic>> register(String name, String email, String password, String? profilePath)async{
    try{
      MultipartFile? profileFile;
      if(profilePath != null){
        profileFile = await MultipartFile.fromFile(profilePath);
      }
      final request = FormData.fromMap({
        "name": name,
        "email": email,
        "password": password,
        if(profilePath != null)
        "profile": profileFile
      });
      final response = await dio.post('/register', data: request);
      if(response.data['success'] == true && response.statusCode == 201){
        final key = await SharedPreferences.getInstance();
        await key.setString("token", response.data['data']['token']);
        await key.setBool("statusLogin", true);
      }
      return response.data;
    }on DioException catch(e){
      return{
        "success": false,
        "message": e.response?.data['message'].toString() ?? "Terjadi kesalahan"
      };
    }
  }

  Future<User> currentUser()async{
    try{
      final response = await dio.get('/user');
      return User.fromJson(response.data);
    }on DioException catch(e){
      throw Exception(e);
    }
  }

  Future<List<User>> getAllUser()async{
    try{
      final response = await dio.get('/message');
      return (response.data['data'] as List).map((item) => User.fromJson(item)).toList();
    }on DioException catch(e){
      throw Exception(e.response);
    }
  }

  Future<Map<String, dynamic>> getAllMessage(int receiverId)async{
    try{
      final response = await dio.get('/message/$receiverId');
      return response.data;
    }on DioException catch(e){
      return{
        "success": false,
        "message": e.response?.data['message'].toString() ?? "Terjadi kesalahan"
      };
    }
  }

  Future<Map<String, dynamic>> sendMessage(int chatRoomId, String message, String? imagePath)async{
    try{
      MultipartFile? imageFile;
      if(imagePath != null){
        imageFile = await MultipartFile.fromFile(imagePath);
      }
      final request = FormData.fromMap({
        "chat_room_id": chatRoomId,
        "message": message,
        if(imagePath != null)
        "image": imageFile
      });
      final response = await dio.post("/message", data: request);
      return response.data;
    }on DioException catch(e){
      return{
        "success": false,
        "message": e.response?.data['message'].toString() ?? "Terjadi kesalahan"
      };
    }
  }

  Future<Map<String, dynamic>> authBroadcast(String? socketId, String? channelName)async{
    try{
      final response = await dio.post('/broadcasting/auth', data: {
        "socket_id": socketId,
        "channel_name": channelName
      });
      return response.data;
    }on DioException catch(e){
      throw Exception(e);
    }
  }
}