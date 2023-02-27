import 'package:xdg_status_notifier_item/xdg_status_notifier_item.dart';

void main() async {
  var client = StatusNotifierItemClient();
  await client.addItem(id: 'dart-test', title: 'Test');
  //await client.close();
}
