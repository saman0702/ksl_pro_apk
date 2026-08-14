class PhoneCountry {
  const PhoneCountry({
    required this.name,
    required this.dialCode,
    required this.flag,
  });

  final String name;
  final String dialCode;
  final String flag;

  static const PhoneCountry defaultCountry = ci;

  static const PhoneCountry ci = PhoneCountry(
    name: 'Côte d\'Ivoire',
    dialCode: '+225',
    flag: '🇨🇮',
  );

  static const List<PhoneCountry> all = [
    ci,
    PhoneCountry(name: 'Sénégal', dialCode: '+221', flag: '🇸🇳'),
    PhoneCountry(name: 'Mali', dialCode: '+223', flag: '🇲🇱'),
    PhoneCountry(name: 'Burkina Faso', dialCode: '+226', flag: '🇧🇫'),
    PhoneCountry(name: 'Ghana', dialCode: '+233', flag: '🇬🇭'),
    PhoneCountry(name: 'Bénin', dialCode: '+229', flag: '🇧🇯'),
    PhoneCountry(name: 'Togo', dialCode: '+228', flag: '🇹🇬'),
    PhoneCountry(name: 'Guinée', dialCode: '+224', flag: '🇬🇳'),
    PhoneCountry(name: 'France', dialCode: '+33', flag: '🇫🇷'),
  ];

  static PhoneCountry? findByDialCode(String code) {
    final normalized = code.startsWith('+') ? code : '+$code';
    for (final c in all) {
      if (c.dialCode == normalized) return c;
    }
    return null;
  }
}
