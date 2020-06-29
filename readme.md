# syphon

A privacy centric matrix client



## why
We need to decentralize the web, but also provide a means of freedom within that system. 

Matrix has the potential, and in several ways already is, a peer-to-peer chat protcol that will allow people to communicate but move or transfer their data at will. Most popular proprietary chat clients do not adhere to a publically available protocol. If the goal for this protocol is adoption to instant messaging communication the way of email, and a network effect is required for this paradigm shift, 

then **branding and user experience** should be the number one priority outside the implicit one of privacy and security. 

Syphon aims to be built on these foundations of privacy, branding, and user experience in an effort to pull others away from proprietary chat and messenger clients.

An additional aim for syphon - outside the app concept itself - was to build a usable open-source cross-platform app that followed paradigms most developers, and thus web developers, could understand without needing to know device platform specific code. In order to maintance the freedom of a system, the systems focus should be attempting to include as many perspectives as possible. The more popular a development platform is, the more likely it is for people to contribute or improve the tool without a learning curve due to platform or language specific knowledge. Thus, you may notice Syphon does not look very dart-y (for example, no \_private variable declarations, or using redux instead of provider) in an effort to reduce the learning curve from other languages or platforms. The faster we can get people to contributing, the easier it will be to create and maintain tools to piviot others from products that can or do exploit the user.

## getting started

### state management
- [Redux Tutorial](https://www.netguru.com/codestories/-implement-redux-with-flutter-app)
- [Redux Examples](https://github.com/brianegan/flutter_architecture_samples/blob/master/firestore_redux/)

### storage
There are three layers to storage in Syphon:
- State (Redux + Redux Persist +  Hive)
    * state cache is encrypted at rest
- Cold Storage (Hive)

### native notifications (android only)
- utitlizes [android_alarm_manager](https://pub.dev/packages?q=background_alarm_manager) on Android to run the matrix /sync requests in a bound ground thread and display notifications with [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
- no third party notification provider will ever be used

### assets
- [paid icon](https://thenounproject.com/search/?q=polygon&i=2596282)
- [iOS icons](https://github.com/smallmuou/ios-icon-generator)

### helpful references
- [iOS file management flutter](https://stackoverflow.com/questions/55220612/how-to-save-a-text-file-in-external-storage-in-ios-using-flutter)
- [scrolling With Text Inputs](https://github.com/flutter/flutter/issues/13339)
- [multi-line text field](https://stackoverflow.com/questions/45900387/multi-line-textfield-in-flutter)
- [keyboard dismissal](https://stackoverflow.com/questions/55863766/how-to-prevent-keyboard-from-dismissing-on-pressing-submit-key-in-flutter)
- [changing transition styles](https://stackoverflow.com/questions/50196913/how-to-change-navigation-animation-using-flutter)


## from those who made it possible
lub youu
