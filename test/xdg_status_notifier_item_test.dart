import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:xdg_status_notifier_item/xdg_status_notifier_item.dart';
import 'package:test/test.dart';

class MockNotifierWatcherObject extends DBusObject {
  MockNotifierWatcherObject() : super(DBusObjectPath('/StatusNotifierWatcher'));

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface != 'org.kde.StatusNotifierWatcher') {
      return DBusMethodErrorResponse.unknownInterface();
    }

    switch (methodCall.name) {
      case 'RegisterStatusNotifierItem':
        return DBusMethodSuccessResponse();

      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }
}

class MockNotifierWatcherServer extends DBusClient {
  late final MockNotifierWatcherObject _root;

  MockNotifierWatcherServer(DBusAddress clientAddress) : super(clientAddress) {
    _root = MockNotifierWatcherObject();
  }

  Future<void> start() async {
    await requestName('org.kde.StatusNotifierWatcher');
    await registerObject(_root);
  }
}

void main() {
  test('connect', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var watcher = MockNotifierWatcherServer(clientAddress);
    await watcher.start();
    addTearDown(() async {
      await watcher.close();
    });

    var client = StatusNotifierItemClient(
        id: 'test', menu: DBusMenuItem(), bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });
    await client.connect();
  });
}
