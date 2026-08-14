import 'dart:io';

String platformLocalHost() {
  if (Platform.isAndroid) return '10.0.2.2';
  return '127.0.0.1';
}
