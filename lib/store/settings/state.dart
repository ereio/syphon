import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:syphon/store/settings/theme-settings/model.dart';
import 'package:syphon/store/settings/chat-settings/sort-order/model.dart';
import 'package:syphon/store/settings/devices-settings/model.dart';
import 'package:syphon/store/settings/notification-settings/model.dart';
import './chat-settings/model.dart';

part 'state.g.dart';

@JsonSerializable()
class SettingsStore extends Equatable {
  @JsonKey(ignore: true)
  final bool loading;

  final bool smsEnabled;
  final bool enterSendEnabled;
  final bool readReceiptsEnabled;
  final bool typingIndicatorsEnabled;
  final bool membershipEventsEnabled;
  final bool roomTypeBadgesEnabled;
  final bool timeFormat24Enabled;
  final bool dismissKeyboardEnabled;

  final String language;

  final int syncInterval;
  final int syncPollTimeout;

  final String sortOrder;
  final List<String> sortGroups;

  final List<Device> devices;
  final Map<String, ChatSetting> chatSettings; // roomId
  final NotificationSettings notificationSettings;

  final ThemeSettings themeSettings;

  final String? alphaAgreement; // a timestamp of agreement for alpha TOS

  @JsonKey(ignore: true)
  final String? pusherToken; // NOTE: can be device token for APNS

  const SettingsStore({
    this.language = 'English',
    this.syncInterval = 2000, // millis
    this.syncPollTimeout = 10000, // millis
    this.sortGroups = const [SortOptions.PINNED],
    this.sortOrder = SortOrder.LATEST,
    this.enterSendEnabled = false,
    this.smsEnabled = false,
    this.readReceiptsEnabled = false,
    this.typingIndicatorsEnabled = false,
    this.membershipEventsEnabled = true,
    this.roomTypeBadgesEnabled = true,
    this.timeFormat24Enabled = false,
    this.dismissKeyboardEnabled = false,
    this.chatSettings = const <String, ChatSetting>{},
    this.devices = const [],
    this.loading = false,
    this.notificationSettings = const NotificationSettings(),
    this.themeSettings = const ThemeSettings(),
    this.alphaAgreement,
    this.pusherToken,
  });

  @override
  List<Object?> get props => [
        language,
        smsEnabled,
        enterSendEnabled,
        readReceiptsEnabled,
        typingIndicatorsEnabled,
        roomTypeBadgesEnabled,
        timeFormat24Enabled,
        dismissKeyboardEnabled,
        chatSettings,
        devices,
        loading,
        notificationSettings,
        themeSettings,
        alphaAgreement,
        pusherToken,
      ];

  SettingsStore copyWith({
    String? language,
    bool? smsEnabled,
    bool? enterSendEnabled,
    bool? readReceiptsEnabled,
    bool? typingIndicatorsEnabled,
    bool? membershipEventsEnabled,
    bool? roomTypeBadgesEnabled,
    bool? timeFormat24Enabled,
    bool? dismissKeyboardEnabled,
    int? syncInterval,
    int? syncPollTimeout,
    Map<String, ChatSetting>? chatSettings,
    NotificationSettings? notificationSettings,
    ThemeSettings? themeSettings,
    List<Device>? devices,
    bool? loading,
    String? alphaAgreement,
    String? pusherToken, // NOTE: device token for APNS
  }) =>
      SettingsStore(
        language: language ?? this.language,
        smsEnabled: smsEnabled ?? this.smsEnabled,
        enterSendEnabled: enterSendEnabled ?? this.enterSendEnabled,
        readReceiptsEnabled: readReceiptsEnabled ?? this.readReceiptsEnabled,
        typingIndicatorsEnabled:
            typingIndicatorsEnabled ?? this.typingIndicatorsEnabled,
        timeFormat24Enabled: timeFormat24Enabled ?? this.timeFormat24Enabled,
        dismissKeyboardEnabled:
            dismissKeyboardEnabled ?? this.dismissKeyboardEnabled,
        membershipEventsEnabled:
            membershipEventsEnabled ?? this.membershipEventsEnabled,
        roomTypeBadgesEnabled:
            roomTypeBadgesEnabled ?? this.roomTypeBadgesEnabled,
        syncInterval: syncInterval ?? this.syncInterval,
        syncPollTimeout: syncPollTimeout ?? this.syncPollTimeout,
        chatSettings: chatSettings ?? this.chatSettings,
        notificationSettings: notificationSettings ?? this.notificationSettings,
        themeSettings: themeSettings ?? this.themeSettings,
        devices: devices ?? this.devices,
        loading: loading ?? this.loading,
        alphaAgreement: alphaAgreement ?? this.alphaAgreement,
        pusherToken: pusherToken ?? this.pusherToken,
      );

  Map<String, dynamic> toJson() => _$SettingsStoreToJson(this);

  factory SettingsStore.fromJson(Map<String, dynamic> json) =>
      _$SettingsStoreFromJson(json);
}
