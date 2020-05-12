import 'package:Tether/global/strings.dart';
import 'package:Tether/global/themes.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';

// Store
import 'package:Tether/store/index.dart';
import 'package:Tether/store/settings/actions.dart';
import 'package:Tether/store/auth/actions.dart';

// Styling
import 'package:touchable_opacity/touchable_opacity.dart';
import 'package:Tether/global/dimensions.dart';
import 'package:Tether/global/behaviors.dart';

// Assets
import 'package:Tether/global/assets.dart';

class Login extends StatefulWidget {
  final Store<AppState> store;
  const Login({Key key, this.store}) : super(key: key);

  @override
  LoginState createState() => LoginState();
}

class LoginState extends State<Login> {
  final GlobalKey<ScaffoldState> loginScaffold = GlobalKey<ScaffoldState>();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordFocus = FocusNode();

  LoginState({Key key});

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      onMounted();
    });
  }

  @protected
  void onMounted() {
    final store = StoreProvider.of<AppState>(context);
    // Init alerts listener
    store.state.alertsStore.onAlertsChanged.listen((alert) {
      var color;

      switch (alert.type) {
        case 'warning':
          color = Colors.red;
          break;
        case 'error':
          color = Colors.red;
          break;
        case 'info':
        default:
          color = Colors.grey;
      }

      loginScaffold.currentState.showSnackBar(SnackBar(
        backgroundColor: color,
        content: Text(alert.message),
        duration: alert.duration,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            loginScaffold.currentState.removeCurrentSnackBar();
          },
        ),
      ));
    });
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  void handleSubmitted(String value) {
    FocusScope.of(context).requestFocus(passwordFocus);
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    final double defaultWidgetScaling = width * 0.725;

    return StoreConnector<AppState, _Props>(
      distinct: true,
      converter: (store) => _Props.mapStoreToProps(store),
      builder: (context, props) => Scaffold(
        key: loginScaffold,
        body: ScrollConfiguration(
          behavior: DefaultScrollBehavior(),
          child: SingleChildScrollView(
            // Use a container of the same height and width
            // to flex dynamically but within a single child scroll
            child: Container(
              height: height,
              constraints: BoxConstraints(
                maxHeight: Dimensions.widgetHeightMax,
              ),
              child: Flex(
                direction: Axis.vertical,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Flexible(
                    flex: 4,
                    child: Flex(
                      direction: Axis.vertical,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TouchableOpacity(
                          onTap: () {
                            props.onIncrementTheme();
                          },
                          child: Image(
                            width: width * 0.35,
                            height: width * 0.35,
                            image: AssetImage(TETHER_ICON_PNG),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    flex: 2,
                    child: Flex(
                        direction: Axis.vertical,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FittedBox(
                            fit: BoxFit.fitWidth,
                            child: Text(
                              LOGIN_TITLE,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headline4,
                            ),
                          ),
                        ]),
                  ),
                  Flexible(
                    flex: 3,
                    fit: FlexFit.loose,
                    child: Flex(
                        direction: Axis.vertical,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: defaultWidgetScaling,
                            height: Dimensions.inputHeight,
                            margin: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            constraints: BoxConstraints(
                              minWidth: Dimensions.inputWidthMin,
                              maxWidth: Dimensions.inputWidthMax,
                            ),
                            child: TextField(
                              controller: usernameController,
                              onSubmitted: handleSubmitted,
                              onChanged: (username) {
                                // Trim value for UI
                                usernameController.value = TextEditingValue(
                                  text: username.trim(),
                                  selection: TextSelection.fromPosition(
                                    TextPosition(
                                      offset: username.trim().length,
                                    ),
                                  ),
                                );
                                props.onChangeUsername(username);
                              },
                              decoration: InputDecoration(
                                labelText: 'username',
                                hintText: props.usernameHint,
                                contentPadding: EdgeInsets.only(
                                  left: 20,
                                  top: 32,
                                ),
                                suffixIcon: IconButton(
                                  highlightColor:
                                      Theme.of(context).primaryColor,
                                  icon: Icon(Icons.help_outline),
                                  tooltip: SELECT_USERNAME_TITLE,
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/search_home',
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: defaultWidgetScaling,
                            height: Dimensions.inputHeight,
                            margin: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            constraints: BoxConstraints(
                              minWidth: Dimensions.inputWidthMin,
                              maxWidth: Dimensions.inputWidthMax,
                            ),
                            child: TextField(
                              focusNode: passwordFocus,
                              onChanged: (password) {
                                props.onChangePassword(password);
                              },
                              obscureText: true,
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.only(
                                  left: 20,
                                  top: 32,
                                  bottom: 32,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                labelText: 'password',
                              ),
                            ),
                          ),
                        ]),
                  ),
                  Container(
                    width: defaultWidgetScaling,
                    height: Dimensions.inputHeight,
                    margin: const EdgeInsets.only(
                      top: 24,
                    ),
                    constraints: BoxConstraints(
                      minWidth: 256,
                      maxWidth: 336,
                    ),
                    child: FlatButton(
                      disabledColor: Colors.grey,
                      disabledTextColor: Colors.grey[300],
                      onPressed: props.isLoginAttemptable
                          ? () {
                              props.onLoginUser();
                            }
                          : null,
                      color: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28.0),
                      ),
                      child: props.loading
                          ? Container(
                              constraints: BoxConstraints(
                                maxHeight: 28,
                                maxWidth: 28,
                              ),
                              child: CircularProgressIndicator(
                                strokeWidth: Dimensions.defaultStrokeWidth,
                                backgroundColor: Colors.white,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.grey,
                                ),
                              ),
                            )
                          : Text(
                              LOGIN_BUTTON_TEXT,
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  Container(
                    height: Dimensions.inputHeight,
                    constraints: BoxConstraints(
                      minHeight: Dimensions.inputHeight,
                    ),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 16,
                    ),
                    child: TouchableOpacity(
                      activeOpacity: 0.4,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/signup',
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            CREATE_USER_TEXT,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w100,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              CREATE_USER_TEXT_ACTION,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w100,
                                color: Themes.invertedPrimaryColor(context),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Props extends Equatable {
  final bool loading;
  final String username;
  final String password;
  final bool isLoginAttemptable;
  final String usernameHint;

  final Function onIncrementTheme;
  final Function onChangeUsername;
  final Function onChangePassword;
  final Function onLoginUser;

  _Props({
    @required this.loading,
    @required this.username,
    @required this.password,
    @required this.isLoginAttemptable,
    @required this.usernameHint,
    @required this.onIncrementTheme,
    @required this.onChangeUsername,
    @required this.onChangePassword,
    @required this.onLoginUser,
  });

  static _Props mapStoreToProps(Store<AppState> store) => _Props(
      loading: store.state.authStore.loading,
      username: store.state.authStore.username,
      password: store.state.authStore.password,
      isLoginAttemptable: store.state.authStore.isPasswordValid &&
          store.state.authStore.isUsernameValid &&
          !store.state.authStore.loading,
      usernameHint: formatUsernameHint(
        store.state.authStore.homeserver,
      ),
      onChangeUsername: (String text) {
        // If user enters full username, make sure to set homeserver
        if (text.contains(':')) {
          final alias = text.trim().split(':');
          print('${alias[0]}(:)${alias[1]}');
          store.dispatch(setUsername(
            username: alias[0],
          ));
          store.dispatch(setHomeserver(
            homeserver: alias[1],
          ));
        } else {
          store.dispatch(setUsername(
            username: text.trim(),
          ));
          store.dispatch(setHomeserver(
            homeserver: 'matrix.org',
          ));
        }
      },
      onChangePassword: (String text) {
        store.dispatch(setPassword(password: text));
      },
      onIncrementTheme: () {
        store.dispatch(incrementTheme());
      },
      onLoginUser: () async {
        await store.dispatch(loginUser());
      });

  @override
  List<Object> get props => [
        loading,
        username,
        password,
        isLoginAttemptable,
        usernameHint,
      ];
}
