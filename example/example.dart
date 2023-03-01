import 'package:xdg_status_notifier_item/xdg_status_notifier_item.dart';

late StatusNotifierItemClient client;
var itemClicked = false;
var checkmarkIsActive = true;
var activeRadio = 1;

DBusMenuItem buildMenu() {
  return DBusMenuItem(children: [
    DBusMenuItem(
        label: itemClicked ? 'Clicked Item' : 'Item',
        onClicked: () async => await handleClick()),
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
    DBusMenuItem.checkmark('Checkmark',
        state: checkmarkIsActive,
        onClicked: () async => await toggleCheckmark()),
    DBusMenuItem.separator(),
    DBusMenuItem.checkmark('Radio 1',
        state: activeRadio == 1, onClicked: () async => await setRadio(1)),
    DBusMenuItem.checkmark('Radio 2',
        state: activeRadio == 2, onClicked: () async => await setRadio(2)),
    DBusMenuItem.checkmark('Radio 3',
        state: activeRadio == 3, onClicked: () async => await setRadio(3)),
    DBusMenuItem.separator(),
    DBusMenuItem(label: 'Quit', onClicked: () async => await client.close()),
  ]);
}

Future<void> rebuild() async {
  await client.updateMenu(buildMenu());
}

Future<void> handleClick() async {
  itemClicked = true;
  await rebuild();
}

Future<void> toggleCheckmark() async {
  checkmarkIsActive = !checkmarkIsActive;
  await rebuild();
}

Future<void> setRadio(int active) async {
  activeRadio = active;
  await rebuild();
}

void main() async {
  client = StatusNotifierItemClient();
  await client.addItem(
      id: 'dart-test', iconName: 'computer-fail-symbolic', menu: buildMenu());
}
