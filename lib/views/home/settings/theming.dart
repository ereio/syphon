import 'package:syphon/global/dimensions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/actions.dart';
import 'package:syphon/global/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';
import 'package:syphon/views/widgets/dialogs/dialog-color-picker.dart';

class Theming extends StatelessWidget {
  Theming({Key key, this.title}) : super(key: key);

  final String title;

  displayThemeType(String themeTypeName) {
    return themeTypeName.split('.')[1].toLowerCase();
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, Props>(
        distinct: true,
        converter: (Store<AppState> store) => Props.mapStateToProps(store),
        builder: (context, props) {
          double width = MediaQuery.of(context).size.width;

          final sectionBackgroundColor =
              Theme.of(context).brightness == Brightness.dark
                  ? const Color(Colours.blackDefault)
                  : const Color(Colours.whiteDefault);

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context, false),
              ),
              title: Text(title,
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w100)),
            ),
            body: SingleChildScrollView(
              child: Container(
                  child: Column(
                children: <Widget>[
                  Card(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    elevation: 0.5,
                    color: sectionBackgroundColor,
                    child: Container(
                      padding: EdgeInsets.only(top: 12),
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
                                currentColor: props.primaryColor,
                                onSelectColor: props.onSelectAccentColor,
                              ),
                            ),
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'Accent Color',
                            ),
                            trailing: CircleAvatar(
                              radius: 16,
                              backgroundColor: Color(props.accentColor),
                            ),
                          ),
                          ListTile(
                            onTap: () => props.onIncrementTheme(),
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'Theme',
                            ),
                            trailing: Text(
                              displayThemeType(props.themeType),
                            ),
                          ),
                          ListTile(
                            onTap: () {},
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'Font Size',
                            ),
                            trailing: Text(
                              props.fontSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    elevation: 0.5,
                    color: sectionBackgroundColor,
                    child: Container(
                      padding: EdgeInsets.only(top: 12),
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
                            onTap: () {},
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'Chat Title Size',
                            ),
                            trailing: Text(
                              props.chatFontSize,
                            ),
                          ),
                          ListTile(
                            onTap: () {},
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'Message Body Size',
                            ),
                            trailing: Text(
                              props.chatFontSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )),
            ),
          );
        },
      );
}

class Props {
  final int primaryColor;
  final int accentColor;
  final String themeType;
  final String language;
  final String fontSize;
  final String chatFontSize;
  final bool enterSend;

  final Function onSelectPrimaryColor;
  final Function onSelectAccentColor;
  final Function onIncrementTheme;
  final Function onToggleEnterSend;

  Props({
    @required this.primaryColor,
    @required this.accentColor,
    @required this.themeType,
    @required this.language,
    @required this.fontSize,
    @required this.chatFontSize,
    @required this.enterSend,
    @required this.onSelectPrimaryColor,
    @required this.onSelectAccentColor,
    @required this.onIncrementTheme,
    @required this.onToggleEnterSend,
  });

  static Props mapStateToProps(Store<AppState> store) => Props(
        primaryColor:
            store.state.settingsStore.primaryColor ?? Colours.cyanSyphon,
        accentColor:
            store.state.settingsStore.accentColor ?? Colours.cyanSyphon,
        themeType: store.state.settingsStore.theme.toString(),
        language: store.state.settingsStore.language,
        enterSend: store.state.settingsStore.enterSend,
        fontSize: "Normal",
        chatFontSize: "Normal",
        onSelectPrimaryColor: (int color) => store.dispatch(
          // convert to int hex color code
          selectPrimaryColor(color),
        ),
        onSelectAccentColor: (int color) => store.dispatch(
          // convert to int hex color code
          selectAccentColor(color),
        ),
        onIncrementTheme: () => store.dispatch(
          incrementTheme(),
        ),
        onToggleEnterSend: () => store.dispatch(
          toggleEnterSend(),
        ),
      );

  @override
  int get hashCode =>
      primaryColor.hashCode ^
      accentColor.hashCode ^
      language.hashCode ^
      themeType.hashCode ^
      enterSend.hashCode ^
      onSelectPrimaryColor.hashCode ^
      onSelectAccentColor.hashCode ^
      onIncrementTheme.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Props &&
          runtimeType == other.runtimeType &&
          primaryColor == other.primaryColor &&
          accentColor == other.accentColor &&
          language == other.language &&
          themeType == other.themeType &&
          enterSend == other.enterSend &&
          onSelectPrimaryColor == other.onSelectPrimaryColor &&
          onSelectAccentColor == other.onSelectAccentColor &&
          onIncrementTheme == other.onIncrementTheme;
}
