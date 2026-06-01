import 'dart:async';
import 'dart:io';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:message/models/message.dart';
import 'package:message/models/user.dart';
import 'package:message/viewmodels/message_viewmodel.dart';

class MessageView extends StatefulWidget {
  const MessageView({required this.sender, required this.receiver});
  final User sender;
  final User receiver;

  @override
  State<MessageView> createState() => _MessageViewState();
}

class _MessageViewState extends State<MessageView> {
  final Color primaryOrange = const Color(0xFFFF9800);
  final messageController = TextEditingController();
  File? gambar;
  bool isUpdate = false;
  int? messageId;
  Timer? typingTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask((){
      final messageVM = Provider.of<MessageViewmodel>(context, listen: false);
      messageVM.fetchMessage(widget.receiver.id);
    });
  }

  @override
  void dispose() {
    final messageVM = Provider.of<MessageViewmodel>(context, listen: false);
    messageVM.unsubscribeRoom();
    super.dispose();
  }

  void _picked()async{
    final pickedFile = await FilePicker.platform.pickFiles(type: FileType.image);
    if(pickedFile?.files.first.path != null){
      setState(() {
        gambar = File(pickedFile!.files.first.path!);
      });
    }
  }

  void onTyping(String value){
    final messageVM = Provider.of<MessageViewmodel>(context, listen: false);
    messageVM.sendTyping(true);
    typingTimer?.cancel();
    typingTimer = Timer(Duration(seconds: 2), (){
      messageVM.sendTyping(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final messageVM = Provider.of<MessageViewmodel>(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        centerTitle: false,
        elevation: 1,
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          children: [
            BackButton(color: Colors.white),
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: widget.receiver.profilePath != null
              ? CachedNetworkImage(
                  imageUrl:
                      "http://127.0.0.1:8000/storage/${widget.receiver.profilePath}",
                  fit: BoxFit.cover,
                  width: 46,
                  height: 46,
                  errorWidget: (context, url, error) =>
                      Icon(Icons.person, size: 46, color: Colors.white24),
                )
              : Icon(Icons.person, size: 46, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.receiver.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                messageVM.isTypng()
                ? AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text("${widget.receiver.name} sedang mengetik...",
                      key: ValueKey("${widget.receiver.name} sedang mengetik..."),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : SizedBox(
                    width: MediaQuery.of(context).size.width - 220,
                    child: Text(
                      messageVM.isOnline(widget.receiver.id) ? "Online" : "Offline",
                      style: TextStyle(
                        fontSize: 12,
                        color: messageVM.isOnline(widget.receiver.id) ? Colors.greenAccent : Colors.white70,
                      ),
                    )
                  )
              ],
            )
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.local_phone),
            onPressed: () {},
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {},
            color: Colors.white,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => messageVM.fetchMessage(widget.receiver.id),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                itemCount: messageVM.messageList.length,
                // show message from older to newer. If your API returns newest first,
                // you might want to reverse the list or change index access.
                itemBuilder: (context, index) {
                  final msg = messageVM.messageList[index];
                  final isMe = msg.user.id == widget.sender.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment:
                          isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMe) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: msg.user.profilePath != null
                                ? CachedNetworkImage(
                                    imageUrl:
                                        "http://127.0.0.1:8000/storage/${msg.user.profilePath}",
                                    width: 36,
                                    height: 36,
                                    fit: BoxFit.cover,
                                    errorWidget: (c, u, e) =>
                                        Container(width: 36, height: 36, color: Colors.grey),
                                  )
                                : Container(
                                    width: 36,
                                    height: 36,
                                    color: Colors.grey.shade300,
                                    child: const Icon(Icons.person, size: 20),
                                  ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: _ChatBubble(
                            message: msg,
                            isMe: isMe,
                            orange: primaryOrange,
                            onUpdate: () {
                              setState(() {
                                messageController.text = msg.message;
                                messageId = msg.id;
                                isUpdate = true;
                              });
                            },
                            onDelete: () {
                              AwesomeDialog(
                                context: context,
                                dialogType: DialogType.warning,
                                animType: AnimType.bottomSlide,
                                dismissOnTouchOutside: false,
                                title: "Hapus",
                                desc: "Apakah anda yakin ingin menghapus pesan?",
                                btnOkOnPress: (){
                                  messageVM.deleteMessage(msg.id);
                                },
                                btnOkColor: Colors.orange,
                                btnCancelOnPress: (){},
                                btnCancelColor: Colors.grey
                              ).show();
                            },
                          ),
                        ),
                        if (isMe) const SizedBox(width: 44) // keep spacing for right side
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          ChatInputField(
            onTyping: (value) => onTyping(value),
            picked: _picked,
            onSend: (String text) async{
              setState(() {
                messageController.text = text;
              });
              if(text.isNotEmpty){
                isUpdate 
                ? messageVM.updateMessage(messageId!, messageController.text, gambar?.path)
                : messageVM.sendMessage(messageController.text, gambar?.path);
                setState(() {
                  isUpdate = false;
                  messageController.clear();
                  gambar = null;
                  messageId = null;
                });
              }
            },
            orange: primaryOrange,
            onCancel: () {},
            isUpdate: false,
            messageController: messageController,
          ),
        ],
      ),
    );
  }
}

class ChatInputField extends StatefulWidget {
  final void Function(String text)? onSend;
  final Color? orange;
  ChatInputField({required this.messageController, this.onSend, this.orange, super.key, required this.picked, required this.isUpdate, required this.onCancel, required this.onTyping});
  final VoidCallback picked, onCancel;
  bool isUpdate;
  final TextEditingController messageController;
  final Function(String value) onTyping;

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  bool _showAttachment = false;

  void _updateAttachmentState() {
    setState(() {
      _showAttachment = !_showAttachment;
    });
  }

  @override
  Widget build(BuildContext context) {
    final messageVM = Provider.of<MessageViewmodel>(context);
    final orange = widget.orange ?? const Color(0xFFFF9800);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -3),
            blurRadius: 12,
            color: Colors.black.withOpacity(0.03),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: widget.isUpdate ? widget.onCancel : null,
              icon: Icon(Icons.cancel_outlined),
              color: orange,
            ),
            Expanded(
              child: TextField(
                onChanged: (value) => widget.onTyping(value),
                controller: widget.messageController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Ketik pesan...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.attachment_outlined,
                            color: _showAttachment ? orange : Colors.grey),
                        onPressed: _updateAttachmentState,
                      ),
                      IconButton(
                        icon: const Icon(Icons.camera_alt_outlined),
                        onPressed: widget.picked,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: messageVM.isLoading
              ? null
              : () {
                  final text = widget.messageController.text.trim();
                  if (text.isNotEmpty) {
                    widget.onSend?.call(text);
                    widget.messageController.clear();
                  }
                },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: orange,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: orange.withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: messageVM.isLoading ? const CircularProgressIndicator() : const Icon(Icons.send, color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final Color orange;
  final VoidCallback onUpdate, onDelete;
  const _ChatBubble({
    required this.message,
    required this.isMe,
    required this.orange,
    required this.onUpdate,
    required this.onDelete
  });

  @override
  Widget build(BuildContext context) {
    // max width so bubble doesn't stretch full screen
    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.72;

    // background for bubble: orange filled for me, light orange translucent for others
    final backgroundColor = isMe ? orange : orange.withOpacity(0.08);
    final textColor = isMe ? Colors.white : Colors.black87;

    // We'll show gambar first (if present), then message text (if non-empty).
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxBubbleWidth),
      child: GestureDetector(
        onTap: isMe ? () => _showMessageAction(context) : null,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.imagePath != null && message.imagePath!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                    bottom: message.message.isNotEmpty ? 8.0 : 0.0),
                child: Container(
                  // image container with rounded corners + shadow (chosen option)
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CachedNetworkImage(
                      imageUrl:
                          "http://127.0.0.1:8000/storage/${message.imagePath}",
                      placeholder: (context, url) => AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Container(
                          color: Colors.grey.shade200,
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                      ),
                      errorWidget: (context, url, error) => AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Container(
                          color: Colors.grey.shade200,
                          child: const Center(child: Icon(Icons.broken_image)),
                        ),
                      ),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      // set height but let BoxFit cover manage crop
                      height: 200,
                    ),
                  ),
                ),
              ),
            if (message.message.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isMe ? 18 : 6),
                    topRight: Radius.circular(isMe ? 6 : 18),
                    bottomLeft: const Radius.circular(18),
                    bottomRight: const Radius.circular(18),
                  ),
                ),
                child: Text(
                  message.message,
                  style: TextStyle(color: textColor, fontSize: 15),
                ),
              ),
            const SizedBox(height: 6),
            // small timestamp (optional)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.createAt!),
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w400),
                ),
                // const SizedBox(width: 6),
                // if (isMe)
                // Icon(
                //   Icons.done_all,
                //   size: 14,
                //   color: message.status == 'receive' ? Colors.green : Colors.grey.shade500,
                // )
              ],
            )
          ],
        ),
      )
    );
  }

  static String _formatTime(DateTime dt) {
    try {
      // show only hour:minute, safe for nulls
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return "";
    }
  }

  void _showMessageAction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit pesan'),
                onTap: () {
                  Navigator.pop(context);
                  onUpdate();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Hapus pesan',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onDelete();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}