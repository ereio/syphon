import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/svg.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/auth/actions.dart';

// Store
import 'package:syphon/store/index.dart';
import 'package:syphon/views/widgets/buttons/button-solid.dart';
import 'package:syphon/views/widgets/buttons/button-text.dart';
import 'package:syphon/views/widgets/dialogs/dialog-explaination.dart';

// Styling
import 'package:syphon/global/behaviors.dart';

// Assets
import 'package:syphon/global/assets.dart';

class VerificationView extends StatefulWidget {
  const VerificationView({Key key}) : super(key: key);

  VerificationViewState createState() => VerificationViewState();
}

class VerificationViewState extends State<VerificationView>
    with WidgetsBindingObserver {
  bool sending;
  bool success;

  int sendAttempt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    this.setState(() {
      sending = false;
      sendAttempt = 1;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final store = StoreProvider.of<AppState>(context);
    final props = _Props.mapStateToProps(store);

    switch (state) {
      case AppLifecycleState.resumed:
        if (success == null || !success) {
          final result = await props.onCreateUser(enableErrors: true);
          this.setState(() {
            success = result;
          });
        }
        break;
      case AppLifecycleState.inactive:
        debugPrint("app in inactive");
        break;
      case AppLifecycleState.paused:
        debugPrint("app in paused");
        break;
      case AppLifecycleState.detached:
        debugPrint("app in detached");
        break;
    }
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStateToProps(store),
        builder: (context, props) {
          double width = MediaQuery.of(context).size.width;
          double height = MediaQuery.of(context).size.height;

          return Scaffold(
            body: ScrollConfiguration(
              behavior: DefaultScrollBehavior(),
              child: SingleChildScrollView(
                child: Container(
                  height: height,
                  width: width,
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      vertical: height * 0.01,
                    ),
                    child: Flex(
                      direction: Axis.vertical,
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Flexible(
                          flex: 2,
                          child: Container(
                            width: Dimensions.contentWidth(context),
                            constraints: BoxConstraints(
                              maxHeight: Dimensions.mediaSizeMax,
                              maxWidth: Dimensions.mediaSizeMax,
                            ),
                            child: SvgPicture.asset(
                              Assets.heroSignupVerificationView,
                              semanticsLabel:
                                  'Letter in envelop floating upward with attached balloons',
                            ),
                          ),
                        ),
                        Flexible(
                          child: Flex(
                            direction: Axis.vertical,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                padding: EdgeInsets.only(bottom: 8, top: 8),
                                child: Text(
                                  'Check your email and click the verification\nlink to finish account creation.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.caption,
                                ),
                              ),
                              Container(
                                child: Stack(
                                  overflow: Overflow.visible,
                                  children: <Widget>[
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 24,
                                      ),
                                      child: Text(
                                        'Verify your email address',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline5,
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) =>
                                                DialogExplaination(
                                              title: Strings
                                                  .titleDialogEmailVerifiedRequirement,
                                              content: Strings
                                                  .contentEmailRequirement,
                                              onConfirm: () {
                                                Navigator.pop(context);
                                              },
                                            ),
                                          );
                                        },
                                        child: Container(
                                          height: 20,
                                          width: 20,
                                          child: Icon(
                                            Icons.info_outline,
                                            color:
                                                Theme.of(context).accentColor,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: Flex(
                            mainAxisAlignment: MainAxisAlignment.center,
                            direction: Axis.vertical,
                            children: <Widget>[
                              Container(
                                width: Dimensions.contentWidth(context),
                                margin: EdgeInsets.only(top: height * 0.01),
                                height: Dimensions.inputHeight,
                                constraints: BoxConstraints(
                                  minWidth: Dimensions.buttonWidthMin,
                                  maxWidth: Dimensions.buttonWidthMax,
                                ),
                                child: ButtonSolid(
                                  text: 'resend email',
                                  loading: this.sending || props.loading,
                                  disabled: this.sending || props.loading,
                                  onPressed: () {
                                    print('sending ${this.sendAttempt}');
                                    props.onResendVerification(
                                      sendAttempt: this.sendAttempt + 1,
                                    );
                                    this.setState(() {
                                      sendAttempt = this.sendAttempt + 1;
                                    });
                                  },
                                ),
                              ),
                              Container(
                                width: Dimensions.contentWidth(context),
                                margin: EdgeInsets.only(top: height * 0.01),
                                height: Dimensions.inputHeight,
                                constraints: BoxConstraints(
                                  minWidth: Dimensions.buttonWidthMin,
                                  maxWidth: Dimensions.buttonWidthMax,
                                ),
                                child: ButtonText(
                                  text: 'check verification',
                                  disabled: this.sending || props.loading,
                                  onPressed: () async {
                                    final result = await props.onCreateUser(
                                        enableErrors: true);
                                    this.setState(() {
                                      success = result;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
}

class _Props extends Equatable {
  final bool loading;
  final bool verification;

  final Function onCreateUser;
  final Function onResendVerification;

  _Props({
    @required this.loading,
    @required this.verification,
    @required this.onCreateUser,
    @required this.onResendVerification,
  });

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        loading: store.state.authStore.loading,
        verification: store.state.authStore.verificationNeeded,
        onResendVerification: ({int sendAttempt}) async {
          return await store.dispatch(submitEmail(sendAttempt: sendAttempt));
        },
        onCreateUser: ({bool enableErrors = false}) async {
          return await store.dispatch(createUser(enableErrors: enableErrors));
        },
      );

  @override
  List<Object> get props => [
        loading,
        verification,
      ];
}
