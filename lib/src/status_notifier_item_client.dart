import 'dart:async';
import 'dart:io';
import 'package:dbus/dbus.dart';

/// Category for notifier items.
enum StatusNotifierItemCategory {
  applicationStatus,
  communications,
  systemServices,
  hardware
}

/// Status for notifier items.
enum StatusNotifierItemStatus { passive, active }

String _encodeCategory(StatusNotifierItemCategory value) =>
    {
      StatusNotifierItemCategory.applicationStatus: 'ApplicationStatus',
      StatusNotifierItemCategory.communications: 'Communications',
      StatusNotifierItemCategory.systemServices: 'SystemServices',
      StatusNotifierItemCategory.hardware: 'Hardware'
    }[value] ??
    '';

String _encodeStatus(StatusNotifierItemStatus value) =>
    {
      StatusNotifierItemStatus.passive: 'Passive',
      StatusNotifierItemStatus.active: 'Active'
    }[value] ??
    '';

class _MenuObject extends DBusObject {
  _MenuObject() : super(DBusObjectPath('/Menu'));

  List<DBusIntrospectInterface> introspect() {
    return [
      DBusIntrospectInterface('com.canonical.dbusmenu', methods: [
        DBusIntrospectMethod('AboutToShow', args: [
          DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_,
              name: 'id'),
          DBusIntrospectArgument(DBusSignature('b'), DBusArgumentDirection.out,
              name: 'needsUpdate')
        ]),
        DBusIntrospectMethod('AboutToShowGroup', args: [
          DBusIntrospectArgument(DBusSignature('ai'), DBusArgumentDirection.in_,
              name: 'ids'),
          DBusIntrospectArgument(DBusSignature('ai'), DBusArgumentDirection.out,
              name: 'updatesNeeded'),
          DBusIntrospectArgument(DBusSignature('ai'), DBusArgumentDirection.out,
              name: 'idErrors')
        ]),
        DBusIntrospectMethod('Event', args: [
          DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_,
              name: 'id'),
          DBusIntrospectArgument(DBusSignature('s'), DBusArgumentDirection.in_,
              name: 'eventId'),
          DBusIntrospectArgument(DBusSignature('v'), DBusArgumentDirection.in_,
              name: 'data'),
          DBusIntrospectArgument(DBusSignature('u'), DBusArgumentDirection.in_,
              name: 'timestamp')
        ]),
        DBusIntrospectMethod('EventGroup', args: [
          DBusIntrospectArgument(
              DBusSignature('a(isvu)'), DBusArgumentDirection.in_,
              name: 'events'),
          DBusIntrospectArgument(DBusSignature('ai'), DBusArgumentDirection.out,
              name: 'idErrors')
        ]),
        DBusIntrospectMethod('GetProperty', args: [
          DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_,
              name: 'id'),
          DBusIntrospectArgument(DBusSignature('s'), DBusArgumentDirection.in_,
              name: 'name'),
          DBusIntrospectArgument(DBusSignature('v'), DBusArgumentDirection.out,
              name: 'value')
        ])
      ], signals: [], properties: [
        DBusIntrospectProperty('IconThemePath', DBusSignature('as'),
            access: DBusPropertyAccess.read),
        DBusIntrospectProperty('Status', DBusSignature('s'),
            access: DBusPropertyAccess.read),
        DBusIntrospectProperty('TextDirection', DBusSignature('s'),
            access: DBusPropertyAccess.read),
        DBusIntrospectProperty('Version', DBusSignature('u'),
            access: DBusPropertyAccess.read)
      ])
    ];
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    print(methodCall);

    if (methodCall.interface != 'com.canonical.dbusmenu') {
      return DBusMethodErrorResponse.unknownInterface();
    }

    switch (methodCall.name) {
      case 'AboutToShow':
        if (methodCall.signature != DBusSignature('i')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return DBusMethodSuccessResponse([DBusBoolean(false)]);

      case 'AboutToShowGroup':
        if (methodCall.signature != DBusSignature('ai')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return DBusMethodSuccessResponse([DBusArray.int32([])]);

      case 'Event':
        if (methodCall.signature != DBusSignature('isvu')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return DBusMethodSuccessResponse();

      case 'EventGroup':
        if (methodCall.signature != DBusSignature('a(isvu)')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return DBusMethodSuccessResponse([DBusArray.int32([])]);

      case 'GetProperty':
        if (methodCall.signature != DBusSignature('is')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return DBusMethodSuccessResponse([DBusVariant(DBusString(''))]);

      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    if (interface != 'com.canonical.dbusmenu') {
      return DBusMethodErrorResponse.unknownProperty();
    }

    switch (name) {
      default:
        print('get property $interface $name');
        return DBusMethodErrorResponse.unknownProperty();
    }
  }
}

class _StatusNotifierItemObject extends DBusObject {
  final StatusNotifierItemCategory category;
  final String id;
  String title;
  StatusNotifierItemStatus status;
  final int windowId;
  String iconName;
  String overlayIconName;
  String attentionIconName;
  String attentionMovieName;
  final bool itemIsMenu;
  final DBusObjectPath menu;

  _StatusNotifierItemObject(
      {this.category = StatusNotifierItemCategory.applicationStatus,
      required this.id,
      this.title = '',
      this.status = StatusNotifierItemStatus.active,
      this.windowId = 0,
      this.iconName = '',
      this.overlayIconName = '',
      this.attentionIconName = '',
      this.attentionMovieName = '',
      this.itemIsMenu = false,
      this.menu = DBusObjectPath.root})
      : super(DBusObjectPath('/StatusNotifierItem'));

  List<DBusIntrospectInterface> introspect() {
    return [
      DBusIntrospectInterface('org.freedesktop.StatusNotifierItem', methods: [
        DBusIntrospectMethod('ContextMenu', args: [
          DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_,
              name: 'x'),
          DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_,
              name: 'y')
        ]),
        DBusIntrospectMethod('Activate', args: [
          DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_,
              name: 'x'),
          DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_,
              name: 'y')
        ]),
        DBusIntrospectMethod('SecondaryActivate', args: [
          DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_,
              name: 'x'),
          DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_,
              name: 'y')
        ]),
        DBusIntrospectMethod('Scroll', args: [
          DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_,
              name: 'delta'),
          DBusIntrospectArgument(DBusSignature('s'), DBusArgumentDirection.in_,
              name: 'orientation')
        ]),
        DBusIntrospectMethod('ProvideXdgActivationToken', args: [
          DBusIntrospectArgument(DBusSignature('s'), DBusArgumentDirection.in_,
              name: 'token')
        ])
      ], signals: [], properties: [
        DBusIntrospectProperty('Category', DBusSignature('s'),
            access: DBusPropertyAccess.read),
        DBusIntrospectProperty('Id', DBusSignature('s'),
            access: DBusPropertyAccess.read),
        DBusIntrospectProperty('Title', DBusSignature('s'),
            access: DBusPropertyAccess.read),
        DBusIntrospectProperty('Status', DBusSignature('s'),
            access: DBusPropertyAccess.read),
        DBusIntrospectProperty('WindowId', DBusSignature('i'),
            access: DBusPropertyAccess.read),
        DBusIntrospectProperty('IconName', DBusSignature('s'),
            access: DBusPropertyAccess.read),
        DBusIntrospectProperty('IconPixmap', DBusSignature('a(iiay)'),
            access: DBusPropertyAccess.read),
        DBusIntrospectProperty('OverlayIconName', DBusSignature('s'),
            access: DBusPropertyAccess.read),
        DBusIntrospectProperty('OverlayIconPixmap', DBusSignature('a(iiay)'),
            access: DBusPropertyAccess.read),
        DBusIntrospectProperty('AttentionIconName', DBusSignature('s'),
            access: DBusPropertyAccess.read),
        DBusIntrospectProperty('AttentionIconPixmap', DBusSignature('a(iiay)'),
            access: DBusPropertyAccess.read),
        DBusIntrospectProperty('AttentionMovieName', DBusSignature('s'),
            access: DBusPropertyAccess.read),
        DBusIntrospectProperty('ToolTip', DBusSignature('(sa(iiay))'),
            access: DBusPropertyAccess.read),
        DBusIntrospectProperty('ItemIsMenu', DBusSignature('b'),
            access: DBusPropertyAccess.read),
        DBusIntrospectProperty('Menu', DBusSignature('o'),
            access: DBusPropertyAccess.read)
      ])
    ];
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface != 'org.freedesktop.StatusNotifierItem') {
      return DBusMethodErrorResponse.unknownInterface();
    }

    switch (methodCall.name) {
      case 'ContextMenu':
        if (methodCall.signature != DBusSignature('ii')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return DBusMethodSuccessResponse();
      case 'Activate':
        if (methodCall.signature != DBusSignature('ii')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return DBusMethodSuccessResponse();
      case 'SecondaryActivate':
        if (methodCall.signature != DBusSignature('ii')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return DBusMethodSuccessResponse();
      case 'Scroll':
        if (methodCall.signature != DBusSignature('is')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return DBusMethodSuccessResponse();
      case 'ProvideXdgActivationToken':
        if (methodCall.signature != DBusSignature('s')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return DBusMethodSuccessResponse();
      default:
        print(methodCall);
        return DBusMethodErrorResponse.unknownMethod();
    }
  }

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    if (interface != 'org.freedesktop.StatusNotifierItem') {
      return DBusMethodErrorResponse.unknownProperty();
    }

    switch (name) {
      case 'Category':
        return DBusGetPropertyResponse(DBusString(_encodeCategory(category)));
      case 'Id':
        return DBusGetPropertyResponse(DBusString(id));
      case 'Title':
        return DBusGetPropertyResponse(DBusString(title));
      case 'Status':
        return DBusGetPropertyResponse(DBusString(_encodeStatus(status)));
      case 'WindowId':
        return DBusGetPropertyResponse(DBusInt32(windowId));
      case 'IconName':
        return DBusGetPropertyResponse(DBusString(iconName));
      case 'IconPixmap':
        return DBusGetPropertyResponse(DBusArray(DBusSignature('(iiay)'), []));
      case 'OverlayIconName':
        return DBusGetPropertyResponse(DBusString(overlayIconName));
      case 'OverlayIconPixmap':
        return DBusGetPropertyResponse(DBusArray(DBusSignature('(iiay)'), []));
      case 'AttentionIconName':
        return DBusGetPropertyResponse(DBusString(attentionIconName));
      case 'AttentionIconPixmap':
        return DBusGetPropertyResponse(DBusArray(DBusSignature('(iiay)'), []));
      case 'AttentionMovieName':
        return DBusGetPropertyResponse(DBusString(attentionMovieName));
      case 'ToolTip':
        return DBusGetPropertyResponse(DBusStruct([
          DBusString(''),
          DBusArray(DBusSignature('(iiay)'), []),
          DBusString(''),
          DBusString('')
        ]));
      case 'ItemIsMenu':
        return DBusGetPropertyResponse(DBusBoolean(itemIsMenu));
      case 'Menu':
        return DBusGetPropertyResponse(menu);
      default:
        print('get property $interface $name');
        return DBusMethodErrorResponse.unknownProperty();
    }
  }

  @override
  Future<DBusMethodResponse> getAllProperties(String interface) async {
    return DBusGetAllPropertiesResponse({
      'Category': DBusString(_encodeCategory(category)),
      'Id': DBusString(id),
      'Title': DBusString(title),
      'Status': DBusString(_encodeStatus(status)),
      'WindowId': DBusInt32(windowId),
      'IconName': DBusString(iconName),
      'OverlayIconName': DBusString(overlayIconName),
      'AttentionIconName': DBusString(attentionIconName),
      'AttentionMovieName': DBusString(attentionMovieName),
      'ItemIsMenu': DBusBoolean(itemIsMenu),
      'Menu': menu
    });
  }
}

/// A client that registers status notifier items.
class StatusNotifierItemClient {
  /// The bus this client is connected to.
  final DBusClient _bus;
  final bool _closeBus;

  /// Creates a new status notifier item client. If [bus] is provided connect to the given D-Bus server.
  StatusNotifierItemClient({DBusClient? bus})
      : _bus = bus ?? DBusClient.session(),
        _closeBus = bus == null {}

  // FIXME: status enum
  Future<void> addItem(
      {required String id,
      StatusNotifierItemCategory category =
          StatusNotifierItemCategory.applicationStatus,
      String title = '',
      StatusNotifierItemStatus status = StatusNotifierItemStatus.active,
      int windowId = 0,
      String iconName = '',
      String overlayIconName = '',
      String attentionIconName = '',
      String attentionMovieName = ''}) async {
    var name = 'org.kde.StatusNotifierItem-$pid-1';
    var requestResult = await _bus.requestName(name);
    assert(requestResult == DBusRequestNameReply.primaryOwner);

    // Create a menu.
    var menu = _MenuObject();
    await _bus.registerObject(menu);

    // Put the item on the bus.
    var item = _StatusNotifierItemObject(
        id: id,
        category: category,
        title: title,
        status: status,
        windowId: windowId,
        iconName: iconName,
        overlayIconName: overlayIconName,
        attentionIconName: attentionIconName,
        attentionMovieName: attentionMovieName,
        menu: menu.path);
    await _bus.registerObject(item);

    // Register the item.
    await _bus.callMethod(
        destination: 'org.kde.StatusNotifierWatcher',
        path: DBusObjectPath('/StatusNotifierWatcher'),
        interface: 'org.kde.StatusNotifierWatcher',
        name: 'RegisterStatusNotifierItem',
        values: [DBusString(name)],
        replySignature: DBusSignature.empty);
  }

  /// Terminates all active connections. If a client remains unclosed, the Dart process may not terminate.
  Future<void> close() async {
    if (_closeBus) {
      await _bus.close();
    }
  }
}
