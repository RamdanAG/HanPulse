import 'dart:async';
import 'dart:convert';
import 'package:message/services/api_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebsocketService {
  static final WebsocketService _instance = WebsocketService._internal();
  factory WebsocketService(){
    return _instance;
  }
  WebsocketService._internal();

  final _apiService = ApiService();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _presenceSyncController = StreamController<Map<String, dynamic>>.broadcast();
  final _memberJoinController = StreamController<Map<String, dynamic>>.broadcast();
  final _memberLeftController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageEvent => _messageController.stream;
  Stream<Map<String, dynamic>> get presenceSyncEvent => _presenceSyncController.stream;
  Stream<Map<String, dynamic>> get memberJoinEvent => _memberJoinController.stream;
  Stream<Map<String, dynamic>> get memberLeftEvent => _memberLeftController.stream;
  Stream<Map<String, dynamic>> get typingEvent => _typingController.stream;
  bool isTyping = false;
  String? socketId;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _isConnected = false;
  int? _chatRoomId;

  void connect(){
    if(_isConnected) return;
    final wsUrl = "ws://127.0.0.1:8080/app/zbbjjhv6fdikxza9xzfk";
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    _subscription = _channel?.stream.listen((event){
      final data = jsonDecode(event);
      print("Data Event: $data");

      if(data['event'] == "pusher:connection_established"){
        _isConnected = true;
        final socketData = jsonDecode(data['data']);
        socketId = socketData['socket_id'];
      }

      if(data['event'] == "pusher:ping"){
        _channel?.sink.add(jsonEncode({
          "event": "pusher:pong",
          "data": {}
        }));
      }

      if(data['event'] == "pusher_internal:subscription_succeeded"){
        print("Subscribe Berhasil");
        final presenceData = jsonDecode(data['data']);
        final member = presenceData['presence']['hash'];
        _presenceSyncController.add(Map<String, dynamic>.from(member));
      }

      if(data['event'] == "pusher_internal:member_added"){
        final member = jsonDecode(data['data']);
        _memberJoinController.add(Map<String, dynamic>.from(member));
      }

      if(data['event'] == "pusher_internal:member_removed"){
        final member = jsonDecode(data['data']);
        _memberLeftController.add(Map<String, dynamic>.from(member));
      }

      if(data['event'] == "chatUpdate"){
        final payload = jsonDecode(data['data']);
        _messageController.add(Map<String, dynamic>.from(payload));
      }

      if(data['event'] == "client-send-typing"){
        final typingData = data['data'] is String ? jsonDecode(data['data']) : data['data'];
        if(isTyping == typingData['is_typing']) return;
        isTyping = typingData['is_typing'];
        _typingController.add(Map<String, dynamic>.from(typingData));
      }
    },
    onDone: () {
      _isConnected = false;
      _reconnect();
    },
    onError: (e){
      _isConnected = false;
      _reconnect();
    });
  }

  void _reconnect()async{
    connect();
    if(_chatRoomId == null) return;
    Future.delayed(Duration(seconds: 5), ()async{
      await subscribeChatRoom(_chatRoomId!);
    });
  }

  void sendTyping(int chatRoomId, bool isTyping){
    _channel?.sink.add(jsonEncode({
      "event": "client-send-typing",
      "channel": "presence-chat-room-$chatRoomId",
      "data": jsonEncode({
        "is_typing": isTyping
      })
    }));
  }

  Future<void> subscribeChatRoom(int chatRoomId)async{
    _chatRoomId = chatRoomId;
    final response = await _apiService.authBroadcast(socketId, "presence-chat-room-$chatRoomId");
    _channel?.sink.add(jsonEncode({
      "event": "pusher:subscribe",
      "data": {
        "channel": "presence-chat-room-$chatRoomId",
        "auth": response['auth'],
        "channel_data": response['channel_data']
      }
    }));
  }

  void unsubscribeRoom(int chatRoomId){
    _channel?.sink.add(jsonEncode({
      "event": "pusher:unsubscribe",
      "data": {
        "channel": "presence-chat-room-$chatRoomId"
      }
    }));
    print("Unsubscriber Berhasil");
    isTyping = false;
    _chatRoomId = null;
  }

  void disconnect(){
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _chatRoomId = null;
  }
}