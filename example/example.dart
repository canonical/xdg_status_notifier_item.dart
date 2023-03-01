import 'package:xdg_status_notifier_item/xdg_status_notifier_item.dart';

void main() async {
  var client = StatusNotifierItemClient();
  await client.addItem(
      id: 'dart-test',
      iconName: 'computer-fail-symbolic',
      menu: DBusMenuItem(children: [
        DBusMenuItem(
            label: 'Item', onClicked: () async => print('Item clicked!')),
        DBusMenuItem(label: 'Disabled Item', enabled: false),
        DBusMenuItem(label: 'Invisible Item', visible: false),
        DBusMenuItem.separator(),
        DBusMenuItem(label: 'Submenu', children: [
          DBusMenuItem(
              label: 'Submenu 1',
              onClicked: () async => print('Submenu item 1 clicked!')),
          DBusMenuItem(
              label: 'Submenu 2',
              onClicked: () async => print('Submenu item 2 clicked!')),
          DBusMenuItem(
              label: 'Submenu 3',
              onClicked: () async => print('Submenu item 3 clicked!'))
        ]),
        DBusMenuItem.separator(),
        DBusMenuItem.checkmark('Checkmark On', state: true),
        DBusMenuItem.checkmark('Checkmark Off'),
        DBusMenuItem.separator(),
        DBusMenuItem.checkmark('Radio 1', state: true),
        DBusMenuItem.checkmark('Radio 2'),
        DBusMenuItem.checkmark('Radio 3'),
      ]));
  //await client.close();
}
