// Flutter imports:
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/svg.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/assets.dart';

// Project imports:
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/store/events/actions.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/rooms/selectors.dart';

class ChatInput extends StatefulWidget {
  final String roomId;
  final bool sending;
  final bool enterSend;
  final Message? quotable;
  final String? mediumType;
  final FocusNode focusNode;
  final TextEditingController controller;

  final Function? onSubmitMessage;
  final Function? onSubmittedMessage;
  final Function? onChangeMethod;
  final Function? onUpdateMessage;
  final Function? onCancelReply;

  const ChatInput({
    Key? key,
    required this.roomId,
    required this.focusNode,
    required this.controller,
    this.mediumType,
    this.quotable,
    this.sending = false,
    this.enterSend = false,
    this.onUpdateMessage,
    this.onChangeMethod,
    this.onSubmitMessage,
    this.onSubmittedMessage,
    this.onCancelReply,
  }) : super(key: key);

  @override
  ChatInputState createState() => ChatInputState();
}

class ChatInputState extends State<ChatInput> {
  ChatInputState({
    Key? key,
  }) : super();

  bool sendable = false;

  Timer? typingNotifier;
  Timer? typingNotifierTimeout;

  Color inputTextColor = const Color(Colours.blackDefault);
  Color inputColorBackground = const Color(Colours.greyEnabled);
  Color inputCursorColor = Colors.blueGrey;
  Color? sendButtonColor = const Color(Colours.greyDisabled);
  String hintText = Strings.placeholderInputMatrixUnencrypted;

  @protected
  onMounted(_Props props) {
    final draft = props.room.draft;

    if (draft != null && draft.type == MessageTypes.TEXT) {
      setState(() {
        sendable = draft.body != null && draft.body!.isNotEmpty;
      });
    }

    widget.focusNode.addListener(() {
      if (!widget.focusNode.hasFocus && this.typingNotifier != null) {
        this.typingNotifier!.cancel();
        setState(() {
          typingNotifier = null;
        });
      }
    });

    if (Theme.of(context).brightness == Brightness.dark) {
      setState(() {
        inputTextColor = Colors.white;
        inputCursorColor = Colors.white;
        inputColorBackground = Colors.blueGrey;
      });
    }
  }

  @protected
  onUpdate(String text, {_Props? props}) {
    setState(() {
      sendable = text.trim().isNotEmpty;
    });

    // start an interval for updating typing status
    if (widget.focusNode.hasFocus && typingNotifier == null) {
      props!.onSendTyping(typing: true, roomId: props.room.id);
      setState(() {
        typingNotifier = Timer.periodic(
          Duration(milliseconds: 4000),
          (timer) => props.onSendTyping(typing: true, roomId: props.room.id),
        );
      });
    }

    // Handle a timeout of the interval if the user idles with input focused
    if (widget.focusNode.hasFocus) {
      if (typingNotifierTimeout != null) {
        this.typingNotifierTimeout!.cancel();
      }

      setState(() {
        typingNotifierTimeout = Timer(Duration(milliseconds: 4000), () {
          if (typingNotifier != null) {
            this.typingNotifier!.cancel();
            setState(() {
              typingNotifier = null;
              typingNotifierTimeout = null;
            });
            // run after to avoid flickering
            props!.onSendTyping(typing: false, roomId: props.room.id);
          }
        });
      });
    }
    if (widget.onUpdateMessage != null) {
      widget.onUpdateMessage!(text);
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (this.typingNotifier != null) {
      this.typingNotifier!.cancel();
    }

    if (this.typingNotifierTimeout != null) {
      this.typingNotifierTimeout!.cancel();
    }
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) =>
            _Props.mapStateToProps(store, widget.roomId),
        onInitialBuild: onMounted,
        builder: (context, props) {
          final double width = MediaQuery.of(context).size.width;
          final double height = MediaQuery.of(context).size.height;

          // dynamic dimensions
          final double messageInputWidth = width - 72;
          final bool replying =
              widget.quotable != null && widget.quotable!.sender != null;
          final double maxHeight = replying ? height * 0.45 : height * 0.5;

          final isSendable = sendable && !widget.sending;
          if (widget.mediumType == MediumType.plaintext) {
            if (isSendable) {
              if (Theme.of(context).accentColor !=
                  Theme.of(context).primaryColor) {
                sendButtonColor = Theme.of(context).accentColor;
              } else {
                sendButtonColor = Colors.grey[700];
              }
            }
          }

          if (widget.mediumType == MediumType.encryption) {
            hintText = Strings.placeholderInputMatrixEncrypted;

            if (isSendable) {
              sendButtonColor = Theme.of(context).primaryColor;
            }
          }

          var sendButton = InkWell(
            borderRadius: BorderRadius.circular(48),
            onLongPress: widget.onChangeMethod as void Function()?,
            onTap:
                !isSendable ? null : widget.onSubmitMessage as void Function()?,
            child: CircleAvatar(
              backgroundColor: sendButtonColor,
              child: Container(
                margin: EdgeInsets.only(left: 2, top: 3),
                child: SvgPicture.asset(
                  Assets.iconSendUnlockBeing,
                  color: Colors.white,
                  semanticsLabel: Strings.semanticsSendUnencrypted,
                ),
              ),
            ),
          );

          if (widget.mediumType == MediumType.encryption) {
            sendButton = InkWell(
              borderRadius: BorderRadius.circular(48),
              onLongPress: widget.onChangeMethod as void Function()?,
              onTap: !isSendable
                  ? null
                  : widget.onSubmitMessage as void Function()?,
              child: CircleAvatar(
                backgroundColor: sendButtonColor,
                child: Container(
                  margin: EdgeInsets.only(left: 2, top: 3),
                  child: SvgPicture.asset(
                    Assets.iconSendLockSolidBeing,
                    color: Colors.white,
                    semanticsLabel: Strings.semanticsSendUnencrypted,
                  ),
                ),
              ),
            );
          }

          return Column(
            children: [
              Visibility(
                visible: replying,
                maintainSize: false,
                maintainState: false,
                maintainAnimation: false,
                child: Row(
                  //////// REPLY FIELD ////////
                  children: <Widget>[
                    Stack(
                      children: [
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: messageInputWidth,
                          ),
                          child: TextField(
                            maxLines: 1,
                            enabled: false,
                            autocorrect: false,
                            enableSuggestions: false,
                            controller: TextEditingController(
                              text: replying ? widget.quotable!.body : '',
                            ),
                            style: TextStyle(
                              color: inputTextColor,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              labelText:
                                  replying ? widget.quotable!.sender : '',
                              labelStyle: TextStyle(
                                  color: Theme.of(context).accentColor),
                              contentPadding: Dimensions.inputContentPadding
                                  .copyWith(right: 36),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Theme.of(context).accentColor,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  topRight: Radius.circular(24),
                                  bottomLeft:
                                      Radius.circular(!replying ? 24 : 0),
                                  bottomRight:
                                      Radius.circular(!replying ? 24 : 0),
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Theme.of(context).accentColor,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  topRight: Radius.circular(24),
                                  bottomLeft:
                                      Radius.circular(!replying ? 24 : 0),
                                  bottomRight:
                                      Radius.circular(!replying ? 24 : 0),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          bottom: 0,
                          child: IconButton(
                            onPressed: () => widget.onCancelReply!(),
                            icon: Icon(
                              Icons.close,
                              size: Dimensions.iconSize,
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              Row(
                //////// ACTUAL INPUT FIELD ////////
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: maxHeight,
                      maxWidth: messageInputWidth,
                    ),
                    child: TextField(
                      maxLines: null,
                      autocorrect: false,
                      enableSuggestions: false,
                      keyboardType: TextInputType.multiline,
                      textInputAction: widget.enterSend
                          ? TextInputAction.send
                          : TextInputAction.newline,
                      cursorColor: inputCursorColor,
                      focusNode: widget.focusNode,
                      controller: widget.controller,
                      onChanged: (text) => onUpdate(text, props: props),
                      onSubmitted: !sendable
                          ? null
                          : widget.onSubmittedMessage as void Function(String)?,
                      style: TextStyle(
                        height: 1.5,
                        color: inputTextColor,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        hintText: hintText,
                        fillColor: inputColorBackground,
                        contentPadding: Dimensions.inputContentPadding,
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).accentColor, width: 1),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(!replying ? 24 : 0),
                              topRight: Radius.circular(!replying ? 24 : 0),
                              bottomLeft: Radius.circular(24),
                              bottomRight: Radius.circular(24),
                            )),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(!replying ? 24 : 0),
                          topRight: Radius.circular(!replying ? 24 : 0),
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        )),
                      ),
                    ),
                  ),
                  Container(
                    width: Dimensions.buttonSendSize,
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: sendButton,
                  ),
                ],
              )
            ],
          );
        },
      );
}

class _Props extends Equatable {
  final Room room;
  final bool enterSendEnabled;

  final Function onSendTyping;

  _Props({
    required this.room,
    required this.enterSendEnabled,
    required this.onSendTyping,
  });

  @override
  List<Object> get props => [
        room,
        enterSendEnabled,
      ];

  static _Props mapStateToProps(Store<AppState> store, String roomId) => _Props(
        room: selectRoom(id: roomId, state: store.state),
        enterSendEnabled: store.state.settingsStore.enterSendEnabled,
        onSendTyping: ({typing, roomId}) => store.dispatch(
          sendTyping(typing: typing, roomId: roomId),
        ),
      );
}
