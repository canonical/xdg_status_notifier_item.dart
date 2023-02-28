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

class DBusMenuItem {
  final String? type;
  final bool? enabled;
  final bool? visible;
  final String? label;
  final int? toggleState;
  final String? toggleType;
  final List<DBusMenuItem> children;
  bool Function(int id)? aboutToShow;
  Future<void> Function()? opened;
  Future<void> Function()? closed;
  Future<void> Function()? clicked;

  DBusMenuItem(
      {this.type,
      this.enabled,
      this.visible,
      this.label,
      this.toggleState,
      this.toggleType,
      this.children = const [],
      this.aboutToShow,
      this.opened,
      this.closed,
      this.clicked});

  DBusMenuItem.separator({bool visible = true})
      : this(type: 'separator', visible: visible);

  DBusMenuItem.checkmark(String label,
      {bool visible = true,
      bool enabled = true,
      bool state = false,
      Future<void> Function()? clicked})
      : this(
            visible: visible,
            enabled: enabled,
            label: label,
            toggleType: 'checkmark',
            toggleState: state ? 1 : 0,
            clicked: clicked);

  DBusMenuItem.radio(String label,
      {bool visible = true,
      bool enabled = true,
      bool state = false,
      Future<void> Function()? clicked})
      : this(
            visible: visible,
            enabled: enabled,
            label: label,
            toggleType: 'radio',
            toggleState: state ? 1 : 0,
            clicked: clicked);
}

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
  DBusMenuItem menu;
  var _items = <DBusMenuItem>[];
  var _idsByItem = <DBusMenuItem, int>{};

  _MenuObject(this.menu) : super(DBusObjectPath('/Menu')) {
    _registerId(menu);
  }

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
        DBusIntrospectMethod('GetLayout', args: [
          DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_,
              name: 'parentId'),
          DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_,
              name: 'recursionDepth'),
          DBusIntrospectArgument(DBusSignature('as'), DBusArgumentDirection.in_,
              name: 'propertyNames'),
          DBusIntrospectArgument(DBusSignature('u'), DBusArgumentDirection.out,
              name: 'revision'),
          DBusIntrospectArgument(
              DBusSignature('(ia{sv}av)'), DBusArgumentDirection.out,
              name: 'layout')
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
    if (methodCall.interface != 'com.canonical.dbusmenu') {
      return DBusMethodErrorResponse.unknownInterface();
    }

    switch (methodCall.name) {
      case 'AboutToShow':
        if (methodCall.signature != DBusSignature('i')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        var id = methodCall.values[0].asInt32();
        var item = _getItem(id);
        if (item != null) {
          var needsUpdate = await item.aboutToShow?.call(id) ?? false;
          return DBusMethodSuccessResponse([DBusBoolean(needsUpdate)]);
        } else {
          return DBusMethodErrorResponse('com.canonical.dbusmenu.UnknownId');
        }
      case 'AboutToShowGroup':
        if (methodCall.signature != DBusSignature('ai')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        var ids = methodCall.values[0].asInt32Array();
        return DBusMethodSuccessResponse(
            [DBusArray.int32([]), DBusArray.int32([])]);
      case 'Event':
        if (methodCall.signature != DBusSignature('isvu')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        var id = methodCall.values[0].asInt32();
        var eventId = methodCall.values[1].asString();
        //var data = methodCall.values[2].asVariant();
        //var timestamp = methodCall.values[3].asUint32();
        var item = _getItem(id);
        if (item != null) {
          switch (eventId) {
            case 'opened':
              await item.opened?.call();
              break;
            case 'closed':
              await item.closed?.call();
              break;
            case 'clicked':
              await item.clicked?.call();
              break;
          }
        }
        return DBusMethodSuccessResponse();
      case 'EventGroup':
        if (methodCall.signature != DBusSignature('a(isvu)')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return DBusMethodSuccessResponse([DBusArray.int32([])]);
      case 'GetLayout':
        if (methodCall.signature != DBusSignature('iias')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        var parentId = methodCall.values[0].asInt32();
        var recursionDepth = methodCall.values[1].asInt32();
        var propertyNames = methodCall.values[2].asStringArray();
        var revision = 1;
        return DBusMethodSuccessResponse(
            [DBusUint32(revision), _makeMenuItem(menu)]);
      case 'GetProperty':
        if (methodCall.signature != DBusSignature('is')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return DBusMethodSuccessResponse([DBusVariant(DBusString(''))]);
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }

  void _registerId(DBusMenuItem item) {
    var id = _items.length;
    _items.add(item);
    _idsByItem[item] = id;
    item.children.forEach(_registerId);
  }

  DBusValue _makeMenuItem(DBusMenuItem item) {
    var properties = <String, DBusValue>{};
    if (item.type != null) {
      properties['type'] = DBusString(item.type!);
    }
    if (item.enabled != null) {
      properties['enabled'] = DBusBoolean(item.enabled!);
    }
    if (item.visible != null) {
      properties['visible'] = DBusBoolean(item.visible!);
    }
    if (item.label != null) {
      properties['label'] = DBusString(item.label!);
    }
    if (item.toggleType != null) {
      properties['toggle-type'] = DBusString(item.toggleType!);
    }
    if (item.toggleState != null) {
      properties['toggle-state'] = DBusInt32(item.toggleState!);
    }
    if (item.children.isNotEmpty) {
      properties['children-display'] = DBusString('submenu');
    }
    return DBusStruct([
      DBusInt32(_idsByItem[item] ?? -1),
      DBusDict.stringVariant(properties),
      DBusArray.variant(item.children.map(_makeMenuItem))
    ]);
  }

  DBusMenuItem? _getItem(int id) {
    return id >= 0 && id <= _items.length ? _items[id] : null;
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
  Future<void> Function(int x, int y)? contextMenu;
  Future<void> Function(int x, int y)? activate;
  Future<void> Function(int x, int y)? secondaryActivate;
  Future<void> Function(int delta, String orientation)? scroll;

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
      this.menu = DBusObjectPath.root,
      this.contextMenu,
      this.activate,
      this.secondaryActivate,
      this.scroll})
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
        var x = methodCall.values[0].asInt32();
        var y = methodCall.values[0].asInt32();
        await contextMenu?.call(x, y);
        return DBusMethodSuccessResponse();
      case 'Activate':
        if (methodCall.signature != DBusSignature('ii')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        var x = methodCall.values[0].asInt32();
        var y = methodCall.values[0].asInt32();
        await activate?.call(x, y);
        return DBusMethodSuccessResponse();
      case 'SecondaryActivate':
        if (methodCall.signature != DBusSignature('ii')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        var x = methodCall.values[0].asInt32();
        var y = methodCall.values[0].asInt32();
        await secondaryActivate?.call(x, y);
        return DBusMethodSuccessResponse();
      case 'Scroll':
        if (methodCall.signature != DBusSignature('is')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        var delta = methodCall.values[0].asInt32();
        var orientation = methodCall.values[0].asString();
        await scroll?.call(delta, orientation);
        return DBusMethodSuccessResponse();
      case 'ProvideXdgActivationToken':
        if (methodCall.signature != DBusSignature('s')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return DBusMethodSuccessResponse();
      default:
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
    var menu = DBusMenuItem(children: [
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
        DBusMenuItem.checkmark('Autostart on login', state: true)
      ]),
      DBusMenuItem(label: 'Quit')
    ]);
    var menuObject = _MenuObject(menu);
    await _bus.registerObject(menuObject);

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
        menu: menuObject.path);
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
