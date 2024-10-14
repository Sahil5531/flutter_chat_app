import 'dart:math';

String generateRandomNumber(int length) {
  const chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  Random rnd = Random();
  final string = String.fromCharCodes(Iterable.generate(
      length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  return string;
}

bool isValidPhoneNumber(String phoneNumber) {
  final RegExp phoneRegex =
      RegExp(r'^(\+[0-9]{1,3})?([0-9]{3})?([0-9]{7,10})$');
  return phoneRegex.hasMatch(phoneNumber);
}
