import 'package:flutter_test/flutter_test.dart';
import 'package:helpdesk_app/features/ticket/data/ticket_model.dart';

void main() {
  group('TicketModel - fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'id': '1',
        'title': 'Printer Error',
        'description': 'Printer tidak mau menyala',
        'status': 'open',
        'priority': 'high',
        'category': 'Hardware',
        'attachments': [],
        'comments': [],
        'created_at': '2026-04-08T10:00:00.000Z',
        'updated_at': '2026-04-08T10:00:00.000Z',
      };

      final ticket = TicketModel.fromJson(json);

      expect(ticket.id, '1');
      expect(ticket.title, 'Printer Error');
      expect(ticket.status, 'open');
      expect(ticket.priority, 'high');
      expect(ticket.category, 'Hardware');
      expect(ticket.attachments, isEmpty);
      expect(ticket.comments, isEmpty);
    });

    test('handles missing optional fields gracefully', () {
      final json = {
        'id': '2',
        'title': 'Network Issue',
        'description': 'Tidak bisa connect WiFi',
        'status': 'in_progress',
        'priority': 'medium',
        'category': 'Jaringan',
        'created_at': '2026-04-08T10:00:00.000Z',
        'updated_at': '2026-04-08T10:00:00.000Z',
      };

      final ticket = TicketModel.fromJson(json);

      expect(ticket.createdBy, isNull);
      expect(ticket.assignedTo, isNull);
      expect(ticket.attachments, isEmpty);
    });

    test('toJson returns correct map', () {
      final json = {
        'id': '3',
        'title': 'Software Bug',
        'description': 'Aplikasi crash saat dibuka',
        'status': 'resolved',
        'priority': 'critical',
        'category': 'Software',
        'attachments': [],
        'comments': [],
        'created_at': '2026-04-08T10:00:00.000Z',
        'updated_at': '2026-04-08T10:00:00.000Z',
      };

      final ticket = TicketModel.fromJson(json);
      final result = ticket.toJson();

      expect(result['title'], 'Software Bug');
      expect(result['status'], 'resolved');
      expect(result['priority'], 'critical');
    });
  });

  group('CommentModel - fromJson', () {
    test('parses comment correctly', () {
      final json = {
        'id': '101',
        'ticket_id': '1',
        'content': 'Sedang dicek oleh tim teknis',
        'author': {
          'id': '5',
          'name': 'Budi Santoso',
          'email': 'budi@company.com',
          'username': 'budi',
          'role': 'helpdesk',
        },
        'created_at': '2026-04-08T12:00:00.000Z',
      };

      final comment = CommentModel.fromJson(json);

      expect(comment.id, '101');
      expect(comment.content, 'Sedang dicek oleh tim teknis');
      expect(comment.author?.name, 'Budi Santoso');
      expect(comment.author?.role, 'helpdesk');
    });
  });
}
