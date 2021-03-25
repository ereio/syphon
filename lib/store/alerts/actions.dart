// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:easy_localization/easy_localization.dart' as tr;

// Package imports:
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/global/print.dart';

// Project imports:
import 'package:syphon/store/index.dart';
import './model.dart';

class SetLoading {
  final bool loading;
  SetLoading({this.loading});
}

class SetAlertsObserver {
  final StreamController<Alert> alertsObserver;
  SetAlertsObserver({this.alertsObserver});
}

class AddAlert {
  final Alert alert;
  AddAlert({this.alert});
}

class AddSuccess {
  final Alert alert;
  AddSuccess({this.alert});
}

class RemoveAlert {
  final Alert alert;
  RemoveAlert({this.alert});
}

ThunkAction<AppState> startAlertsObserver() {
  return (Store<AppState> store) async {
    if (store.state.alertsStore.alertsObserver != null) {
      throw 'Cannot call startAlertsObserver with an existing instance';
    }

    store.dispatch(
      SetAlertsObserver(alertsObserver: StreamController<Alert>.broadcast()),
    );
  };
}

ThunkAction<AppState> addInProgress() {
  return (Store<AppState> store) async {
    store.dispatch(addInfo(message: tr.tr('alert-feature-in-progress')));
  };
}

ThunkAction<AppState> addInfo({
  type = 'info',
  origin = 'Unknown',
  message,
  error,
}) {
  return (Store<AppState> store) async {
    printInfo(error.toString(), tag: origin);

    final alertsObserver = store.state.alertsStore.alertsObserver;
    final alert = Alert(type: type, message: message, error: error);
    store.dispatch(AddAlert(alert: alert));
    alertsObserver.add(alert);
  };
}

ThunkAction<AppState> addConfirmation({
  String type = 'success',
  String origin = 'Unknown',
  String message,
  error,
}) {
  return (Store<AppState> store) async {
    printInfo(error.toString(), tag: origin);

    final alertsObserver = store.state.alertsStore.alertsObserver;
    final alert = Alert(type: type, message: message, error: error.toString());
    store.dispatch(AddAlert(alert: alert));
    alertsObserver.add(alert);
  };
}

ThunkAction<AppState> addAlert({
  type = 'warning',
  origin = 'Unknown',
  message,
  error,
}) {
  return (Store<AppState> store) async {
    printWarning(error.toString(), tag: origin);

    final alertsObserver = store.state.alertsStore.alertsObserver;
    final alert = Alert(type: type, message: message, error: error.toString());
    store.dispatch(AddAlert(alert: alert));
    alertsObserver.add(alert);
  };
}

ThunkAction<AppState> stopAlertsObserver() {
  return (Store<AppState> store) async {
    store.state.alertsStore.alertsObserver.close();
  };
}
