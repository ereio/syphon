// Dart imports:
import 'dart:typed_data';

// Project imports:
import './actions.dart';
import './state.dart';

MediaStore mediaReducer(
    [MediaStore state = const MediaStore(), dynamic action]) {
  switch (action.runtimeType) {
    case LoadMedia:
      return state.copyWith(
        mediaCache: action.media,
      );
    case UpdateMediaCache:
      final mediaCache = Map<String, Uint8List>.from(
        state.mediaCache ?? const {},
      );
      mediaCache[action.mxcUri] = action.data;
      return state.copyWith(
        mediaCache: mediaCache,
      );
      break;
    case UpdateMediaChecks:
      final mediaChecks = Map<String, String>.from(
        state.mediaChecks ?? const {},
      );
      mediaChecks[action.mxcUri] = action.status;
      return state.copyWith(
        mediaChecks: mediaChecks,
      );
      break;
    default:
      return state;
  }
}
