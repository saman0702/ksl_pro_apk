class OtpVerifyResult {
  OtpVerifyResult({
    required this.message,
    required this.identifier,
    this.channel = 'sms',
    this.destinationMasked,
  });

  final String message;
  final String identifier;
  final String channel;
  final String? destinationMasked;

  bool get isEmail => channel == 'email';
}
