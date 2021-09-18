import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:instachatty/constants.dart';
import 'package:instachatty/services/helper.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          String url = 'tel:12345678';
          launch(url);
        },
        backgroundColor: Color(COLOR_ACCENT),
        child: Icon(
          Icons.call,
          color: isDarkMode(context) ? Colors.black : Colors.white,
        ),
      ),
      appBar: AppBar(
        backgroundColor: Color(COLOR_PRIMARY),
        iconTheme: IconThemeData(
            color: isDarkMode(context) ? Colors.grey.shade200 : Colors.white),
        title: Text(
          'contactUs',
          style: TextStyle(
              color: isDarkMode(context) ? Colors.grey.shade200 : Colors.white,
              fontWeight: FontWeight.bold),
        ).tr(),
        centerTitle: true,
      ),
      body: Column(children: <Widget>[
        Material(
            elevation: 2,
            color: isDarkMode(context)
                ? Colors.black54 : Colors.white,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding:
                    const EdgeInsets.only(right: 16.0, left: 16, top: 16),
                    child: Text(
                      'ourAddress',
                      style: TextStyle(
                          color: isDarkMode(context)
                              ? Colors.white : Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ).tr(),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        right: 16.0, left: 16, top: 16, bottom: 16),
                    child:
                    Text('placeholderAddress')
                        .tr(),
                  ),
                  ListTile(
                    onTap: () async {
                      var url =
                          'mailto:office@idating.com?subject=Instamobile contact ticket';
                      if (await canLaunch(url)) {
                        await launch(url);
                      } else {
                        showAlertDialog(context, 'CouldNotEmail'.tr(),
                            'noMailingAppFound'.tr());
                      }
                    },
                    title: Text(
                      'emailUs',
                      style: TextStyle(
                          color: isDarkMode(context)
                              ? Colors.white : Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ).tr(),
                    subtitle: Text('office@idating.com'),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: isDarkMode(context)
                          ? Colors.white54 : Colors.black54,
                    ),
                  )
                ]))
      ]),
    );
  }
}
