import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:Tether/global/libs/hive/index.dart';
import 'package:Tether/global/libs/matrix/errors.dart';
import 'package:Tether/global/libs/matrix/user.dart';
import 'package:Tether/store/media/actions.dart';
import 'package:Tether/store/rooms/events/actions.dart';
import 'package:Tether/store/rooms/service.dart';
import 'package:Tether/store/user/model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

import 'package:Tether/store/index.dart';
import 'package:Tether/global/libs/matrix/rooms.dart';

import 'room/model.dart';
import 'events/model.dart';

final protocol = DotEnv().env['PROTOCOL'];

class SetLoading {
  final bool loading;
  SetLoading({this.loading});
}

class SetSyncing {
  final bool syncing;
  SetSyncing({this.syncing});
}

class SetSending {
  final bool sending;
  final Room room;
  SetSending({this.sending, this.room});
}

class SetRoomObserver {
  final Timer roomObserver;
  SetRoomObserver({this.roomObserver});
}

class SetRooms {
  final List<Room> rooms;
  SetRooms({this.rooms});
}

class SetRoom {
  final Room room;
  SetRoom({this.room});
}

// Atomically Update specific room attributes
class UpdateRoom {
  final String id; // room id
  final Message draft;
  final bool syncing;

  UpdateRoom({
    this.id,
    this.draft,
    this.syncing,
  });
}

class RemoveRoom {
  final Room room;
  RemoveRoom({this.room});
}

class ResetRooms {
  ResetRooms();
}

class SetRoomState {
  final String id; // room id
  final List<Event> state;
  final String username;

  SetRoomState({this.id, this.state, this.username});
}

class SetRoomMessages {
  final String id; // room id
  final String startTime;
  final String endTime;
  final List<Message> messageEvents;

  SetRoomMessages({
    this.id,
    this.startTime,
    this.endTime,
    this.messageEvents,
  });
}

/**
 * tempId for messages that have attempted sending but not finished
 */
class SaveOutboxMessage {
  final String id; // TODO: room id
  final String tempId;
  final Message pendingMessage;

  SaveOutboxMessage({
    this.id,
    this.tempId,
    this.pendingMessage,
  });
}

class DeleteOutboxMessage {
  final Message message; // room id

  DeleteOutboxMessage({
    this.message,
  });
}

class SetSynced {
  final bool synced;
  final bool syncing;
  final String lastSince;
  SetSynced({this.synced, this.syncing, this.lastSince});
}

/**
 * Initial Room Sync - Custom Solution for /sync
 * 
 * This will only be run on log in because the matrix protocol handles
 * initial syncing terribly. It's incredibly cumbersome to load thousands of events
 * for multiple rooms all at once in order to show the user just some room names
 * and timestamps. Lazy loading isn't always supported, so it's not a solid solution
 */
ThunkAction<AppState> initialRoomSync() {
  return (Store<AppState> store) async {
    // Start initial sync in background
    // TODO: use an isolate for initial sync
    store.dispatch(fetchSync());

    // Fetch All Room Ids
    await store.dispatch(fetchRooms());
    await store.dispatch(fetchDirectRooms());

    // Fetch Essential State and Message Events
    final joinedRooms = store.state.roomStore.roomList;

    final allFetchStates = joinedRooms.map((room) async {
      return store.dispatch(fetchStateEvents(room: room));
    }).toList();

    final allFetchMessages = joinedRooms.map((room) async {
      return store.dispatch(fetchMessageEvents(room: room));
    }).toList();

    // Await all the futures in no particular order
    await Future.wait(
      [allFetchMessages, allFetchStates].expand((x) => x).toList(),
    );
  };
}

/**
 * Default Room Sync Observer
 * 
 * This will be run after the initial sync. Following login or signup, users
 * will just have an observer that runs every second or so to sync with the server
 * only while the app is _active_ otherwise, it will be up to a background service
 * and a notification service to trigger syncs
 */
ThunkAction<AppState> startRoomsObserver() {
  return (Store<AppState> store) async {
    Timer roomObserver = Timer.periodic(Duration(seconds: 5), (timer) async {
      if (store.state.roomStore.lastSince == null) {
        print('[Room Observer] skipping sync, needs full sync');
        return;
      }

      final lastUpdate = DateTime.fromMillisecondsSinceEpoch(
        store.state.roomStore.lastUpdate,
      );
      final retryTimeout =
          DateTime.now().difference(lastUpdate).compareTo(Duration(hours: 1));

      if (0 < retryTimeout) {
        print('[Room Observer] forced retry timeout');
        store.dispatch(fetchSync(since: store.state.roomStore.lastSince));
        return;
      }

      if (store.state.roomStore.syncing) {
        print('[Room Observer] still syncing');
        return;
      }

      print('[Room Observer] running sync');
      store.dispatch(fetchSync(since: store.state.roomStore.lastSince));
    });

    store.dispatch(SetRoomObserver(roomObserver: roomObserver));
  };
}

ThunkAction<AppState> stopRoomsObserver() {
  return (Store<AppState> store) async {
    if (store.state.roomStore.roomObserver != null) {
      store.state.roomStore.roomObserver.cancel();
      store.dispatch(SetRoomObserver(roomObserver: null));
      stopRoomObserverService();
    }
  };
}

ThunkAction<AppState> fetchSync({String since, bool forceFull = false}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetSyncing(syncing: true));
      if (since == null) {
        print('[fetchSync] fetching full sync');
      }

      final request = buildSyncRequest(
        protocol: protocol,
        homeserver: store.state.userStore.homeserver,
        accessToken: store.state.userStore.user.accessToken,
        fullState: forceFull || store.state.roomStore.rooms == null,
        since: forceFull ? null : since ?? store.state.roomStore.lastSince,
      );

      final response = await http.get(
        request['url'],
        headers: request['headers'],
      );

      // parse sync data
      final data = json.decode(response.body);

      // if (!kReleaseMode) {
      //   print('[fetchSync] DEBUGGING **************************');
      //   (data as Map).forEach((key, value) {
      //     print('$key $value\n');
      //   });
      //   print('[fetchSync] DEBUGGING **************************');
      // }

      final String lastSince = data['next_batch'];
      final Map<String, dynamic> rawRooms =
          data['rooms']['join'] ?? Map<String, Room>();

      // init new store containers
      final Map<String, Room> rooms =
          store.state.roomStore.rooms ?? Map<String, Room>();
      final user = store.state.userStore.user;

      // update those that exist or add a new room
      rawRooms.forEach((id, json) {
        Room room;

        // use pre-existing values where available
        if (rooms.containsKey(id)) {
          room = rooms[id].fromSync(
            json: json,
            currentUser: user.displayName,
          );
        } else {
          room = Room(id: id).fromSync(
            json: json,
            currentUser: user.displayName,
          );
        }

        // fetch avatar if a uri was found
        if (room.avatarUri != null) {
          store.dispatch(fetchThumbnail(
            mxcUri: room.avatarUri,
          ));
        }

        store.dispatch(SetRoom(room: room));
      });

      // Update synced to indicate init sync and next batch id (lastSince)
      store.dispatch(SetSynced(
        synced: true,
        syncing: false,
        lastSince: lastSince,
      ));

      // TODO: encrypt and find a way to reasonably update this
      if (!store.state.roomStore.synced) {
        Cache.hive.put(Cache.matrixStateBox, response.body);
      }
      if (!kReleaseMode && since == null) {
        print('[fetchSync] full sync completed');
      }
    } catch (error) {
      print('[fetchSync] error $error');
      store.dispatch(SetSyncing(syncing: false));
    }
  };
}

ThunkAction<AppState> fetchRooms() {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final request = buildJoinedRoomsRequest(
        protocol: protocol,
        homeserver: store.state.userStore.homeserver,
        accessToken: store.state.userStore.user.accessToken,
      );

      final response = await http.get(
        request['url'],
        headers: request['headers'],
      );

      final data = json.decode(response.body);

      if (data['errcode'] != null) {
        throw data['error'];
      }

      // Convert joined_rooms to Room objects
      final List<dynamic> rawJoinedRooms = data['joined_rooms'];
      final joinedRooms = rawJoinedRooms.map((id) => Room(id: id)).toList();
      store.dispatch(SetRooms(rooms: joinedRooms));
    } catch (error) {
      // WARNING: Silent error, throws error if they have no direct messages
      print('[fetchRooms] error: $error');
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

/*
 Fetch Direct Room Ids
 - fetches id's of direct rooms 
 @riot-bot:matrix.org: [!ajJxpUAIJjYYTzvsHo:matrix.org],
 alekseyparfyonov@gmail.com: [!muTrhMUMwdJSrYlqic:matrix.org] 
*/
ThunkAction<AppState> fetchDirectRooms() {
  return (Store<AppState> store) async {
    try {
      final request = buildDirectRoomsRequest(
        protocol: protocol,
        homeserver: store.state.userStore.homeserver,
        accessToken: store.state.userStore.user.accessToken,
        userId: store.state.userStore.user.userId,
      );

      final response = await http.get(
        request['url'],
        headers: request['headers'],
      );

      final data = json.decode(response.body);

      if (data['errcode'] != null) {
        throw data['error'];
      }

      // Mark specified rooms as direct chats
      final rawDirectRooms = data as Map<String, dynamic>;

      rawDirectRooms.forEach((userId, roomIds) {
        store.dispatch(SetRoom(
            room: Room(
          id: roomIds[0],
          direct: true,
        )));
      });
    } catch (error) {
      print('[fetchDirectRooms] error: $error');
    } finally {}
  };
}

/**
 * Create Room 
 */
ThunkAction<AppState> createRoom({
  String name = 'New Chat',
  String alias,
  String topic,
  String avatarUri,
  List<User> invites,
  bool isDirect = false,
}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));
      await store.dispatch(stopRoomsObserver());

      final request = buildCreateRoom(
        protocol: protocol,
        accessToken: store.state.userStore.user.accessToken,
        homeserver: store.state.userStore.homeserver,
        roomName: name,
        roomTopic: topic,
        roomAlias: alias,
        invites: invites.map((user) => user.userId).toList(),
        isDirect: isDirect,
      );

      final response = await http.post(
        request['url'],
        headers: request['headers'],
        body: json.encode(
          request['body'],
        ),
      );

      final data = json.decode(
        response.body,
      );

      final newRoomId = data['room_id'];

      if (data['errcode'] != null) {
        throw data['error'];
      }

      print('[createRoom] $data $newRoomId');

      if (isDirect) {
        final request = buildSaveAccountData(
          protocol: protocol,
          accessToken: store.state.userStore.user.accessToken,
          homeserver: store.state.userStore.homeserver,
          userId: store.state.userStore.user.userId,
          type: AccountDataTypes.DIRECT,
        );

        final body = {
          invites[0].userId: [newRoomId]
        };

        final response = await http.put(
          request['url'],
          headers: request['headers'],
          body: json.encode(body),
        );

        final data = json.decode(
          response.body,
        );

        print('[DIRECT Save Account Data] $data');

        if (data['errcode'] != null) {
          throw data['error'];
        }

        await store.dispatch(fetchDirectRooms());
      }
      await store.dispatch(startRoomsObserver());

      return newRoomId;
    } catch (error) {
      print('[createRoom] error: $error');
      return null;
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

/**
 * Delete Room
 * 
 * Both leaves and forgets room
 * 
 * TODO: make sure this is in accordance with matrix in that
 * the user can only delete if owning the room, or leave if
 * just a member
 */
ThunkAction<AppState> removeRoom({Room room}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      // submit a leave room request
      final leaveRequest = buildLeaveRoom(
        protocol: protocol,
        accessToken: store.state.userStore.user.accessToken,
        homeserver: store.state.userStore.homeserver,
        roomId: room.id,
      );

      final leaveResponse = await http.post(
        leaveRequest['url'],
        headers: leaveRequest['headers'],
      );

      final leaveData = json.decode(
        leaveResponse.body,
      );

      // Remove the room locally if it's already been removed remotely
      if (leaveData['errcode'] != null) {
        if (leaveData['errcode'] == MatrixErrors.room_unknown) {
          await store.dispatch(RemoveRoom(room: Room(id: room.id)));
        } else if (leaveData['errcode'] == MatrixErrors.room_not_found) {
          await store.dispatch(RemoveRoom(room: Room(id: room.id)));
        }
        throw leaveData['error'];
      }
      if (!kReleaseMode) {
        print('[removeRoom|leaveData] success $leaveData');
      }

      final forgetRequest = buildForgetRoom(
        protocol: protocol,
        accessToken: store.state.userStore.user.accessToken,
        homeserver: store.state.userStore.homeserver,
        roomId: room.id,
      );

      final forgetResponse = await http.post(
        forgetRequest['url'],
        headers: forgetRequest['headers'],
      );

      final forgetData = json.decode(
        forgetResponse.body,
      );

      if (forgetData['errcode'] != null) {
        if (leaveData['errcode'] == MatrixErrors.room_not_found) {
          // TODO: confirm this works, deletes room if it doesn't
          await store.dispatch(RemoveRoom(room: Room(id: room.id)));
        }
        throw forgetData['error'];
      }

      if (room.direct) {
        await store.dispatch(removeDirectRoom(room: room));
      }

      if (!kReleaseMode) {
        print('[removeRoom|forgetData] $forgetData');
        print('[removeRoom|forgetData] room was successfully removed');
      }

      await store.dispatch(RemoveRoom(room: Room(id: room.id)));
    } catch (error) {
      print('[removeRoom] error: $error');
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

/**
 * Remove Direct Room
 * 
 * NOTE: https://github.com/matrix-org/matrix-doc/issues/1519
 * 
 * Fetch the direct rooms list and recalculate it without the
 * given alias
 */
ThunkAction<AppState> removeDirectRoom({Room room}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final request = buildDirectRoomsRequest(
        protocol: protocol,
        homeserver: store.state.userStore.homeserver,
        accessToken: store.state.userStore.user.accessToken,
        userId: store.state.userStore.user.userId,
      );

      final response = await http.get(
        request['url'],
        headers: request['headers'],
      );

      final data = json.decode(response.body);

      if (data['errcode'] != null) {
        throw data['error'];
      }

      final rawDirectRooms = data as Map<String, dynamic>;

      // Remove room id from nested Map<List<String>>
      var filteredDirectRooms = rawDirectRooms.map((key, value) {
        List<dynamic> directRoomIds = List.from(value as List<dynamic>);
        if (directRoomIds.contains(room.id)) {
          directRoomIds.remove(room.id);
        }
        return MapEntry(key, directRoomIds);
      });

      // Filter out empty list entries for a user
      filteredDirectRooms.removeWhere((key, value) {
        final roomIds = value as List<dynamic>;
        return roomIds.isEmpty;
      });

      final saveRequest = buildSaveAccountData(
        protocol: protocol,
        accessToken: store.state.userStore.user.accessToken,
        homeserver: store.state.userStore.homeserver,
        userId: store.state.userStore.user.userId,
        type: AccountDataTypes.DIRECT,
      );

      final saveResponse = await http.put(
        saveRequest['url'],
        headers: saveRequest['headers'],
        body: json.encode(filteredDirectRooms),
      );

      final saveData = json.decode(
        saveResponse.body,
      );

      if (saveData['errcode'] != null) {
        throw saveData['error'];
      }

      print('[removeDirectRoom]');
    } catch (error) {
      print('[removeDirectRoom] error: $error');
    }
  };
}

/**
 * Delete Room
 * 
 * NOTE: https://github.com/vector-im/riot-web/issues/722
 * NOTE: https://github.com/vector-im/riot-web/issues/6978
 * NOTE: https://github.com/matrix-org/matrix-doc/issues/948
 * 
 * Kick all (if owner), tries to delete alias, and leaves
 * TODO: make sure this is in accordance with matrix in that
 * the user can only delete if owning the room, or leave if
 * just a member
 */
ThunkAction<AppState> deleteRoom({Room room}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final deleteRequest = buildLeaveRoom(
        protocol: protocol,
        accessToken: store.state.userStore.user.accessToken,
        homeserver: store.state.userStore.homeserver,
        roomId: room.id,
      );

      final deleteResponse = await http.delete(
        deleteRequest['url'],
        headers: deleteRequest['headers'],
      );

      final deleteData = json.decode(
        deleteResponse.body,
      );

      if (deleteData['errcode'] != null) {
        throw deleteData['error'];
      }

      if (!kReleaseMode) {
        print('[deleteRoom] $deleteData');
        print('[deleteRoom] room was successfully deleted');
      }

      store.dispatch(RemoveRoom(room: Room(id: room.id)));
    } catch (error) {
      print('[deleteRoom] error: $error');
    }
  };
}

/******* DEV TOOLS BEYOND THIS POINT ********/

/**
 * TODO: Explaination of this
 * 
 * LOAD != FETCH
 * 
 * Fetch -> Remote
 * Store -> Hot Cache / Local
 * Load (Hive) -> Cold Cache / Local 
 */
ThunkAction<AppState> storeSync() {
  return (Store<AppState> store) async {
    try {
      // final json = await readFullSyncJson();
      // final json = Cache.hive.get('sync');
      return true;
    } catch (error) {
      debugPrint(error);
      return false;
    }
  };
}

ThunkAction<AppState> loadSync() {
  return (Store<AppState> store) async {
    try {
      // final json = await readFullSyncJson();
      // final json = Cache.hive.get('sync');
      return true;
    } catch (error) {
      debugPrint(error);
      return false;
    }
  };
}

/**
 * Create Draft Room
 * 
 * TODO: make sure this is in accordance with matrix in that
 * A local only room that has not been established with matrix
 * meant to prep a room or first message before actually creating it 
 */
// ThunkAction<AppState> createDraftRoom({
//   String name = 'New Chat',
//   String topic,
//   String avatarUri,
//   List<User> users,
//   bool isDirect = false,
// }) {
//   return (Store<AppState> store) async {
//     try {
//       final draftId = Random.secure().nextInt(1 << 32).toString();

//       final draftRoom = Room(
//         id: draftId,
//         name: name,
//         topic: topic,
//         direct: isDirect,
//         avatarUri: avatarUri,
//         isDraftRoom: true,
//         users: Map.fromIterable(
//           users,
//           key: (user) => user.id,
//           value: (user) => user,
//         ),
//       );

//       await store.dispatch(SetRoom(room: draftRoom));
//       return draftRoom;
//     } catch (error) {
//       print('[createDraftRoom] error: $error');
//       return null;
//     }
//   };
// }

/**
 * TODO: Room Drafts
 * 
 * Convert a draft room to a remote matrix room
 */
// ThunkAction<AppState> convertDraftRoom({
//   Room room,
// }) {
//   return (Store<AppState> store) async {
//     try {
//       if (!room.isDraftRoom) {
//         throw 'Room has already been created';
//       }

//       final newRoomId = await store.dispatch(
//         createRoom(
//           name: room.name,
//           topic: room.topic,
//           invites: room.users,
//           isDirect: room.direct,
//         ),
//       );

//       if (newRoomId == null) {
//         throw 'Failed to convert draft room to a real room';
//       }

//       // To temporarily redirect to the new room in the UI
//       return Room(
//         id: newRoomId,
//         name: room.name,
//       );
//     } catch (error) {
//       print('[createRoom] error: $error');
//       return null;
//     }
//   };
// }

// WARNING: ONLY FOR TESTING OUTPUT
Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();

  return directory.path;
}

// WARNING: ONLY FOR TESTING OUTPUT
Future<File> get _localFile async {
  final path = await _localPath;
  return File('$path/matrix.json');
}

// WARNING: ONLY FOR TESTING OUTPUT
Future<dynamic> readFullSyncJson() async {
  try {
    final file = await _localFile;
    String contents = await file.readAsString();
    return await jsonDecode(contents);
  } catch (error) {
    // If encountering an error, return 0.
    print('readFullSyncJson $error');
    return null;
  } finally {
    print('** Read State From Disk Successfully **');
  }
}
