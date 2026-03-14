import 'package:flutter/material.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/shared/widgets/notif_card.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifs = [
      (type: NotifType.meal, title: 'Heure du déjeuner', subtitle: 'N’oubliez pas votre repas de midi', time: '12:00', emoji: '🥗', avatarUrl: null),
      (type: NotifType.chat, title: 'Marie vous a envoyé un message', subtitle: 'Super recette !', time: '11:30', emoji: null, avatarUrl: null),
      (type: NotifType.request, title: 'Jean souhaite rejoindre votre groupe', subtitle: 'Groupe: Famille Saine', time: 'hier', emoji: null, avatarUrl: null),
      (type: NotifType.meal, title: 'Rappel : dîner', subtitle: 'Poulet grillé ce soir', time: '18:00', emoji: '🍗', avatarUrl: null),
    ];

    return Scaffold(
      backgroundColor: AkeliColors.background,
      appBar: AppBar(
        backgroundColor: AkeliColors.background,
        elevation: 0,
        leading: const BackButton(),
        title: const Text('Notifications'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ...notifs.map((n) => AkeliNotifCard(
            type: n.type,
            title: n.title,
            subtitle: n.subtitle,
            time: n.time,
            avatarUrl: n.avatarUrl,
            emoji: n.emoji,
          )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
