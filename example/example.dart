import 'package:xdg_status_notifier_item/xdg_status_notifier_item.dart';

void main() async {
  var client = StatusNotifierItemClient();
  await client.addItem(
      id: 'dart-test',
      title: 'Test',
      menu: DBusMenuItem(children: [
        DBusMenuItem(label: 'Start', enabled: false),
        DBusMenuItem(label: 'Open Shell'),
        DBusMenuItem(label: 'Stop', enabled: false),
        DBusMenuItem.separator(),
        DBusMenuItem(label: 'snapcraft-ubuntu-desktop-session', children: [
          DBusMenuItem(label: 'Start'),
          DBusMenuItem(label: 'Open Shell'),
          DBusMenuItem(label: 'Stop', enabled: false)
        ]),
        DBusMenuItem(label: 'About', children: [
          DBusMenuItem.checkmark('Autostart on login', state: true),
          DBusMenuItem(label: 'multipass version: 1.11.0', enabled: false),
          DBusMenuItem(label: 'multipassd version: 1.11.0', enabled: false),
          DBusMenuItem(
              label: 'Copyright © 2017-2022 Canonical Ltd.', enabled: false)
        ]),
        DBusMenuItem(label: 'Quit')
      ]));
  //await client.close();
}
