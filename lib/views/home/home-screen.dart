// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:fab_circular_menu/fab_circular_menu.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/colours.dart';
import 'package:syphon/store/settings/theme-settings/model.dart';
import 'package:syphon/store/events/selectors.dart';
import 'package:url_launcher/url_launcher.dart';

// Project imports:
import 'package:syphon/global/assets.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/formatters.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/rooms/room/selectors.dart';
import 'package:syphon/store/rooms/selectors.dart';
import 'package:syphon/store/settings/chat-settings/model.dart';
import 'package:syphon/store/sync/actions.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/views/home/chat/details-chat-screen.dart';
import 'package:syphon/views/home/chat/chat-screen.dart';
import 'package:syphon/views/widgets/avatars/avatar-app-bar.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';
import 'package:syphon/views/widgets/containers/menu-rounded.dart';
import 'package:syphon/views/widgets/containers/ring-actions.dart';

enum Options { newGroup, markAllRead, inviteFriends, settings, licenses, help }

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<HomeScreen> {
  HomeState({Key? key}) : super();

  final GlobalKey<FabCircularMenuState> fabKey =
      GlobalKey<FabCircularMenuState>();

  Room? selectedRoom;
  late Map<String, Color?> roomColorDefaults;

  @override
  void initState() {
    super.initState();
    roomColorDefaults = Map();
  }

  @protected
  onToggleRoomOptions({Room? room}) {
    setState(() {
      selectedRoom = room;
    });
  }

  @protected
  onDismissMessageOptions() {
    setState(() {
      selectedRoom = null;
    });
  }

  @protected
  Widget buildAppBarRoomOptions({BuildContext? context, _Props? props}) =>
      AppBar(
        backgroundColor: Colors.grey[500],
        automaticallyImplyLeading: false,
        titleSpacing: 0.0,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 8),
              child: IconButton(
                icon: Icon(Icons.close),
                color: Colors.white,
                iconSize: Dimensions.buttonAppBarSize,
                onPressed: onDismissMessageOptions,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.info_outline),
            iconSize: Dimensions.buttonAppBarSize,
            tooltip: 'Chat Details',
            color: Colors.white,
            onPressed: () {
              Navigator.pushNamed(
                context!,
                '/home/chat/settings',
                arguments: ChatSettingsArguments(
                  roomId: selectedRoom!.id,
                  title: selectedRoom!.name,
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.archive),
            iconSize: Dimensions.buttonAppBarSize,
            tooltip: 'Archive Room',
            color: Colors.white,
            onPressed: () async {
              await props!.onArchiveRoom(room: this.selectedRoom);
              setState(() {
                selectedRoom = null;
              });
            },
          ),
          Visibility(
            visible: true,
            child: IconButton(
              icon: Icon(Icons.exit_to_app),
              iconSize: Dimensions.buttonAppBarSize,
              tooltip: 'Leave Chat',
              color: Colors.white,
              onPressed: () async {
                await props!.onLeaveChat(room: this.selectedRoom);
                setState(() {
                  selectedRoom = null;
                });
              },
            ),
          ),
          Visibility(
            visible: this.selectedRoom!.direct,
            child: IconButton(
              icon: Icon(Icons.delete_outline),
              iconSize: Dimensions.buttonAppBarSize,
              tooltip: 'Delete Chat',
              color: Colors.white,
              onPressed: () async {
                await props!.onDeleteChat(room: this.selectedRoom);
                setState(() {
                  selectedRoom = null;
                });
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.select_all),
            iconSize: Dimensions.buttonAppBarSize,
            tooltip: 'Select All',
            color: Colors.white,
            onPressed: () {},
          ),
        ],
      );

  @protected
  Widget buildAppBar({required BuildContext context, required _Props props}) =>
      AppBar(
        automaticallyImplyLeading: false,
        brightness: Brightness.dark,
        titleSpacing: 16.00,
        title: Row(
          children: <Widget>[
            AvatarAppBar(
              themeType: props.themeType,
              user: props.currentUser,
              offline: props.offline,
              syncing: props.syncing,
              unauthed: props.unauthed,
              tooltip: 'Profile and Settings',
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
            Text(
              Values.appName,
              style: Theme.of(context).textTheme.headline6!.copyWith(
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            color: Colors.white,
            icon: Icon(Icons.search),
            tooltip: 'Search Chats',
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
          ),
          RoundedPopupMenu<Options>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onSelected: (Options result) {
              switch (result) {
                case Options.newGroup:
                  Navigator.pushNamed(context, '/home/groups/create');
                  break;
                case Options.markAllRead:
                  props.onMarkAllRead();
                  break;
                case Options.settings:
                  Navigator.pushNamed(context, '/settings');
                  break;
                case Options.help:
                  props.onSelectHelp();
                  break;
                default:
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<Options>>[
              const PopupMenuItem<Options>(
                value: Options.newGroup,
                child: Text('New Group'),
              ),
              const PopupMenuItem<Options>(
                value: Options.markAllRead,
                child: Text('Mark All Read'),
              ),
              const PopupMenuItem<Options>(
                value: Options.inviteFriends,
                enabled: false,
                child: Text('Invite Friends'),
              ),
              const PopupMenuItem<Options>(
                value: Options.settings,
                child: Text('Settings'),
              ),
              const PopupMenuItem<Options>(
                value: Options.help,
                child: Text('Help'),
              ),
            ],
          )
        ],
      );

  @protected
  Widget buildChatList(List<Room> rooms, BuildContext context, _Props props) {
    if (rooms.isEmpty) {
      return Center(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            constraints: BoxConstraints(
              minWidth: Dimensions.mediaSizeMin,
              maxWidth: Dimensions.mediaSizeMax,
              maxHeight: Dimensions.mediaSizeMin,
            ),
            child: SvgPicture.asset(
              Assets.heroChatNotFound,
              semanticsLabel: Strings.semanticsLabelHomeEmpty,
            ),
          ),
          GestureDetector(
            child: Container(
              margin: EdgeInsets.only(bottom: 48),
              padding: EdgeInsets.only(top: 16),
              child: Text(
                props.syncing ? Strings.labelSyncing : Strings.labelNoMessages,
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          ),
        ],
      ));
    }

    return ListView.builder(
      scrollDirection: Axis.vertical,
      itemCount: rooms.length,
      itemBuilder: (BuildContext context, int index) {
        final room = rooms[index];
        final messages = props.messages[room.id] ?? const [];
        final messageLatest = latestMessage(messages);
        final roomSettings = props.chatSettings[room.id] ?? null;
        final preview = formatPreview(room: room, message: messageLatest);

        bool messagesNew = false;
        var backgroundColor;
        var textStyle = TextStyle();
        var primaryColor = Colors.grey[500];

        // Check settings for custom color, then check temp cache,
        // or generate new temp color
        if (roomSettings != null) {
          primaryColor = Color(roomSettings.primaryColor!);
        } else if (roomColorDefaults.containsKey(room.id)) {
          primaryColor = roomColorDefaults[room.id];
        } else {
          primaryColor = Colours.hashedColor(room.id);
          roomColorDefaults.putIfAbsent(
            room.id,
            () => primaryColor,
          );
        }

        // highlight selected rooms if necessary
        if (selectedRoom != null) {
          if (selectedRoom!.id != room.id) {
            backgroundColor = Theme.of(context).scaffoldBackgroundColor;
          } else {
            backgroundColor = Theme.of(context).primaryColor.withAlpha(128);
          }
        }

        // show draft inidicator if it's an empty room
        if (room.drafting || messages.length < 1) {
          textStyle = TextStyle(fontStyle: FontStyle.italic);
        }

        if (messages != null && messages.isNotEmpty) {
          // it has undecrypted message contained within
          if (messageLatest!.type == EventTypes.encrypted &&
              messageLatest.body!.isEmpty) {
            textStyle = TextStyle(fontStyle: FontStyle.italic);
          }

          if (messageLatest.body == null || messageLatest.body!.isEmpty) {
            textStyle = TextStyle(fontStyle: FontStyle.italic);
          }

          // display message as being 'unread'
          if (room.lastRead! < messageLatest.timestamp!) {
            messagesNew = true;
            textStyle = textStyle.copyWith(
              color: Theme.of(context).textTheme.bodyText1!.color,
              fontWeight: FontWeight.w500,
            );
          }
        }

        // GestureDetector w/ animation
        return InkWell(
          onTap: () {
            if (this.selectedRoom != null) {
              this.onDismissMessageOptions();
            } else {
              Navigator.pushNamed(
                context,
                '/home/chat',
                arguments: ChatViewArguements(
                  roomId: room.id,
                  title: room.name,
                ),
              );
            }
          },
          onLongPress: () => onToggleRoomOptions(room: room),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor, // if selected, color seperately
            ),
            padding: EdgeInsets.symmetric(
              vertical: Theme.of(context).textTheme.subtitle1!.fontSize!,
            ).add(Dimensions.appPaddingHorizontal),
            child: Flex(
              direction: Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      Avatar(
                        uri: room.avatarUri,
                        size: Dimensions.avatarSizeMin,
                        alt: formatRoomInitials(room: room),
                        background: primaryColor,
                      ),
                      Visibility(
                        visible: !room.encryptionEnabled,
                        child: Positioned(
                          bottom: 0,
                          right: 0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              Dimensions.badgeAvatarSize,
                            ),
                            child: Container(
                              width: Dimensions.badgeAvatarSize,
                              height: Dimensions.badgeAvatarSize,
                              color: Theme.of(context).scaffoldBackgroundColor,
                              child: Icon(
                                Icons.lock_open,
                                color: Theme.of(context).iconTheme.color,
                                size: Dimensions.iconSizeMini,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: props.roomTypeBadgesEnabled && room.invite,
                        child: Positioned(
                          bottom: 0,
                          right: 0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: Dimensions.badgeAvatarSize,
                              height: Dimensions.badgeAvatarSize,
                              color: Theme.of(context).scaffoldBackgroundColor,
                              child: Icon(
                                Icons.mail_outline,
                                color: Theme.of(context).iconTheme.color,
                                size: Dimensions.iconSizeMini,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: messagesNew,
                        child: Positioned(
                          top: 0,
                          right: 0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: Dimensions.badgeAvatarSizeSmall,
                              height: Dimensions.badgeAvatarSizeSmall,
                              color: Theme.of(context).accentColor,
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: props.roomTypeBadgesEnabled &&
                            room.type == 'group' &&
                            !room.invite,
                        child: Positioned(
                          right: 0,
                          bottom: 0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: Dimensions.badgeAvatarSize,
                              height: Dimensions.badgeAvatarSize,
                              color: Theme.of(context).scaffoldBackgroundColor,
                              child: Icon(
                                Icons.group,
                                color: Theme.of(context).iconTheme.color,
                                size: Dimensions.badgeAvatarSizeSmall,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: props.roomTypeBadgesEnabled &&
                            room.type == 'public' &&
                            !room.invite,
                        child: Positioned(
                          right: 0,
                          bottom: 0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: Dimensions.badgeAvatarSize,
                              height: Dimensions.badgeAvatarSize,
                              color: Theme.of(context).scaffoldBackgroundColor,
                              child: Icon(
                                Icons.public,
                                color: Theme.of(context).iconTheme.color,
                                size: Dimensions.badgeAvatarSize,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  flex: 1,
                  fit: FlexFit.tight,
                  child: Flex(
                    direction: Axis.vertical,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              room.name!,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyText1,
                            ),
                          ),
                          Text(
                            formatTimestamp(lastUpdateMillis: room.lastUpdate),
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w100),
                          ),
                        ],
                      ),
                      Container(
                        child: Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.caption!.merge(
                                textStyle,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStateToProps(store),
        builder: (context, props) {
          var currentAppBar = buildAppBar(
            props: props,
            context: context,
          );

          if (this.selectedRoom != null) {
            currentAppBar = buildAppBarRoomOptions(
              props: props,
              context: context,
            );
          }

          return Scaffold(
            appBar: currentAppBar as PreferredSizeWidget?,
            floatingActionButton: ActionRing(fabKey: fabKey),
            body: Align(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () {
                        return props.onFetchSyncForced();
                      },
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: this.onDismissMessageOptions,
                            child: buildChatList(
                              props.rooms,
                              context,
                              props,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

class _Props extends Equatable {
  final List<Room> rooms;
  final bool? offline;
  final bool syncing;
  final bool unauthed;
  final bool roomTypeBadgesEnabled;
  final User currentUser;
  final ThemeType themeType;
  final Map<String, ChatSetting> chatSettings;
  final Map<String, List<Message>?> messages;

  final Function onDebug;
  final Function onLeaveChat;
  final Function onDeleteChat;
  final Function onSelectHelp;
  final Function onArchiveRoom;
  final Function onMarkAllRead;
  final Function onFetchSyncForced;

  _Props({
    required this.rooms,
    required this.themeType,
    required this.offline,
    required this.syncing,
    required this.unauthed,
    required this.messages,
    required this.currentUser,
    required this.chatSettings,
    required this.roomTypeBadgesEnabled,
    required this.onDebug,
    required this.onLeaveChat,
    required this.onDeleteChat,
    required this.onSelectHelp,
    required this.onArchiveRoom,
    required this.onMarkAllRead,
    required this.onFetchSyncForced,
  });

  @override
  List<Object?> get props => [
        rooms,
        themeType,
        syncing,
        offline,
        unauthed,
        currentUser,
        chatSettings,
      ];

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        themeType: store.state.settingsStore.appTheme.themeType,
        rooms: availableRooms(sortedPrioritizedRooms(filterBlockedRooms(
          store.state.roomStore.rooms.values.toList(),
          store.state.userStore.blocked,
        ))),
        messages: store.state.eventStore.messages,
        unauthed: store.state.syncStore.unauthed,
        offline: store.state.syncStore.offline,
        syncing: () {
          final synced = store.state.syncStore.synced;
          final syncing = store.state.syncStore.syncing;
          final offline = store.state.syncStore.offline;
          final backgrounded = store.state.syncStore.backgrounded;
          final loadingRooms = store.state.roomStore.loading;

          final lastAttempt = DateTime.fromMillisecondsSinceEpoch(
              store.state.syncStore.lastAttempt ?? 0);

          // See if the last attempted sy nc is older than 60 seconds
          final isLastAttemptOld = DateTime.now()
              .difference(lastAttempt)
              .compareTo(Duration(seconds: 90));

          // syncing for the first time
          if (syncing && !synced) {
            return true;
          }

          // syncing for the first time since going offline
          if (syncing && offline) {
            return true;
          }

          // joining or removing a room
          if (loadingRooms) {
            return true;
          }

          // syncing for the first time in a while or restarting the app
          if (syncing && (0 < isLastAttemptOld || backgrounded)) {
            return true;
          }

          return false;
        }(),
        currentUser: store.state.authStore.user,
        roomTypeBadgesEnabled: store.state.settingsStore.roomTypeBadgesEnabled,
        chatSettings: store.state.settingsStore.customChatSettings ?? Map(),
        onDebug: () async {
          debugPrint('[onDebug] trigged debug function @ home');
        },
        onMarkAllRead: () {
          store.dispatch(markRoomsReadAll());
        },
        onArchiveRoom: ({Room? room}) async {
          store.dispatch(archiveRoom(room: room));
        },
        onFetchSyncForced: () async {
          await store.dispatch(
            fetchSync(since: store.state.syncStore.lastSince),
          );
          return Future(() => true);
        },
        onLeaveChat: ({Room? room}) {
          return store.dispatch(leaveRoom(room: room));
        },
        onDeleteChat: ({Room? room}) {
          return store.dispatch(removeRoom(room: room));
        },
        onSelectHelp: () async {
          try {
            if (await canLaunch(Values.openHelpUrl)) {
              await launch(Values.openHelpUrl);
            } else {
              throw 'Could not launch ${Values.openHelpUrl}';
            }
          } catch (error) {}
        },
      );
}
