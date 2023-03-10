import 'dart:async';
import 'package:dbus/dbus.dart';

/// An item in the menu.
class DBusMenuItem {
  final String? type;
  final bool? enabled;
  final bool? visible;
  final String? label;
  final int? toggleState;
  final String? toggleType;
  final List<DBusMenuItem> children;

  // Called when this menu item is about to be shown. Return true if this item needs updating.
  final Future<bool> Function()? onAboutToShow;

  /// Called when the submenu under this item is opened.
  final Future<void> Function()? onOpened;

  /// Called when the submenu under this item is closed.
  final Future<void> Function()? onClosed;

  /// Called when this item is clicked.
  final Future<void> Function()? onClicked;

  /// Creates a new menu item.
  DBusMenuItem(
      {this.type,
      this.enabled,
      this.visible,
      this.label,
      this.toggleState,
      this.toggleType,
      this.children = const [],
      this.onAboutToShow,
      this.onOpened,
      this.onClosed,
      this.onClicked});

  /// Creates a new separator menu item.
  DBusMenuItem.separator({bool visible = true})
      : this(type: 'separator', visible: visible);

  // Creates a new checkmark menu item. If [state] is true the item is checked.
  DBusMenuItem.checkmark(String label,
      {bool visible = true,
      bool enabled = true,
      bool state = false,
      Future<void> Function()? onClicked})
      : this(
            visible: visible,
            enabled: enabled,
            label: label,
            toggleType: 'checkmark',
            toggleState: state ? 1 : 0,
            onClicked: onClicked);

  // Creates a new radio menu item. If [state] is true the item is active.
  DBusMenuItem.radio(String label,
      {bool visible = true,
      bool enabled = true,
      bool state = false,
      Future<void> Function()? onClicked})
      : this(
            visible: visible,
            enabled: enabled,
            label: label,
            toggleType: 'radio',
            toggleState: state ? 1 : 0,
            onClicked: onClicked);
}

class DBusMenuObject extends DBusObject {
  // The menu being exported over DBus.
  DBusMenuItem menu;

  final _items = <DBusMenuItem>[];
  final _idsByItem = <DBusMenuItem, int>{};

  DBusMenuObject(DBusObjectPath path, this.menu) : super(path) {
    _registerIds(menu);
  }

  /// Export an updated [menu]. This must have the same number and layout of items as the previous menu.
  Future<void> update(DBusMenuItem menu) async {
    // Calculate what has changed.
    var updatedProperties = <DBusValue>[];
    var removedProperties = <DBusValue>[];
    _makeMenuItemPropertiesUpdated(
        this.menu, menu, updatedProperties, removedProperties);

    // Replace old menu.
    _items.clear();
    _idsByItem.clear();
    this.menu = menu;
    _registerIds(menu);

    await emitSignal('com.canonical.dbusmenu', 'ItemsPropertiesUpdated', [
      DBusArray(DBusSignature('(ia{sv})'), updatedProperties),
      DBusArray(DBusSignature('(ias)'), removedProperties)
    ]);
  }

  void _makeMenuItemPropertiesUpdated(
      DBusMenuItem originalItem,
      DBusMenuItem newItem,
      List<DBusValue> allUpdatedProperties,
      List<DBusValue> allRemovedProperties) {
    var id = _idsByItem[originalItem]!;
    var originalProperties = _makeMenuItemProperties(originalItem);
    var newProperties = _makeMenuItemProperties(newItem);
    var updatedProperties =
        _getUpdatedProperties(originalProperties, newProperties);
    if (updatedProperties.isNotEmpty) {
      allUpdatedProperties.add(DBusStruct(
          [DBusInt32(id), DBusDict.stringVariant(updatedProperties)]));
    }
    var removedProperties =
        _getRemovedProperties(originalProperties, newProperties);
    if (removedProperties.isNotEmpty) {
      allRemovedProperties.add(
          DBusStruct([DBusInt32(id), DBusArray.string(removedProperties)]));
    }

    assert(originalItem.children.length == newItem.children.length);
    for (var i = 0; i < originalItem.children.length; i++) {
      _makeMenuItemPropertiesUpdated(originalItem.children[i],
          newItem.children[i], allUpdatedProperties, allRemovedProperties);
    }
  }

  @override
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
      ], signals: [
        DBusIntrospectSignal('ItemsPropertiesUpdated', args: [
          DBusIntrospectArgument(
              DBusSignature('a(ia{sv})'), DBusArgumentDirection.out,
              name: 'updatedProps'),
          DBusIntrospectArgument(
              DBusSignature('a(ias)'), DBusArgumentDirection.out,
              name: 'removedProps')
        ]),
        DBusIntrospectSignal('LayoutUpdated', args: [
          DBusIntrospectArgument(DBusSignature('u'), DBusArgumentDirection.out,
              name: 'revision'),
          DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.out,
              name: 'parent')
        ]),
        DBusIntrospectSignal('ItemActivationRequested', args: [
          DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.out,
              name: 'id'),
          DBusIntrospectArgument(DBusSignature('u'), DBusArgumentDirection.out,
              name: 'timestamp')
        ]),
      ], properties: [
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
        if (item == null) {
          return DBusMethodErrorResponse('com.canonical.dbusmenu.UnknownId');
        }
        var needsUpdate = await item.onAboutToShow?.call() ?? false;
        return DBusMethodSuccessResponse([DBusBoolean(needsUpdate)]);
      case 'AboutToShowGroup':
        if (methodCall.signature != DBusSignature('ai')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        var ids = methodCall.values[0].asInt32Array();
        var updatesNeeded = <int>[];
        var idErrors = <int>[];
        for (var id in ids) {
          var item = _getItem(id);
          if (item == null) {
            idErrors.add(id);
          } else {
            var needsUpdate = await item.onAboutToShow?.call() ?? false;
            if (needsUpdate) updatesNeeded.add(id);
          }
        }
        return DBusMethodSuccessResponse(
            [DBusArray.int32(updatesNeeded), DBusArray.int32(idErrors)]);
      case 'Event':
        if (methodCall.signature != DBusSignature('isvu')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        var id = methodCall.values[0].asInt32();
        var eventId = methodCall.values[1].asString();
        var data = methodCall.values[2].asVariant();
        var timestamp = methodCall.values[3].asUint32();
        var item = _getItem(id);
        if (item == null) {
          return DBusMethodErrorResponse('com.canonical.dbusmenu.UnknownId');
        }
        await _handleEvent(item, eventId, data, timestamp);
        return DBusMethodSuccessResponse();
      case 'EventGroup':
        if (methodCall.signature != DBusSignature('a(isvu)')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        var events = methodCall.values[0].asArray();
        var idErrors = <int>[];
        for (var event in events) {
          var values = event.asArray();
          var id = values[0].asInt32();
          var eventId = values[1].asString();
          var data = values[2].asVariant();
          var timestamp = values[3].asUint32();
          var item = _getItem(id);
          if (item == null) {
            idErrors.add(id);
          } else {
            await _handleEvent(item, eventId, data, timestamp);
          }
        }
        return DBusMethodSuccessResponse([DBusArray.int32(idErrors)]);
      case 'GetLayout':
        if (methodCall.signature != DBusSignature('iias')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        var parentId = methodCall.values[0].asInt32();
        var recursionDepth = methodCall.values[1].asInt32();
        //var propertyNames = methodCall.values[2].asStringArray();
        var item = _getItem(parentId);
        if (item == null) {
          return DBusMethodErrorResponse('com.canonical.dbusmenu.UnknownId');
        }
        var revision = 1;
        return DBusMethodSuccessResponse(
            [DBusUint32(revision), _makeMenuItem(item, recursionDepth)]);
      case 'GetProperty':
        if (methodCall.signature != DBusSignature('is')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        var id = methodCall.values[0].asInt32();
        var name = methodCall.values[1].asString();
        var item = _getItem(id);
        if (item == null) {
          return DBusMethodErrorResponse('com.canonical.dbusmenu.UnknownId');
        }
        var properties = _makeMenuItemProperties(item);
        var property = properties[name];
        if (property == null) {
          return DBusMethodErrorResponse(
              'com.canonical.dbusmenu.UnknownProperty');
        }
        return DBusMethodSuccessResponse([DBusVariant(property)]);
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }

  // Register a new [item] and assign it an id.
  void _registerIds(DBusMenuItem item) {
    var id = _items.length;
    _items.add(item);
    _idsByItem[item] = id;
    item.children.forEach(_registerIds);
  }

  // Build properties on menu items.
  Map<String, DBusValue> _makeMenuItemProperties(DBusMenuItem item) {
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
    return properties;
  }

  // Returns properties in [newProperties] that are new or have changed values from [originalProperties].
  static Map<String, DBusValue> _getUpdatedProperties(
      Map<String, DBusValue> originalProperties,
      Map<String, DBusValue> newProperties) {
    return Map.fromEntries(newProperties.entries.where((entry) =>
        !originalProperties.containsKey(entry.key) ||
        originalProperties[entry.key] != entry.value));
  }

  // Returns names of properties that are in [originalProperties] but not in [newProperties].
  static List<String> _getRemovedProperties(
      Map<String, DBusValue> originalProperties,
      Map<String, DBusValue> newProperties) {
    return originalProperties.keys
        .where((name) => !newProperties.containsKey(name))
        .toList();
  }

  // Build description of menu items.
  DBusValue _makeMenuItem(DBusMenuItem item, int recursionDepth) {
    List<DBusValue> children = [];
    if (recursionDepth != 0) {
      var nextRecursionDepth =
          recursionDepth < 0 ? recursionDepth : recursionDepth - 1;
      for (var child in item.children) {
        children.add(_makeMenuItem(child, nextRecursionDepth));
      }
    }
    return DBusStruct([
      DBusInt32(_idsByItem[item] ?? -1),
      DBusDict.stringVariant(_makeMenuItemProperties(item)),
      DBusArray.variant(children)
    ]);
  }

  // Get the item with the given [id].
  DBusMenuItem? _getItem(int id) {
    return id >= 0 && id <= _items.length ? _items[id] : null;
  }

  // Handle a received event.
  Future<void> _handleEvent(
      DBusMenuItem item, String eventId, DBusValue data, int timestamp) async {
    switch (eventId) {
      case 'opened':
        await item.onOpened?.call();
        break;
      case 'closed':
        await item.onClosed?.call();
        break;
      case 'clicked':
        await item.onClicked?.call();
        break;
    }
  }
}
