import 'dart:async';

class QueueItem {
  final String type; // e.g., 'add_member', 'send_reminder'
  final Map<String, dynamic> payload;
  int attempts;
  final int maxAttempts;
  QueueItem({required this.type, required this.payload, this.attempts = 0, this.maxAttempts = 3});
}

class QueueStore {
  final _queue = <QueueItem>[];
  final _controller = StreamController<List<QueueItem>>.broadcast();

  int get pendingCount => _queue.length;

  Stream<List<QueueItem>> get stream => _controller.stream;

  void enqueue(QueueItem item) {
    _queue.add(item);
    _controller.add(List.unmodifiable(_queue));
  }

  QueueItem? peek() => _queue.isNotEmpty ? _queue.first : null;

  QueueItem? dequeue() {
    if (_queue.isEmpty) return null;
    final item = _queue.removeAt(0);
    _controller.add(List.unmodifiable(_queue));
    return item;
  }

  int get length => _queue.length;
}
