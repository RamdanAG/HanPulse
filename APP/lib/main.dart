import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:message/viewmodels/auth_viewmodel.dart';
import 'package:message/viewmodels/message_viewmodel.dart';
import 'package:message/views/chat_view.dart';
import 'package:message/views/login_view.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  final key = await SharedPreferences.getInstance();
  final statusLogin = key.getBool('statusLogin') ?? false;
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => AuthViewmodel()),
    ChangeNotifierProvider(create: (_) => MessageViewmodel())
  ], child: MyApp(status: statusLogin,),));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.status});
  final bool status;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Chat App",
      home: status ? ChatView() : LoginView(),
    );
  }
}

//php artisan serve --host=0.0.0.0 --port=8000
// {'Content-Type': 'application/json'}
// http://192.168.1.245:8000
//192.168.1.245 cek dengan ipconfig di cmd
//http://10.0.2.2:8000/api khusus emulator

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return const Placeholder();
//   }
// }