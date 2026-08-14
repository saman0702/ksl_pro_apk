import '../core/phone_countries.dart';

class PhoneUtils {
  PhoneUtils._();

  static bool isEmail(String value) => value.contains('@');

  static String normalize(PhoneCountry country, String localNumber) {
    final dialDigits = country.dialCode.replaceAll('+', '');
    var local = localNumber.replaceAll(RegExp(r'\D'), '');

    if (local.startsWith('00')) {
      local = local.substring(2);
    }

    if (local.startsWith(dialDigits)) {
      return _fixInternationalDigits('+$local', dialDigits);
    }

    if (local.startsWith('0') && local.length == 10) {
      return '+$dialDigits$local';
    }

    if (local.length == 9) {
      return '+${dialDigits}0$local';
    }

    return '+$dialDigits$local';
  }

  static String _fixInternationalDigits(String value, String dialDigits) {
    var digits = value.replaceAll(RegExp(r'\D'), '');
    if (!digits.startsWith(dialDigits)) {
      return value.startsWith('+') ? value : '+$digits';
    }
    var national = digits.substring(dialDigits.length);
    if (national.length == 9) {
      national = '0$national';
    }
    return '+$dialDigits$national';
  }

  static String normalizeRaw(
    String value, {
    PhoneCountry country = PhoneCountry.defaultCountry,
  }) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    if (isEmail(trimmed)) return trimmed;

    final dialDigits = country.dialCode.replaceAll('+', '');
    if (trimmed.startsWith('+')) {
      return _fixInternationalDigits(trimmed, dialDigits);
    }
    if (trimmed.replaceAll(RegExp(r'\D'), '').startsWith(dialDigits)) {
      return _fixInternationalDigits(trimmed, dialDigits);
    }
    return normalize(country, trimmed);
  }
}
