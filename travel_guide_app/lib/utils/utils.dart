import 'dart:convert';
import 'package:crypto/crypto.dart';

String hashPassword(String password) {
  // Convert the password to UTF-8 and then hash it
  var bytes = utf8.encode(password);
  var digest = sha256.convert(bytes);
  return digest.toString();
}
