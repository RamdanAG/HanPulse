import 'package:message/models/user.dart';

class Message {
  final int id;
  final String message;
  final String? imagePath;
  final DateTime? createAt;
  final User user;

  Message({required this.id, required this.message, this.imagePath, this.createAt, required this.user});
  factory Message.fromJson(Map<String, dynamic> json){
    return Message(
      id: json['id'],
      message: json['message'],
      imagePath: json['image_path'],
      createAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      user: User.fromJson(json['user'])
    );
  }
}