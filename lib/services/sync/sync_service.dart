import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:savessa/services/sync/queue_store.dart';

enum SyncState { idle, syncing, error }

class SyncService {
  final QueueStore _store;
  final _stateController = StreamController<SyncState>.broadcast();
  final ValueNotifier<SyncState> stateNotifier = ValueNotifier<SyncState>(SyncState.idle);
  SyncState _state = SyncState.idle;
  Timer? _tick;

  SyncService(this._store) {
    Connectivity().onConnectivityChanged.listen((event) {
      if (event != ConnectivityResult.none) {
        _flush();
      }
    });
    // Periodic flush to catch up even if no connectivity event fired
    _tick = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_state != SyncState.syncing) {
        // ignore: discarded_futures
        _flush();
      }
    });
  }

  void enqueue(QueueItem item) {
    _store.enqueue(item);
    // fire and forget flush attempt
    // ignore: discarded_futures
    _flush();
  }

  Stream<SyncState> get state => _stateController.stream;

  Future<void> flush() => _flush();

  Future<void> _flush() async {
    if (_state == SyncState.syncing) return;
    if (_store.length == 0) {
      _setState(SyncState.idle);
      return;
    }
    _setState(SyncState.syncing);
    try {
      // Process items until queue is drained or we need to back off
      final int initialLen = _store.length;
      int processed = 0;
      while (_store.length > 0) {
        final item = _store.dequeue();
        if (item == null) break;
        final ok = await _dispatch(item);
        if (!ok) {
          item.attempts += 1;
          if (item.attempts < item.maxAttempts) {
            // backoff before requeue
            await Future<void>.delayed(Duration(milliseconds: 200 * item.attempts));
            _store.enqueue(item);
            _setState(SyncState.error); // briefly indicate error, will retry
          } else {
            // drop the item after max attempts
            _setState(SyncState.error);
          }
        } else {
          processed += 1;
        }
      }
      // If nothing left, we are idle
      if (_store.length == 0) {
        _setState(SyncState.idle);
      } else if (processed == 0 && _store.length >= initialLen) {
        // Avoid tight loop on constant failures
        await Future<void>.delayed(const Duration(seconds: 2));
        _setState(SyncState.error);
      }
    } catch (_) {
      _setState(SyncState.error);
    }
  }

  // Return true if handled successfully, else false to retry
  Future<bool> _dispatch(QueueItem item) async {
    try {
      switch (item.type) {
        case 'send_reminder':
          // In a real app, this would call backend API to schedule push/email/etc.
          await Future<void>.delayed(const Duration(milliseconds: 150));
          return true;
        case 'send_push':
          await Future<void>.delayed(const Duration(milliseconds: 120));
          return true;
        default:
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return true;
      }
    } catch (_) {
      return false;
    }
  }

  void _setState(SyncState s) {
    _state = s;
    _stateController.add(s);
    stateNotifier.value = s;
  }

  void dispose() {
    _tick?.cancel();
    _stateController.close();
    stateNotifier.dispose();
  }
}
