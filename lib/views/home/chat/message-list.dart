// Flutter imports:
import 'package:emoji_picker/emoji_picker.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

// Project imports:
import 'package:syphon/global/themes.dart';
import 'package:syphon/store/events/actions.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/messages/selectors.dart';
import 'package:syphon/store/events/reactions/actions.dart';
import 'package:syphon/store/events/selectors.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/rooms/selectors.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/store/user/selectors.dart';
import 'package:syphon/views/widgets/messages/message-typing.dart';
import 'package:syphon/views/widgets/messages/message.dart';

class MessageList extends StatefulWidget {
  final String roomId;
  final Message selectedMessage;
  final ScrollController scrollController;

  final Function onSelectReply;
  final Function onViewUserDetails;
  final void Function(Message) onToggleSelectedMessage;

  const MessageList({
    Key key,
    @required this.roomId,
    @required this.scrollController,
    this.selectedMessage,
    this.onSelectReply,
    this.onViewUserDetails,
    this.onToggleSelectedMessage,
  }) : super(key: key);

  @override
  MessageListState createState() => MessageListState();
}

class MessageListState extends State<MessageList> {
  MessageListState({
    Key key,
  }) : super();
  final TextEditingController controller = TextEditingController();

  @protected
  onMounted(_Props props) {}

  @protected
  onInputReaction({Message message, _Props props}) async {
    final height = MediaQuery.of(context).size.height;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: height / 2.2,
        padding: EdgeInsets.symmetric(
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: EmojiPicker(
            rows: 7,
            columns: 9,
            indicatorColor: Theme.of(context).accentColor,
            bgColor: Theme.of(context).scaffoldBackgroundColor,
            numRecommended: 10,
            categoryIcons: CategoryIcons(
              smileyIcon: CategoryIcon(icon: Icons.tag_faces_rounded),
              objectIcon: CategoryIcon(icon: Icons.lightbulb),
              travelIcon: CategoryIcon(icon: Icons.flight),
              activityIcon: CategoryIcon(icon: Icons.sports_soccer),
              symbolIcon: CategoryIcon(icon: Icons.tag),
            ),
            onEmojiSelected: (emoji, category) {
              props.onToggleReaction(
                emoji: emoji.emoji,
                message: message,
              );

              Navigator.pop(context, false);
              widget.onToggleSelectedMessage(null);
            }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) =>
            _Props.mapStateToProps(store, widget.roomId),
        onInitialBuild: onMounted,
        builder: (context, props) {
          return GestureDetector(
            onTap: () => widget.onToggleSelectedMessage(null),
            child: ListView(
              reverse: true,
              padding: EdgeInsets.only(bottom: 12),
              physics: widget.selectedMessage != null
                  ? const NeverScrollableScrollPhysics()
                  : null,
              controller: widget.scrollController,
              children: [
                MessageTypingWidget(
                  roomUsers: props.users,
                  typing: props.room.userTyping,
                  usersTyping: props.room.usersTyping,
                  selectedMessageId: widget.selectedMessage != null
                      ? widget.selectedMessage.id
                      : null,
                  onPressAvatar: widget.onViewUserDetails,
                ),
                ListView.builder(
                  reverse: true,
                  shrinkWrap: true,
                  padding: EdgeInsets.only(bottom: 4),
                  addRepaintBoundaries: true,
                  addAutomaticKeepAlives: true,
                  itemCount: props.messages.length,
                  scrollDirection: Axis.vertical,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    final message = props.messages[index];
                    final lastMessage =
                        index != 0 ? props.messages[index - 1] : null;
                    final nextMessage = index + 1 < props.messages.length
                        ? props.messages[index + 1]
                        : null;

                    final isLastSender = lastMessage != null &&
                        lastMessage.sender == message.sender;
                    final isNextSender = nextMessage != null &&
                        nextMessage.sender == message.sender;
                    final isUserSent =
                        props.currentUser.userId == message.sender;

                    final selectedMessageId = widget.selectedMessage != null
                        ? widget.selectedMessage.id
                        : null;

                    final avatarUri = props.users[message.sender]?.avatarUri;

                    return MessageWidget(
                      message: message,
                      isUserSent: isUserSent,
                      isLastSender: isLastSender,
                      isNextSender: isNextSender,
                      lastRead: props.room.lastRead,
                      selectedMessageId: selectedMessageId,
                      avatarUri: avatarUri,
                      theme: props.theme,
                      fontSize: 14,
                      timeFormat: props.timeFormat24Enabled ? '24hr' : '12hr',
                      onSwipe: props.onSelectReply,
                      onPressAvatar: widget.onViewUserDetails,
                      onLongPress: (msg) => widget.onToggleSelectedMessage(msg),
                      onInputReaction: () => onInputReaction(
                        message: message,
                        props: props,
                      ),
                      onToggleReaction: (emoji) => props.onToggleReaction(
                        emoji: emoji,
                        message: message,
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      );
}

class _Props extends Equatable {
  final Room room;
  final ThemeType theme;
  final User currentUser;
  final Map<String, User> users;
  final List<Message> messages;
  final bool timeFormat24Enabled;

  final Function onToggleReaction;
  final Function onSelectReply;

  _Props({
    @required this.room,
    @required this.theme,
    @required this.users,
    @required this.messages,
    @required this.currentUser,
    @required this.timeFormat24Enabled,
    @required this.onToggleReaction,
    @required this.onSelectReply,
  });

  @override
  List<Object> get props => [
        room,
        users,
        messages,
      ];

  static _Props mapStateToProps(Store<AppState> store, String roomId) => _Props(
        timeFormat24Enabled: store.state.settingsStore.timeFormat24Enabled,
        theme: store.state.settingsStore.theme,
        currentUser: store.state.authStore.user,
        room: selectRoom(id: roomId, state: store.state),
        users: messageUsers(roomId: roomId, state: store.state),
        messages: latestMessages(
          filterMessages(
            combineOutbox(
              messages: roomMessages(store.state, roomId),
              outbox: selectRoom(id: roomId, state: store.state).outbox,
            ),
            store.state,
          ),
        ),
        onSelectReply: (Message message) {
          store.dispatch(selectReply(roomId: roomId, message: message));
        },
        onToggleReaction: ({Message message, String emoji}) {
          final room = selectRoom(id: roomId, state: store.state);

          store.dispatch(
            toggleReaction(room: room, message: message, emoji: emoji),
          );
        },
      );
}
