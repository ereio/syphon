// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Project imports:
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/views/home/chat/details-all-users.dart';
import 'package:syphon/views/home/groups/invite-users.dart';
import 'package:syphon/views/widgets/avatars/avatar-circle.dart';
import 'package:syphon/views/widgets/modals/modal-user-details.dart';

/**
 * List of Users (Avi Bubbles)
 * 
 * Still uses userId because users
 * are still indexed by room
 */
class ListUserBubbles extends StatelessWidget {
  ListUserBubbles({
    Key key,
    this.users = const [],
    this.roomId = '',
    this.invite = false,
    this.forceOption = false,
  }) : super(key: key);

  final bool invite;
  final bool forceOption;
  final String roomId;
  final List<User> users;

  @protected
  onShowUserDetails({
    BuildContext context,
    User user,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ModalUserDetails(
        user: user,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListView(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        children: [
          ListView.builder(
            shrinkWrap: true,
            itemCount: users.length < 12 ? users.length : 12,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (BuildContext context, int index) {
              final user = users[index];

              return Align(
                child: GestureDetector(
                  onTap: () {
                    onShowUserDetails(
                      context: context,
                      user: user,
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 12 : 4,
                      right: index == users.length ? 12 : 4,
                    ),
                    child: AvatarCircle(
                      uri: user.avatarUri,
                      alt: user.displayName ?? user.userId,
                      size: Dimensions.avatarSize,
                      background: Colours.hashedColor(user.userId),
                    ),
                  ),
                ),
              );
            },
          ),
          Visibility(
            visible: users.length > 12 || forceOption,
            child: Container(
              margin: EdgeInsets.only(left: 4, right: 12),
              padding: EdgeInsets.symmetric(vertical: 14),
              child: ClipOval(
                child: Material(
                  color:
                      Theme.of(context).scaffoldBackgroundColor, // button color
                  child: InkWell(
                    onTap: () {
                      if (invite) {
                        Navigator.pushNamed(
                          context,
                          '/home/user/invite',
                          arguments: InviteUsersArguments(roomId: roomId),
                        );
                      } else {
                        Navigator.pushNamed(
                          context,
                          '/home/chat/users',
                          arguments: ChatUsersDetailArguments(roomId: roomId),
                        );
                      }
                    },
                    splashColor: Colors.grey, // inkwell color
                    child: SizedBox(
                      width: Dimensions.avatarSize,
                      height: Dimensions.avatarSize,
                      child: Container(
                        width: Dimensions.avatarSize,
                        height: Dimensions.avatarSize,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(
                            Radius.circular(Dimensions.avatarSize),
                          ),
                          border: Border.all(
                            width: 1,
                            color: Theme.of(context).textTheme.caption.color,
                          ),
                        ),
                        child: Icon(
                          invite ? Icons.edit : Icons.arrow_forward_ios,
                          size: invite
                              ? Dimensions.iconSize
                              : Dimensions.iconSizeLarge,
                          color: Theme.of(context).textTheme.caption.color,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}
