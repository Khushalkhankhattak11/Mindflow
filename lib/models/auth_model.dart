class UserCredentials {
  final String? name;
  final String email;
  final String password;
  final bool termsAccepted;

  const UserCredentials({
    this.name,
    required this.email,
    required this.password,
    this.termsAccepted = false,
  });
}
