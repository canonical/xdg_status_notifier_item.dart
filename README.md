[![Pub Package](https://img.shields.io/pub/v/xdg_status_notifier_item.svg)](https://pub.dev/packages/xdg_status_notifier_item)
[![codecov](https://codecov.io/gh/canonical/xdg_status_notifier_item.dart/branch/main/graph/badge.svg?token=QW1N0AQQOY)](https://codecov.io/gh/canonical/xdg_status_notifier_item.dart)

Allows status notifications (i.e. system tray) on Linux desktops using the [StatusNotifierItem specification](https://www.freedesktop.org/wiki/Specifications/StatusNotifierItem/).

```dart
import 'package:xdg_status_notifier_item/xdg_status_notifier_item.dart';

var client = StatusNotificationItemClient();
...
await client.close();
```

## Contributing to xdg_status_notifier_item.dart

We welcome contributions! See the [contribution guide](CONTRIBUTING.md) for more details.
