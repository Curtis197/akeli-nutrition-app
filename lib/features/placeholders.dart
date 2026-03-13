import 'package:flutter/material.dart';

class DietPlanPage extends StatelessWidget {
  const DietPlanPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Diet Plan - Coming Soon')));
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Notifications - Coming Soon')));
}

class MealDetailPage extends StatelessWidget {
  final String mealId;
  const MealDetailPage({super.key, required this.mealId});
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('Meal Detail: \$mealId - Coming Soon')));
}

class GroupChatPage extends StatelessWidget {
  final String groupId;
  const GroupChatPage({super.key, required this.groupId});
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('Group Chat: \$groupId - Coming Soon')));
}

class GroupDetailPage extends StatelessWidget {
  final String groupId;
  const GroupDetailPage({super.key, required this.groupId});
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('Group Detail: \$groupId - Coming Soon')));
}
