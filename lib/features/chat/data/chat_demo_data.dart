import 'dart:math';

import '../models/chat_models.dart';
import 'package:flutter/material.dart';

final _colors = [
  const Color(0xFF7C3AED),
  const Color(0xFF0BA78E),
  const Color(0xFF2563EB),
  const Color(0xFFEA580C),
  const Color(0xFFDB2777),
  const Color(0xFF0EA5E9),
  const Color(0xFF22C55E),
  const Color(0xFFF59E0B),
];

final List<ChatUser> demoUsers = [
  ChatUser(id: 'u1', name: 'Ahmed El Mansouri', avatarColor: _colors[0]),
  ChatUser(id: 'u2', name: 'Sara B.', avatarColor: _colors[1]),
  ChatUser(id: 'u3', name: 'Youssef Amine', avatarColor: _colors[2]),
  ChatUser(id: 'u4', name: 'Imane K.', avatarColor: _colors[3]),
  ChatUser(id: 'u5', name: 'Hamza L.', avatarColor: _colors[4]),
  ChatUser(id: 'u6', name: 'Mariam Z.', avatarColor: _colors[5]),
  ChatUser(id: 'u7', name: 'Nadia B.', avatarColor: _colors[6]),
  ChatUser(id: 'u8', name: 'Omar', avatarColor: _colors[7]),
];

List<ChatMessage> buildMessages(String convId) {
  final texts = [
    "Bonjour 👋",
    "Salut, comment ça va ?",
    "Je voulais savoir si votre produit est toujours disponible.",
    "Oui il est toujours disponible.",
    "Parfait ! Pouvez-vous m'envoyer plus de photos ?",
    "Bien sûr, je vous les envoie.",
    "Merci beaucoup 🙏",
    "Pas de problème, à bientôt !",
    "Voici quelques images supplémentaires.",
    "Super, je confirme l'achat.",
    "Parfait, on peut finaliser.",
    "Top !",
  ];
  final rand = Random(convId.hashCode);
  final count = 10 + rand.nextInt(10); // 10–19
  final List<ChatMessage> msgs = [];
  DateTime base = DateTime.now().subtract(const Duration(hours: 5));
  for (int i = 0; i < count; i++) {
    final isMe = i % 2 == 1;
    msgs.add(ChatMessage(
      id: 'm${convId}_$i',
      conversationId: convId,
      text: texts[rand.nextInt(texts.length)],
      isMe: isMe,
      time: base.add(Duration(minutes: i * 7)),
      status: isMe ? MessageStatus.read : null,
    ));
  }
  return msgs;
}

late final Map<String, List<ChatMessage>> demoMessagesByConv = {
  for (final user in demoUsers) 'c${user.id}': buildMessages('c${user.id}'),
};

List<ChatConversation> demoConversations() {
  final list = <ChatConversation>[];
  int i = 0;
  for (final user in demoUsers) {
    final convId = 'c${user.id}';
    final msgs = demoMessagesByConv[convId]!;
    final last = msgs.last;
    final unread = i % 3 == 0 ? (i % 2 == 0 ? 3 : 1) : 0;
    list.add(ChatConversation(
      id: convId,
      user: user,
      unreadCount: unread,
      lastMessage: last,
    ));
    i++;
  }
  return list;
}
