class ForgotPasswordResult {
  ForgotPasswordResult({
    required this.message,
    required this.identifier,
    required this.channel,
    this.destinationMasked,
  });

  final String message;
  final String identifier;
  final String channel;
  final String? destinationMasked;

  bool get isEmail => channel == 'email';
}
