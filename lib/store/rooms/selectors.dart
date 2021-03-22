// Project imports:
import 'package:syphon/store/index.dart';
import './room/model.dart';

Room selectRoom({AppState state, String id}) {
  if (state.roomStore.rooms == null) return Room();
  return state.roomStore.rooms[id] ?? Room();
}

List<Room> availableRooms(List<Room> rooms) {
  return List.from(rooms.where((room) => !room.hidden));
}

List<Room> filterBlockedRooms(List<Room> rooms, List<String> blocked) {
  final List<Room> roomList = rooms != null ? rooms : [];

  return roomList
    ..removeWhere((room) =>
        room.userIds.length == 2 &&
        room.userIds.any((userId) => blocked.contains(userId)))
    ..toList();
}

List<Room> sortedPrioritizedRooms(List<Room> rooms) {
  final sortedList = rooms != null ? rooms : [];

  // sort descending
  sortedList.sort((a, b) {
    // Prioritze draft rooms
    if (a.drafting && !b.drafting) {
      return -1;
    }
    if (!a.drafting && b.drafting) {
      return 1;
    }
    if (a.invite && !b.invite) {
      return -1;
    }
    if (!a.invite && b.invite) {
      return 1;
    }
    // Prioritze if a direct chat
    if (a.direct && !b.direct) {
      return -1;
    }
    if (!a.direct && b.direct) {
      return 1;
    }
    // Otherwise, use timestamp
    if (a.lastUpdate > b.lastUpdate) {
      return -1;
    }
    if (a.lastUpdate < b.lastUpdate) {
      return 1;
    }

    return 0;
  });

  return sortedList;
}
