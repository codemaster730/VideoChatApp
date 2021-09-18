import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:instachatty/constants.dart';
import 'package:instachatty/main.dart';
import 'package:instachatty/model/User.dart';
import 'package:instachatty/services/FirebaseHelper.dart';
import 'package:instachatty/services/helper.dart';

class SettingsScreen extends StatefulWidget {
  final User user;

  const SettingsScreen({Key? key, required this.user}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late User user;

  @override
  void initState() {
    user = widget.user;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(COLOR_PRIMARY),
        iconTheme: IconThemeData(
            color: isDarkMode(context) ? Colors.grey.shade200 : Colors.white),
        title: Text(
          'settings',
          style: TextStyle(
              color: isDarkMode(context) ? Colors.grey.shade200 : Colors.white,
              fontWeight: FontWeight.bold),
        ).tr(),
        centerTitle: true,
      ),
      body: Builder(
        builder: (buildContext) => Column(
          children: <Widget>[
            Material(
              elevation: 2,
              color: isDarkMode(context) ? Colors.black54 : Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding:
                        const EdgeInsets.only(right: 16.0, left: 16, top: 16),
                    child: Text(
                      'general',
                      style: TextStyle(
                          color: isDarkMode(context)
                              ? Colors.white54
                              : Colors.black54,
                          fontSize: 18),
                    ).tr(),
                  ),
                  SwitchListTile.adaptive(
                      activeColor: Color(COLOR_ACCENT),
                      title: Text(
                        'allowPushNotifications',
                        style: TextStyle(
                            fontSize: 17,
                            color: isDarkMode(context)
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.bold),
                      ).tr(),
                      value: user.settings.allowPushNotifications,
                      onChanged: (bool newValue) {
                        user.settings.allowPushNotifications = newValue;
                        setState(() {});
                      }),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 32.0, bottom: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: double.infinity),
                child: Material(
                  elevation: 2,
                  color: isDarkMode(context) ? Colors.black54 : Colors.white,
                  child: CupertinoButton(
                    padding: const EdgeInsets.all(12.0),
                    onPressed: () async {
                      showProgress(context, 'savingChanges'.tr(), true);
                      User? updateUser =
                          await FireStoreUtils.updateCurrentUser(user);
                      hideProgress();
                      if (updateUser != null) {
                        this.user = updateUser;
                        MyAppState.currentUser = user;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            duration: Duration(seconds: 1),
                            content: Text(
                              'settingsSavedSuccessfully',
                              style: TextStyle(fontSize: 17),
                            ).tr()));
                      }
                    },
                    child: Text(
                      'save',
                      style:
                          TextStyle(fontSize: 18, color: Color(COLOR_PRIMARY)),
                    ).tr(),
                    color: isDarkMode(context) ? Colors.black54 : Colors.white,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
