// Dart imports:
import 'dart:convert';
import 'dart:typed_data';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:redux_persist/redux_persist.dart';
import 'package:sembast/sembast.dart';
import 'package:syphon/global/cache/index.dart';
import 'package:syphon/global/cache/threadables.dart';
import 'package:syphon/global/print.dart';

// Project imports:
import 'package:syphon/store/crypto/state.dart';
import 'package:syphon/store/events/model.dart';
import 'package:syphon/store/events/state.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/sync/state.dart';
import 'package:syphon/store/user/state.dart';
import 'package:syphon/store/auth/state.dart';
import 'package:syphon/store/media/state.dart';
import 'package:syphon/store/rooms/state.dart';
import 'package:syphon/store/settings/state.dart';

/**
 * Cache Serializer
 * 
 * Handles serialization, encryption, and storage for caching redux stores
 */
class CacheSerializer implements StateSerializer<AppState> {
  final Database cache;
  final Map<String, Map<dynamic, dynamic>> preloaded;

  CacheSerializer({this.cache, this.preloaded});

  @override
  Uint8List encode(AppState state) {
    final List<Object> stores = [
      state.authStore,
      state.syncStore,
      state.cryptoStore,
      state.mediaStore,
      state.settingsStore,
      state.userStore,
    ];

    // Queue up a cache saving will wait
    // if the previously schedule task has not finished
    Future.microtask(() async {
      // // create a new IV for the encrypted cache
      Cache.ivKey = generateIV();

      // // backup the IV in case the app is force closed before caching finishes
      await saveIVNext(Cache.ivKey);

      // run through all redux stores for encryption and encoding
      await Future.wait(stores.map((store) async {
        try {
          String jsonEncoded;
          String jsonEncrypted;
          String type = store.runtimeType.toString();

          // serialize the store contents
          // Stopwatch stopwatchSerialize = new Stopwatch()..start();
          try {
            // HACK: unable to pass certain stores directly to an isolate
            final sensitiveStorage = [MediaStore];
            if (sensitiveStorage.contains(store.runtimeType)) {
              jsonEncoded = await compute(jsonEncode, store);
            } else {
              jsonEncoded = json.encode(store);
            }
          } catch (error) {
            jsonEncoded = json.encode(store);
            print(
              '[CacheSerializer] ${type} failed $error',
            );
          }

          // debugPrint(
          //   '[CacheSerializer] ${stopwatchSerialize.elapsed} ${type} serialize',
          // );

          // Stopwatch stopwatchEncrypt = new Stopwatch()..start();
          // encrypt the store contents
          jsonEncrypted = await compute(
            encryptJsonBackground,
            {
              'ivKey': Cache.ivKey,
              'cryptKey': Cache.cryptKey,
              'type': type,
              'json': jsonEncoded,
            },
            debugLabel: 'encryptJsonBackground',
          );

          // debugPrint(
          //   '[CacheSerializer] ${stopwatchEncrypt.elapsed} ${type} encrypt',
          // );

          try {
            // Stopwatch stopwatchSave = new Stopwatch()..start();
            final storeRef = StoreRef<String, String>.main();
            await storeRef.record(type).put(cache, jsonEncrypted);

            // debugPrint(
            //   '[CacheSerializer] ${stopwatchSave.elapsed} ${type} saved',
            // );
          } catch (error) {
            print('[CacheSerializer] ERROR $error');
          }
        } catch (error) {
          debugPrint(
            '[CacheSerializer] $error',
          );
        }
      }));

      // Rotate encryption for the next save
      await saveIV(Cache.ivKey);

      return Future.value(null);
    });

    // Disregard redux persist storage saving
    return null;
  }

  AppState decode(Uint8List data) {
    AuthStore authStore = AuthStore();
    SyncStore syncStore = SyncStore();
    UserStore userStore = UserStore();
    CryptoStore cryptoStore = CryptoStore();
    MediaStore mediaStore = MediaStore();
    SettingsStore settingsStore = SettingsStore();

    // Load stores previously fetched from cache,
    // mutable global due to redux_presist not extendable beyond Uint8List
    final stores = Cache.cacheStores;

    // decode each store cache synchronously
    stores.forEach((type, store) {
      try {
        // if all else fails, just pass back a fresh store to avoid a crash
        if (store == null || store.isEmpty) return;

        // this stinks, but dart doesn't allow reflection for factories/contructors
        switch (type) {
          case 'AuthStore':
            authStore = AuthStore.fromJson(store);
            break;
          case 'SyncStore':
            syncStore = SyncStore.fromJson(store);
            break;
          case 'CryptoStore':
            cryptoStore = CryptoStore.fromJson(store);
            break;
          case 'MediaStore':
            mediaStore = MediaStore.fromJson(store);
            break;
          case 'SettingsStore':
            settingsStore = SettingsStore.fromJson(store);
            break;
          case 'UserStore':
            userStore = UserStore.fromJson(store);
            break;
          case 'RoomStore':
          // --- cold storage only ---
          default:
            break;
        }
      } catch (error) {
        printError('[CacheSerializer.decode] $error');
      }
    });

    return AppState(
      loading: false,
      authStore: authStore ?? AuthStore(),
      syncStore: syncStore ?? SyncStore(),
      cryptoStore: cryptoStore ?? CryptoStore(),
      mediaStore: mediaStore ?? MediaStore(),
      settingsStore: settingsStore ?? SettingsStore(),
      roomStore: RoomStore().copyWith(
        rooms: preloaded['rooms'] ?? {},
      ),
      userStore: userStore.copyWith(
        users: preloaded['users'] ?? {},
      ),
      eventStore: EventStore().copyWith(
        messages: preloaded['messages'] ?? Map<String, List<Message>>(),
      ),
    );
  }
}
