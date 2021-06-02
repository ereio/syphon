// Flutter imports:
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

// Project imports:
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/string-keys.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/actions.dart';
import 'package:syphon/views/widgets/containers/card-section.dart';

class ChatSettingsScreen extends StatelessWidget {
  const ChatSettingsScreen({Key? key}) : super(key: key);

  displayThemeType(String themeTypeName) {
    return themeTypeName.split('.')[1].toLowerCase();
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, Props>(
        distinct: true,
        converter: (Store<AppState> store) =>
            Props.mapStateToProps(store, context),
        builder: (context, props) {
          double width = MediaQuery.of(context).size.width;

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context, false),
              ),
              title: Text(
                tr(StringKeys.titleViewPreferencesChat),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w100,
                ),
              ),
            ),
            body: SingleChildScrollView(
              child: Container(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: <Widget>[
                      CardSection(
                        child: Column(
                          children: [
                            Container(
                              width: width,
                              padding: Dimensions.listPadding,
                              child: Text(
                                'Chats',
                                textAlign: TextAlign.start,
                                style: Theme.of(context).textTheme.subtitle2,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => props.onDisabled(),
                              child: ListTile(
                                onTap: () => props.onIncrementLanguage(),
                                contentPadding: Dimensions.listPadding,
                                title: Text(
                                  'Language',
                                ),
                                trailing: Text(props.language!),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => props.onDisabled(),
                              child: ListTile(
                                enabled: false,
                                contentPadding: Dimensions.listPadding,
                                title: Text(
                                  'Show Membership Events',
                                ),
                                subtitle: Text(
                                  'Show membership changes within the chat',
                                  style: Theme.of(context).textTheme.caption,
                                ),
                                trailing: Switch(
                                  value: false,
                                  inactiveThumbColor:
                                      Color(Colours.greyDisabled),
                                  onChanged: (showMembershipEvents) {},
                                ),
                              ),
                            ),
                            ListTile(
                              onTap: () => props.onToggleEnterSend(),
                              contentPadding: Dimensions.listPadding,
                              title: Text(
                                'Enter Key Sends',
                              ),
                              subtitle: Text(
                                'Pressing the enter key will send a message',
                                style: Theme.of(context).textTheme.caption,
                              ),
                              trailing: Switch(
                                value: props.enterSend!,
                                onChanged: (enterSend) =>
                                    props.onToggleEnterSend(),
                              ),
                            ),
                            ListTile(
                              onTap: () => props.onToggleTimeFormat(),
                              contentPadding: Dimensions.listPadding,
                              title: Text(
                                '24 Hour Time Format',
                              ),
                              subtitle: Text(
                                'Show message timestamps using 24 hour format',
                                style: Theme.of(context).textTheme.caption,
                              ),
                              trailing: Switch(
                                value: props.timeFormat24!,
                                onChanged: (value) =>
                                    props.onToggleTimeFormat(),
                              ),
                            ),
                            ListTile(
                              onTap: () => props.onToggleDismissKeyboard(),
                              contentPadding: Dimensions.listPadding,
                              title: Text(
                                'Dismiss Keyboard',
                              ),
                              subtitle: Text(
                                'Dismiss the keyboard after sending a message',
                                style: Theme.of(context).textTheme.caption,
                              ),
                              trailing: Switch(
                                value: props.dismissKeyboard!,
                                onChanged: (value) =>
                                    props.onToggleDismissKeyboard(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      CardSection(
                        child: Column(
                          children: [
                            Container(
                              width: width,
                              padding: Dimensions.listPadding,
                              child: Text(
                                'Ordering',
                                textAlign: TextAlign.start,
                                style: Theme.of(context).textTheme.subtitle2,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => props.onDisabled(),
                              child: ListTile(
                                contentPadding: Dimensions.listPadding,
                                title: Text(
                                  'Sort By',
                                ),
                                trailing: Text(
                                  'Timestamp',
                                  style: Theme.of(context).textTheme.subtitle1,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => props.onDisabled(),
                              child: ListTile(
                                contentPadding: Dimensions.listPadding,
                                title: Text(
                                  'Group By',
                                ),
                                trailing: Text(
                                  'None',
                                  style: Theme.of(context).textTheme.subtitle1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      CardSection(
                        child: Column(
                          children: [
                            Container(
                              width: width,
                              padding: Dimensions.listPadding,
                              child: Text(
                                'Media',
                                textAlign: TextAlign.start,
                                style: Theme.of(context).textTheme.subtitle2,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => props.onDisabled(),
                              child: ListTile(
                                enabled: false,
                                contentPadding: Dimensions.listPadding,
                                title: Text(
                                  'View all uploaded Media',
                                ),
                                subtitle: Text(
                                  'See all uploaded data, even those unaccessible from messages',
                                  style: Theme.of(context).textTheme.caption,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      CardSection(
                        child: Column(
                          children: [
                            Container(
                              width: width,
                              padding: Dimensions.listPadding,
                              child: Text(
                                'Media auto-download',
                                textAlign: TextAlign.start,
                                style: Theme.of(context).textTheme.subtitle2,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => props.onDisabled(),
                              child: ListTile(
                                enabled: false,
                                contentPadding: Dimensions.listPadding,
                                title: Text(
                                  'When using mobile data',
                                ),
                                subtitle: Text(
                                  'Images, Audio, Video, Documents, Other',
                                  style: Theme.of(context).textTheme.caption,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => props.onDisabled(),
                              child: ListTile(
                                enabled: false,
                                contentPadding: Dimensions.listPadding,
                                title: Text(
                                  'When using Wi-Fi',
                                ),
                                subtitle: Text(
                                  'Images, Audio, Video, Documents, Other',
                                  style: Theme.of(context).textTheme.caption,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => props.onDisabled(),
                              child: ListTile(
                                enabled: false,
                                contentPadding: Dimensions.listPadding,
                                title: Text(
                                  'When Roaming',
                                ),
                                subtitle: Text(
                                  'Images, Audio, Video, Documents, Other',
                                  style: Theme.of(context).textTheme.caption,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )),
            ),
          );
        },
      );
}

class Props extends Equatable {
  final String? language;
  final bool? enterSend;
  final bool? timeFormat24;
  final bool? dismissKeyboard;
  final String chatFontSize;

  final Function onDisabled;
  final Function onIncrementLanguage;
  final Function onToggleEnterSend;
  final Function onToggleTimeFormat;
  final Function onToggleDismissKeyboard;

  Props({
    required this.language,
    required this.enterSend,
    required this.chatFontSize,
    required this.timeFormat24,
    required this.dismissKeyboard,
    required this.onDisabled,
    required this.onIncrementLanguage,
    required this.onToggleEnterSend,
    required this.onToggleTimeFormat,
    required this.onToggleDismissKeyboard,
  });

  @override
  List<Object?> get props => [
        language,
        enterSend,
        chatFontSize,
        timeFormat24,
      ];

  static Props mapStateToProps(Store<AppState> store, BuildContext context) =>
      Props(
        chatFontSize: 'Default',
        language: store.state.settingsStore.language,
        enterSend: store.state.settingsStore.enterSendEnabled,
        timeFormat24: store.state.settingsStore.timeFormat24Enabled,
        dismissKeyboard: store.state.settingsStore.dismissKeyboardEnabled,
        onIncrementLanguage: () {
          store.dispatch(addInfo(message: tr('alert-restart-app-effect')));
          store.dispatch(incrementLanguage(context));
        },
        onToggleDismissKeyboard: () => store.dispatch(toggleDismissKeyboard()),
        onToggleTimeFormat: () => store.dispatch(toggleTimeFormat()),
        onToggleEnterSend: () => store.dispatch(toggleEnterSend()),
        onDisabled: () => store.dispatch(addInProgress()),
      );
}
