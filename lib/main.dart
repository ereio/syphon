import 'dart:io';
import 'package:Tether/global/strings.dart';
import 'package:Tether/store/alerts/actions.dart';
import 'package:Tether/store/service.dart';
import 'package:Tether/store/settings/state.dart';
import 'package:Tether/store/auth/actions.dart';
import 'package:Tether/global/notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_redux/flutter_redux.dart';

// Library Implimentations
import 'package:Tether/global/libs/hive/index.dart';

// Redux - State Managment - "store" - IMPORT ONLY ONCE
import 'package:Tether/store/index.dart';

// Navigation
import 'package:Tether/views/navigation.dart';
import 'package:Tether/views/intro/index.dart';
import 'package:Tether/views/home/index.dart';

// Styling
import 'package:Tether/global/themes.dart';
import 'package:redux/redux.dart';

/**
 * DESKTOP ONLY
import 'package:window_utils/window_utils.dart';
 */

// Generated Json Serializables
// import 'main.reflectable.dart'; // Import generated code.

void _enablePlatformOverrideForDesktop() {
  if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }
}

void main() async {
  // initializeReflectable();
  WidgetsFlutterBinding();
  await DotEnv().load(kReleaseMode ? '.env.release' : '.env.debug');
  _enablePlatformOverrideForDesktop();

  // init cold cache (mobile only)
  if (Platform.isIOS || Platform.isAndroid) {
    Cache.hive = await initHiveStorageUnsafe();
  }

  // init state cache (hot)
  final store = await initStore();

  if (Platform.isAndroid) {
    final backgroundSyncStatus = await BackgroundSync.init();
    print('[main] background service started $backgroundSyncStatus');
  }

  // /**
  //  * DESKTOP ONLY
  // if (Platform.isMacOS) {
  //   print(await WindowUtils.getWindowSize());
  //   await WindowUtils.setSize(Size(720, 720));
  // }
  //  */

  // the main thing
  runApp(Tether(store: store));
}

class Tether extends StatefulWidget {
  final Store<AppState> store;
  const Tether({Key key, this.store}) : super(key: key);

  @override
  TetherState createState() => TetherState(store: store);
}

class TetherState extends State<Tether> with WidgetsBindingObserver {
  final Store<AppState> store;
  Widget defaultHome = Home();
  TetherState({this.store});

  Future onSelectNotification(String payload) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Testing Notifications'),
        content: Text('Payload : $payload'),
      ),
    );
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();

    store.dispatch(startAuthObserver());
    store.dispatch(startAlertsObserver());

    final currentUser = store.state.authStore.user;
    final authed = currentUser.accessToken != null;

    if (!authed) {
      defaultHome = Intro();
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      onMounted();
    });
  }

  // INFO: Used to check when the app is backgrounded
  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   print('state = $state');
  // }

  @override
  void deactivate() {
    closeStorage();
    WidgetsBinding.instance.removeObserver(this);
    store.dispatch(stopAuthObserver());
    store.dispatch(stopAlertsObserver());
    super.deactivate();
  }

  @protected
  void onMounted() {
    // init authenticated navigation
    store.state.authStore.onAuthStateChanged.listen((user) {
      if (user == null && defaultHome.runtimeType == Home) {
        defaultHome = Intro();
        NavigationService.clearTo('/intro', context);
      } else if (user != null &&
          user.accessToken != null &&
          defaultHome.runtimeType == Intro) {
        // Default Authenticated App Home
        defaultHome = Home();
        NavigationService.clearTo('/home', context);
      }
    });
  }

  // Store should not need to be passed to a widget to affect
  // lifecycle widget functions
  @override
  Widget build(BuildContext context) => StoreProvider<AppState>(
        store: store,
        child: StoreConnector<AppState, SettingsStore>(
          distinct: true,
          converter: (store) => store.state.settingsStore,
          builder: (context, settings) => MaterialApp(
            theme: Themes.generateCustomTheme(
              themeType: settings.theme,
              primaryColorHex: settings.primaryColor,
              accentColorHex: settings.accentColor,
            ),
            navigatorKey: NavigationService.navigatorKey,
            routes: NavigationProvider.getRoutes(store),
            home: defaultHome,
          ),
        ),
      );
}
