import 'dart:async';

import 'package:flutter/material.dart';
import 'package:message/models/message.dart';
import 'package:message/models/user.dart';
import 'package:message/services/api_service.dart';
import 'package:message/services/websocket_service.dart';

class MessageViewmodel extends ChangeNotifier {
  final _apiService = ApiService();
  final _websocketService = WebsocketService();
  bool isLoading = false;
  List<Message> messageList = [];
  List<User> userList = [];
  int? chatRoomId;
  User? currentUser;
  List<int> onlineUserIds = [];
  StreamSubscription? _messageEvent;
  StreamSubscription? _presenceEvent;
  StreamSubscription? _joinEvent;
  StreamSubscription? _leftEvent;
  StreamSubscription? _typingEvent;

  Future<void> fetchUser()async{
    isLoading = true;
    notifyListeners();
    currentUser = await _apiService.currentUser();
    userList = await _apiService.getAllUser();
    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMessage(int receiverId)async{
    isLoading = true;
    messageList = [];
    notifyListeners();
    final response = await _apiService.getAllMessage(receiverId);
    if(response['success'] == true){
      messageList = (response['data'] as List).map((item) => Message.fromJson(item)).toList();
      chatRoomId = response['chat_room_id'];
      _websocketService.subscribeChatRoom(response['chat_room_id']);
      _messageEvent?.cancel();
      _presenceEvent?.cancel();
      _joinEvent?.cancel();
      _leftEvent?.cancel();
      _typingEvent?.cancel();
      _messageEvent = _websocketService.messageEvent.listen((data) => _handleMessage(data));
      _presenceEvent = _websocketService.presenceSyncEvent.listen((member) => _handleMemberOnline(member));
      _joinEvent = _websocketService.memberJoinEvent.listen((member) => _handleMemberJoin(member));
      _leftEvent = _websocketService.memberLeftEvent.listen((member) => _handleMemberLeft(member));
      _typingEvent = _websocketService.typingEvent.listen((_) {
        notifyListeners();
      });
    }
    isLoading = false;
    notifyListeners();
  }

  void _handleMessage(Map<String, dynamic> data){
    final action = data['action'];
    final message = Message.fromJson(data['message']);
    if(action == "create"){
      messageList.add(message);
    }
    notifyListeners();
  }

  void _handleMemberOnline(Map<String, dynamic> member){
    onlineUserIds = member.values.map<int>((user) => user['id'] as int).toList();
    notifyListeners();
  }

  void _handleMemberJoin(Map<String, dynamic> member){
    final userId = int.parse(member['user_id'].toString());
    if(!onlineUserIds.contains(userId)){
      onlineUserIds.add(userId);
      notifyListeners();
    }
  }

  void _handleMemberLeft(Map<String, dynamic> member){
    final userId = int.parse(member['user_id'].toString());
    onlineUserIds.remove(userId);
    notifyListeners();
  }

  void unsubscribeRoom(){
    if(chatRoomId == null) return;
    _websocketService.unsubscribeRoom(chatRoomId!);
    chatRoomId = null;
  }

  void sendTyping(bool isTyping,){
    if(chatRoomId == null) return;
    _websocketService.sendTyping(chatRoomId!, isTyping);
  }

  bool isTypng() => _websocketService.isTyping;

  bool isOnline(int userId){
    return onlineUserIds.contains(userId);
  }

  Future<void> sendMessage(String message, String? imagePath)async{
    if(chatRoomId == null) return;
    final response = await _apiService.sendMessage(chatRoomId!, message, imagePath);
  }

  Future<void> updateMessage(int messageId, String message, String? imagePath)async{}
  Future<void> deleteMessage(int messageId)async{}

  @override
  void dispose() {
    super.dispose();
    _messageEvent?.cancel();
    _presenceEvent?.cancel();
    _joinEvent?.cancel();
    _leftEvent?.cancel();
    _typingEvent?.cancel();
  }
}