// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:convert/convert.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

// Project imports:
import 'package:syphon/global/themes.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/auth/state.dart';
import 'package:syphon/store/crypto/keys/model.dart';
import 'package:syphon/store/crypto/model.dart';
import 'package:syphon/store/crypto/state.dart';
import 'package:syphon/store/media/state.dart';
import 'package:syphon/store/rooms/events/ephemeral/m.read/model.dart';
import 'package:syphon/store/rooms/events/model.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/rooms/state.dart';
import 'package:syphon/store/settings/chat-settings/model.dart';
import 'package:syphon/store/settings/devices-settings/model.dart';
import 'package:syphon/store/settings/state.dart';
import 'package:syphon/store/sync/state.dart';
import 'package:syphon/store/user/model.dart';

// Global cache
class Cache {
  static Box state;
  static Box stateRooms;
  static Box stateMedia;
  static LazyBox sync;

  static const group_id = '${Values.appNameLabel}';
  static const encryptionKeyLocation = '${Values.appNameLabel}@publicKey';

  static const syncKey = '${Values.appNameLabel}_sync';
  static const stateKey = '${Values.appNameLabel}_cache';
  static const stateRoomKey = '${Values.appNameLabel}_cache_2';

  static const syncKeyUNSAFE = '${Values.appNameLabel}_sync_unsafe';
  static const stateKeyUNSAFE = '${Values.appNameLabel}_cache_unsafe';
  static const stateKeyRoomsUNSAFE =
      '${Values.appNameLabel}_cache_rooms_unsafe';

  static const backgroundKeyUNSAFE =
      '${Values.appNameLabel}_background_cache_unsafe_alt';

  static const roomNames = 'room_names';
  static const syncData = 'sync_data';
  static const protocol = 'protocol';
  static const homeserver = 'homeserver';
  static const accessTokenKey = 'accessToken';
  static const lastSinceKey = 'lastSince';
  static const currentUser = 'currentUser';
}

/**
 * openHiveState UNSAFE
 * 
 * For testing purposes only - should be encrypting hive
 */
Future<void> initHive() async {
  // Init storage location
  final storageLocation = await initStorageLocation();

  // Init configuration
  await initHiveConfiguration(storageLocation);
}

Future<dynamic> initStorageLocation() async {
  var storageLocation;

  try {
    if (Platform.isIOS || Platform.isAndroid) {
      storageLocation = await getApplicationDocumentsDirectory();
      return storageLocation.path;
    }

    if (Platform.isMacOS) {
      storageLocation = await File('cache').create().then(
            (value) => value.writeAsString(
              '{}',
              flush: true,
            ),
          );

      return storageLocation.path;
    }

    if (Platform.isLinux) {
      storageLocation = await getApplicationDocumentsDirectory();
      return storageLocation.path;
    }

    debugPrint('[initStorageLocation] no cache support');
    return null;
  } catch (error) {
    debugPrint('[initStorageLocation] $error');
    return null;
  }
}

Future<void> initHiveConfiguration(String storageLocationPath) async {
  // Init hive cache
  Hive.init(storageLocationPath);

  // Init Custom Models
  Hive.registerAdapter(ThemeTypeAdapter());
  Hive.registerAdapter(ChatSettingAdapter());
  Hive.registerAdapter(RoomAdapter());
  Hive.registerAdapter(MessageAdapter());
  Hive.registerAdapter(EventAdapter());
  Hive.registerAdapter(ReadStatusAdapter());
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(DeviceAdapter());
  Hive.registerAdapter(DeviceKeyAdapter());
  Hive.registerAdapter(OneTimeKeyAdapter());
  // Hive.registerAdapter(AccountAdapter());

  // Custom Store Models
  Hive.registerAdapter(AuthStoreAdapter());
  Hive.registerAdapter(SyncStoreAdapter());
  Hive.registerAdapter(CryptoStoreAdapter());
  Hive.registerAdapter(RoomStoreAdapter());
  Hive.registerAdapter(MediaStoreAdapter());
  Hive.registerAdapter(SettingsStoreAdapter());
}

Future<List<int>> unlockEncryptionKey() async {
  // Check if storage has been created before
  final storageEngine = FlutterSecureStorage();

  var encryptionKey = await storageEngine.read(
    key: Cache.encryptionKeyLocation,
  );
  // Create a encryptionKey if a serialized one is not found
  if (encryptionKey == null) {
    encryptionKey = hex.encode(Hive.generateSecureKey());

    await storageEngine.write(
      key: Cache.encryptionKeyLocation,
      value: encryptionKey,
    );
  }

  return hex.decode(encryptionKey);
}

/**
 * openHiveState UNSAFE
 * 
 * For testing purposes only - should be encrypting hive
 */
Future<Box> openHiveStateRoomsUnsafe() async {
  return await Hive.openBox(
    Cache.stateKeyUNSAFE,
    compactionStrategy: (entries, deletedEntries) => deletedEntries > 2,
  );
}

/**
 * openHiveState UNSAFE
 * 
 * For testing purposes only - should be encrypting hive
 */
Future<Box> openHiveStateUnsafe() async {
  return await Hive.openBox(
    Cache.stateKeyRoomsUNSAFE,
    compactionStrategy: (entries, deletedEntries) => deletedEntries > 2,
  );
}

/**
 * openHiveState UNSAFE
 * 
 * For testing purposes only - should be encrypting hive
 */
Future<LazyBox> openHiveSyncUnsafe() async {
  return await Hive.openLazyBox(
    Cache.syncKeyUNSAFE,
    compactionStrategy: (entries, deletedEntries) => deletedEntries > 2,
  );
}

/**
 * openHiveState UNSAFE
 * 
 * For testing purposes only - should be encrypting hive
 */
Future<Box> openHiveBackgroundUnsafe() async {
  var storageLocation;

  // Init storage location
  try {
    storageLocation = await getApplicationDocumentsDirectory();
  } catch (error) {
    debugPrint('[openHiveBackgroundUnsafe] Storage Failure $error');
  }

  // Init hive cache + adapters
  Hive.init(storageLocation.path);
  return await Hive.openBox(Cache.backgroundKeyUNSAFE);
}

/**
 * Open Hive State
 * 
 * Separating the rest of state from room data to 
 * improve performance
 * Initializes encrypted storage for caching current state
 */
Future<Box> openHiveState() async {
  try {
    final encryptionKey = await unlockEncryptionKey();

    return await Hive.openBox(
      Cache.stateKey,
      crashRecovery: false,
      encryptionCipher: HiveAesCipher(encryptionKey),
      compactionStrategy: (entries, deletedEntries) => deletedEntries > 1,
    );
  } catch (error) {
    debugPrint('[openHiveState] open failure: $error');
    return await Hive.openBox(
      Cache.stateKeyUNSAFE,
    );
  }
}

/**
 * Open Hive State
 * 
 * Initializes encrypted storage for caching current state
 */
Future<Box> openHiveStateRooms() async {
  try {
    final encryptionKey = await unlockEncryptionKey();

    return await Hive.openBox(
      Cache.stateRoomKey,
      crashRecovery: false,
      encryptionCipher: HiveAesCipher(encryptionKey),
      compactionStrategy: (entries, deletedEntries) => deletedEntries > 1,
    );
  } catch (error) {
    debugPrint('[openHiveState] open failure: $error');
    return await Hive.openBox(
      Cache.stateKeyUNSAFE,
    );
  }
}

/**
 *  Open Hive Sync
 * 
 * Initializes encrypted storage for caching sync
 */
Future<LazyBox> openHiveSync() async {
  try {
    final encryptionKey = await unlockEncryptionKey();

    return await Hive.openLazyBox(
      Cache.syncKey,
      crashRecovery: false,
      encryptionCipher: HiveAesCipher(encryptionKey),
      compactionStrategy: (entries, deletedEntries) => deletedEntries > 1,
    );
  } catch (error) {
    debugPrint('[openHiveState] failure $error');
    return await Hive.openLazyBox(
      Cache.syncKeyUNSAFE,
    );
  }
}

// // Closes and saves storage
void closeStorage() async {
  if (Cache.sync != null && Cache.sync.isOpen) {
    Cache.sync.close();
  }

  if (Cache.state != null && Cache.state.isOpen) {
    Cache.sync.close();
  }
}
