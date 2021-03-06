import 'package:flutter/material.dart';

import 'package:syphon/global/values.dart';
import 'package:syphon/views/home/chat/chat-detail-all-users-screen.dart';
import 'package:syphon/views/home/chat/chat-detail-screen.dart';
import 'package:syphon/views/home/chat/chat-detail-message-screen.dart';
import 'package:syphon/views/home/chat/chat-screen.dart';
import 'package:syphon/views/home/groups/group-create-public-screen.dart';
import 'package:syphon/views/home/groups/group-create-screen.dart';
import 'package:syphon/views/home/groups/invite-users-screen.dart';
import 'package:syphon/views/home/home-screen.dart';
import 'package:syphon/views/home/profile/profile-user-screen.dart';
import 'package:syphon/views/home/profile/profile-screen.dart';
import 'package:syphon/views/home/search/search-groups-screen.dart';
import 'package:syphon/views/home/search/search-rooms-screen.dart';
import 'package:syphon/views/home/search/search-users-screen.dart';
import 'package:syphon/views/home/settings/advanced-settings-screen.dart';
import 'package:syphon/views/home/settings/blocked-screen.dart';
import 'package:syphon/views/home/settings/settings-chats-screen.dart';
import 'package:syphon/views/home/settings/settings-devices-screen.dart';
import 'package:syphon/views/home/settings/settings-screen.dart';
import 'package:syphon/views/home/settings/settings-notifications-screen.dart';
import 'package:syphon/views/home/settings/password/password-update-screen.dart';
import 'package:syphon/views/home/settings/settings-privacy-screen.dart';
import 'package:syphon/views/home/settings/settings-storage-screen.dart';
import 'package:syphon/views/home/settings/settings-theming-screen.dart';
import 'package:syphon/views/intro/login/forgot/password-forgot-screen.dart';
import 'package:syphon/views/intro/login/forgot/password-reset-screen.dart';
import 'package:syphon/views/intro/search/search-homeserver-screen.dart';
import 'package:syphon/views/intro/intro-screen.dart';
import 'package:syphon/views/intro/login/login-screen.dart';
import 'package:syphon/views/intro/signup/signup-screen.dart';
import 'package:syphon/views/intro/signup/loading-screen.dart';
import 'package:syphon/views/intro/signup/verification-screen.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<dynamic> navigateTo(String routeName) {
    return navigatorKey.currentState!.pushNamed(routeName);
  }

  static Future<dynamic> clearTo(String routeName, BuildContext context) {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil(routeName, (_) => false);
  }
}

class NavigationPaths {
  static const intro = '/intro';
  static const theming = '/theming';
}

class NavigationProvider {
  static Map<String, Widget Function(BuildContext)> getRoutes() => <String, WidgetBuilder>{
        NavigationPaths.intro: (BuildContext context) => const IntroScreen(),
        '/login': (BuildContext context) => const LoginScreen(),
        '/signup': (BuildContext context) => const SignupScreen(),
        '/forgot': (BuildContext context) => ForgotPasswordScreen(),
        '/reset': (BuildContext context) => ResetPasswordScreen(),
        '/search/homeservers': (BuildContext context) => SearchHomeserverScreen(),
        '/verification': (BuildContext context) => VerificationScreen(),
        '/home': (BuildContext context) => HomeScreen(),
        '/home/chat': (BuildContext context) => ChatScreen(),
        '/home/chat/settings': (BuildContext context) => ChatDetailsScreen(),
        '/home/chat/details': (BuildContext context) => MessageDetailsScreen(),
        '/home/chat/users': (BuildContext context) => ChatUsersDetailScreen(),
        '/home/user/search': (BuildContext context) => SearchUserScreen(),
        '/home/user/details': (BuildContext context) => UserProfileScreen(),
        '/home/user/invite': (BuildContext context) => InviteUsersScreen(),
        '/home/rooms/search': (BuildContext context) => RoomSearchScreen(),
        '/home/groups/search': (BuildContext context) => GroupSearchScreen(),
        '/home/groups/create': (BuildContext context) => CreateGroupScreen(),
        '/home/groups/create/public': (BuildContext context) => CreatePublicGroupScreen(),
        '/profile': (BuildContext context) => ProfileScreen(),
        '/notifications': (BuildContext context) => NotificationSettingsScreen(),
        '/advanced': (BuildContext context) => AdvancedSettingsScreen(),
        '/storage': (BuildContext context) => StorageSettingsScreen(),
        '/password': (BuildContext context) => PasswordUpdateView(),
        '/licenses': (BuildContext context) => LicensePage(applicationName: Values.appName),
        '/privacy': (BuildContext context) => PrivacySettingsScreen(),
        '/chat-preferences': (BuildContext context) => ChatsSettingsScreen(),
        NavigationPaths.theming: (BuildContext context) => ThemingSettingsScreen(),
        '/devices': (BuildContext context) => DevicesScreen(),
        '/settings': (BuildContext context) => SettingsScreen(),
        '/blocked': (BuildContext context) => BlockedScreen(),
        '/loading': (BuildContext context) => LoadingScreen(),
      };
}
