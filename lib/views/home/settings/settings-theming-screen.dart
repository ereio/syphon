// Flutter imports:
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

// Project imports:
import 'package:syphon/global/themes.dart';
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/string-keys.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/actions.dart';
import 'package:syphon/views/widgets/containers/card-section.dart';
import 'package:syphon/views/widgets/dialogs/dialog-color-picker.dart';

class ThemingSettingsScreen extends StatelessWidget {
  const ThemingSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, Props>(
        distinct: true,
        converter: (Store<AppState> store) => Props.mapStateToProps(store),
        builder: (context, props) {
          double width = MediaQuery.of(context).size.width;

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context, false),
              ),
              title: Text(
                tr(StringKeys.titleViewTheming),
                style: Theme.of(context).textTheme.headline6!.copyWith(
                      color: Colors.white,
                    ),
              ),
            ),
            body: SingleChildScrollView(
              child: Container(
                  child: Column(
                children: <Widget>[
                  CardSection(
                    child: Column(
                      children: [
                        Container(
                          width: width,
                          padding: Dimensions.listPadding,
                          child: Text(
                            'Color',
                            textAlign: TextAlign.start,
                            style: Theme.of(context).textTheme.subtitle2,
                          ),
                        ),
                        ListTile(
                          onTap: () => showDialog(
                            context: context,
                            builder: (BuildContext context) =>
                                DialogColorPicker(
                              title: 'Select Primary Color',
                              resetColor: Colours.cyanSyphon,
                              currentColor: props.primaryColor,
                              onSelectColor: props.onSelectPrimaryColor,
                            ),
                          ),
                          contentPadding: Dimensions.listPadding,
                          title: Text(
                            'Primary Color',
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                          trailing: CircleAvatar(
                            radius: 16,
                            backgroundColor: Color(props.primaryColor),
                          ),
                        ),
                        ListTile(
                          onTap: () => showDialog(
                            context: context,
                            builder: (BuildContext context) =>
                                DialogColorPicker(
                              title: 'Select Accent Color',
                              resetColor: Colours.cyanSyphon,
                              currentColor: props.accentColor,
                              onSelectColor: props.onSelectAccentColor,
                            ),
                          ),
                          contentPadding: Dimensions.listPadding,
                          title: Text(
                            'Accent Color',
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                          trailing: CircleAvatar(
                            radius: 16,
                            backgroundColor: Color(props.accentColor),
                          ),
                        ),
                        ListTile(
                          onTap: () => showDialog(
                            context: context,
                            builder: (BuildContext context) =>
                                DialogColorPicker(
                              title: 'Select App Bar Color',
                              resetColor: Colours.cyanSyphon,
                              currentColor: props.appBarColor,
                              onSelectColor: props.onSelectAppBarColor,
                            ),
                          ),
                          contentPadding: Dimensions.listPadding,
                          title: Text(
                            'App Bar Color',
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                          trailing: CircleAvatar(
                            radius: 16,
                            backgroundColor: Color(props.appBarColor),
                          ),
                        ),
                        ListTile(
                          onTap: () => props.onIncrementThemeType(),
                          contentPadding: Dimensions.listPadding,
                          title: Text(
                            'Theme',
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                          trailing: Text(
                            props.themeType,
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
                            'Fonts',
                            textAlign: TextAlign.start,
                            style: Theme.of(context).textTheme.subtitle2,
                          ),
                        ),
                        ListTile(
                          contentPadding: Dimensions.listPadding,
                          title: Text(
                            'Font',
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                          trailing: Text(
                            props.fontName.name,
                          ),
                          onTap: () => props.onIncrementFontType(),
                        ),
                        ListTile(
                          contentPadding: Dimensions.listPadding,
                          title: Text(
                            'Font Size',
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                          trailing: Text(
                            props.fontSize.name,
                          ),
                          onTap: () => props.onIncrementFontSize(),
                        ),
                        ListTile(
                          contentPadding: Dimensions.listPadding,
                          title: Text(
                            'Message Size',
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                          trailing: Text(
                            props.messageSize.name,
                          ),
                          onTap: () => props.onIncrementMessageSize(),
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
                            'App',
                            textAlign: TextAlign.start,
                            style: Theme.of(context).textTheme.subtitle2,
                          ),
                        ),
                        ListTile(
                          contentPadding: Dimensions.listPadding,
                          title: Text(
                            'Room Type Badges',
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                          trailing: Container(
                            child: Switch(
                              value: props.roomTypeBadgesEnabled,
                              onChanged: (value) =>
                                  props.onToggleRoomTypeBadges(),
                            ),
                          ),
                          onTap: () => props.onToggleRoomTypeBadges(),
                        ),
                        ListTile(
                          onTap: () => props.onIncrementAvatarShape(),
                          contentPadding: Dimensions.listPadding,
                          title: Text(
                            'Avatar Shape',
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                          trailing: Text(
                            props.avatarShape.name,
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
  final int primaryColor;
  final int accentColor;
  final int appBarColor;
  final String themeType;
  final String language;
  final FontName fontName;
  final FontSize fontSize;
  final MessageSize messageSize;
  final AvatarShape avatarShape;

  final bool roomTypeBadgesEnabled;

  final Function onSelectPrimaryColor;
  final Function onSelectAccentColor;
  final Function onSelectAppBarColor;
  final Function onIncrementFontType;
  final Function onIncrementFontSize;
  final Function onIncrementMessageSize;
  final Function onIncrementThemeType;
  final Function onToggleRoomTypeBadges;
  final Function onIncrementAvatarShape;

  Props({
    required this.primaryColor,
    required this.accentColor,
    required this.appBarColor,
    required this.themeType,
    required this.language,
    required this.fontName,
    required this.fontSize,
    required this.messageSize,
    required this.avatarShape,
    required this.roomTypeBadgesEnabled,
    required this.onSelectPrimaryColor,
    required this.onSelectAccentColor,
    required this.onSelectAppBarColor,
    required this.onIncrementFontType,
    required this.onIncrementFontSize,
    required this.onIncrementThemeType,
    required this.onToggleRoomTypeBadges,
    required this.onIncrementAvatarShape,
    required this.onIncrementMessageSize,
  });

  @override
  List<Object> get props => [
        primaryColor,
        accentColor,
        appBarColor,
        themeType,
        language,
        fontName,
        fontSize,
        avatarShape,
        roomTypeBadgesEnabled,
      ];

  static Props mapStateToProps(Store<AppState> store) => Props(
        primaryColor:
            store.state.settingsStore.appTheme.primaryColor ?? Colours.cyanSyphon,
        accentColor:
            store.state.settingsStore.appTheme.accentColor ?? Colours.cyanSyphon,
        appBarColor:
            store.state.settingsStore.appTheme.appBarColor ?? Colours.cyanSyphon,
        themeType: store.state.settingsStore.appTheme.themeType.name,
        language: store.state.settingsStore.language,
        fontName: store.state.settingsStore.appTheme.fontName,
        fontSize: store.state.settingsStore.appTheme.fontSize,
        messageSize: store.state.settingsStore.appTheme.messageSize,
        avatarShape: store.state.settingsStore.appTheme.avatarShape,
        roomTypeBadgesEnabled: store.state.settingsStore.roomTypeBadgesEnabled,
        onToggleRoomTypeBadges: () => store.dispatch(
          toggleRoomTypeBadges(),
        ),
        onSelectPrimaryColor: (int color) => store.dispatch(
          // convert to int hex color code
          selectPrimaryColor(color),
        ),
        onSelectAccentColor: (int color) => store.dispatch(
          // convert to int hex color code
          selectAccentColor(color),
        ),
        onSelectAppBarColor: (int color) => store.dispatch(
          // convert to int hex color code
          updateAppBarColor(color),
        ),
        onIncrementFontType: () => store.dispatch(
          incrementFontType(),
        ),
        onIncrementFontSize: () => store.dispatch(
          incrementFontSize(),
        ),
        onIncrementMessageSize: () => store.dispatch(
          incrementMessageSize(),
        ),
        onIncrementThemeType: () => store.dispatch(
          incrementThemeType(),
        ),
        onIncrementAvatarShape: () => store.dispatch(
          incrementAvatarShape(),
        ),
      );
}
