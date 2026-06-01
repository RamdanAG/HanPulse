import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:message/models/user.dart';
import 'package:message/viewmodels/auth_viewmodel.dart';
import 'package:message/viewmodels/message_viewmodel.dart';
import 'package:message/views/message_view.dart';

const orangeColor = Color(0xFFFF9800);
class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  @override
  void initState() {
    super.initState();
    Future.microtask((){
      final authVM = Provider.of<AuthViewmodel>(context, listen: false);
      authVM.initWebscoket();
      final messageVM = Provider.of<MessageViewmodel>(context, listen: false);
      messageVM.fetchUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final messageVM = Provider.of<MessageViewmodel>(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      appBar: AppBar(
        elevation: 4,
        backgroundColor: orangeColor,
        foregroundColor: Colors.white,
        title: const Text(
          "Messages",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: InkWell(
              onTap: (){},
              child: Icon(Icons.forum_rounded, color: Colors.white),
            ),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: messageVM.fetchUser,
        color: orangeColor,
        child: messageVM.isLoading
            ? const Center(child: CircularProgressIndicator(color: orangeColor))
            : Column(
                children: [
                  // 🔍 Search bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: orangeColor,
                      boxShadow: [
                        BoxShadow(
                          color: orangeColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: "Cari teman...",
                        hintStyle: TextStyle(
                            color: Colors.grey.shade500, fontSize: 15),
                        prefixIcon:
                            Icon(Icons.search, color: orangeColor, size: 22),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  // 👥 List user
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: messageVM.userList.length,
                      itemBuilder: (context, index) {
                        final user = messageVM.userList[index];
                        return ChatUserCard(
                          user: user,
                          press: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => MessageView(receiver: user, sender: messageVM.currentUser!))).then((_) => messageVM.fetchUser());
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class ChatUserCard extends StatelessWidget {
  const ChatUserCard({
    super.key,
    required this.user,
    required this.press,
  });

  final User user;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    const orangeColor = Color(0xFFFF9800);
    final lastSeen = user.createAt != null
        ? "${user.createAt!.hour}:${user.createAt!.minute.toString().padLeft(2, '0')}"
        : "";

    return InkWell(
      onTap: press,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: orangeColor.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          children: [
            // 🧑 Avatar
            CircleAvatarWithActiveIndicator(user: user),
            const SizedBox(width: 12),
            // 💬 Info pengguna
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // 🕒 Waktu aktif terakhir
            Text(
              lastSeen,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CircleAvatarWithActiveIndicator extends StatelessWidget {
  const CircleAvatarWithActiveIndicator({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    const orangeColor = Color(0xFFFF9800);
    final messageVM = Provider.of<MessageViewmodel>(context);

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: user.profilePath != null
              ? CachedNetworkImage(
                  imageUrl: "http://127.0.0.1:8000/storage/${user.profilePath}",
                  width: 55,
                  height: 55,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.broken_image, size: 55),
                )
              : Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 35),
                ),
        ),
        // Titik online/offline
        // if(messageVM.isOnlineUser(user.id))
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: orangeColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ],
    );
  }
}