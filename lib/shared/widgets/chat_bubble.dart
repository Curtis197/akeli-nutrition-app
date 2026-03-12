import 'package:flutter/material.dart';
import 'package:akeli/core/theme.dart';

class AkeliChatBubble extends StatelessWidget {
  final String message;
  final String time;
  final bool isSent;
  final String? senderName;
  final bool isRead;

  const AkeliChatBubble({
    super.key,
    required this.message,
    required this.time,
    required this.isSent,
    this.senderName,
    this.isRead = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isSent && senderName != null) ...[
              Text(
                senderName!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AkeliColors.primary,
                    ),
              ),
              const SizedBox(height: 2),
            ],
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: isSent ? const Color(0xFFE3F0FF) : AkeliColors.surface,
                boxShadow: isSent ? null : const [AkeliShadows.sm],
                borderRadius: isSent
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(AkeliRadius.md),
                        topRight: Radius.circular(AkeliRadius.md),
                        bottomLeft: Radius.circular(AkeliRadius.md),
                        bottomRight: Radius.circular(0),
                      )
                    : const BorderRadius.only(
                        topLeft: Radius.circular(AkeliRadius.md),
                        topRight: Radius.circular(AkeliRadius.md),
                        bottomLeft: Radius.circular(0),
                        bottomRight: Radius.circular(AkeliRadius.md),
                      ),
              ),
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AkeliColors.textPrimary,
                    ),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AkeliColors.textSecondary,
                      ),
                ),
                if (isSent && isRead) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.done_all, size: 12, color: AkeliColors.primary),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
