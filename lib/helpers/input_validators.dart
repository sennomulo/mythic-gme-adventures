import 'string_extensions.dart';

String? validateNotEmpty(String? value) {
  if (value.isNullOrEmpty()) {
    return '此项为必填';
  }
  return null;
}
