import '../../auth/data/auth_model.dart';

class TicketModel {
  final String id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String category;
  final UserModel? createdBy;
  final UserModel? assignedTo;
  final List<String> attachments;
  final List<CommentModel> comments;
  final DateTime createdAt;
  final DateTime updatedAt;

  TicketModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.category,
    this.createdBy,
    this.assignedTo,
    this.attachments = const [],
    this.comments = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    final rawAttachments = json['attachments'];

    return TicketModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'open',
      priority: json['priority'] ?? 'medium',
      category: json['category'] ?? '',
      createdBy: _parseUser(json['created_by']),
      assignedTo: _parseUser(json['assigned_to']),
      attachments: rawAttachments is List
          ? rawAttachments
                .map((a) {
                  if (a is String) return a;
                  if (a is Map<String, dynamic>) {
                    return (a['file_url'] ?? a['file_name'] ?? '').toString();
                  }
                  return '';
                })
                .where((v) => v.isNotEmpty)
                .cast<String>()
                .toList()
          : const <String>[],
      comments: (json['comments'] as List<dynamic>? ?? [])
          .map((c) => CommentModel.fromJson(c))
          .toList(),
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'status': status,
    'priority': priority,
    'category': category,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

UserModel? _parseUser(dynamic value) {
  if (value is Map<String, dynamic>) {
    return UserModel.fromJson(value);
  }
  return null;
}

class CommentModel {
  final String id;
  final String ticketId;
  final String content;
  final UserModel? author;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.ticketId,
    required this.content,
    this.author,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id']?.toString() ?? '',
      ticketId: json['ticket_id']?.toString() ?? '',
      content: json['content'] ?? '',
      author: _parseUser(json['author']),
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class TicketTrackingModel {
  final String id;
  final String ticketId;
  final String status;
  final String description;
  final UserModel? changedBy;
  final DateTime createdAt;

  TicketTrackingModel({
    required this.id,
    required this.ticketId,
    required this.status,
    required this.description,
    this.changedBy,
    required this.createdAt,
  });

  factory TicketTrackingModel.fromJson(Map<String, dynamic> json) {
    return TicketTrackingModel(
      id: json['id']?.toString() ?? '',
      ticketId: json['ticket_id']?.toString() ?? '',
      status: json['status'] ?? '',
      description: json['description'] ?? '',
      changedBy: _parseUser(json['changed_by']),
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
