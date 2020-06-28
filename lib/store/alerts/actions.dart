import 'dart:async';

import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

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

ThunkAction<AppState> addAlert({type, message, origin = 'Unknown'}) {
  return (Store<AppState> store) async {
    debugPrint('[$origin] $type : $message');

    final alertsObserver = store.state.alertsStore.alertsObserver;
    final alert = new Alert(type: type, message: message);
    store.dispatch(AddAlert(alert: alert));
    alertsObserver.add(alert);
  };
}

ThunkAction<AppState> stopAlertsObserver() {
  return (Store<AppState> store) async {
    store.state.alertsStore.alertsObserver.close();
  };
}
