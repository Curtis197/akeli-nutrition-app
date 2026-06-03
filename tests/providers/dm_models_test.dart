import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/providers/dm_provider.dart';

void main() {
  group('DmRequest.fromJson', () {
    test('parses all fields', () {
      final json = {
        'id': 'req-1',
        'requester_id': 'user-1',
        'message': 'Salut !',
        'created_at': '2026-05-24T10:00:00.000Z',
        'user_profile': {'display_name': 'Alice', 'avatar_url': 'https://img'},
      };
      final req = DmRequest.fromJson(json);
      expect(req.requestId, 'req-1');
      expect(req.requesterId, 'user-1');
      expect(req.requesterName, 'Alice');
      expect(req.requesterAvatar, 'https://img');
      expect(req.message, 'Salut !');
    });

    test('handles null avatar and message', () {
      final json = {
        'id': 'req-2',
        'requester_id': 'user-2',
        'message': null,
        'created_at': '2026-05-24T10:00:00.000Z',
        'user_profile': {'display_name': 'Bob', 'avatar_url': null},
      };
      final req = DmRequest.fromJson(json);
      expect(req.requesterAvatar, isNull);
      expect(req.message, isNull);
    });
  });

  group('GroupMember.fromJson', () {
    test('parses member row', () {
      final json = {
        'user_id': 'user-3',
        'role': 'admin',
        'joined_at': '2026-04-01T00:00:00.000Z',
        'user_profile': {'display_name': 'Carol', 'avatar_url': null},
      };
      final m = GroupMember.fromJson(json);
      expect(m.userId, 'user-3');
      expect(m.role, 'admin');
      expect(m.displayName, 'Carol');
    });
  });

  group('ChatMessage.fromJson', () {
    test('isMine true when senderId matches currentUserId', () {
      final json = {
        'id': 'msg-1',
        'conversation_id': 'conv-1',
        'sender_id': 'me',
        'content': 'Hello',
        'sent_at': '2026-05-24T10:00:00.000Z',
        'user_profile': {'display_name': 'Me', 'avatar_url': null},
      };
      final msg = ChatMessage.fromJson(json, currentUserId: 'me');
      expect(msg.isMine, isTrue);
      expect(msg.content, 'Hello');
    });

    test('isMine false for other sender', () {
      final json = {
        'id': 'msg-2',
        'conversation_id': 'conv-1',
        'sender_id': 'other',
        'content': 'Hi',
        'sent_at': '2026-05-24T10:00:00.000Z',
        'user_profile': {'display_name': 'Other', 'avatar_url': null},
      };
      final msg = ChatMessage.fromJson(json, currentUserId: 'me');
      expect(msg.isMine, isFalse);
    });
  });
}
