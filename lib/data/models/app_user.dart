class ProviderData {
  final String providerId;
  ProviderData({required this.providerId});
}

class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final String? phoneNumber;
  final bool emailVerified;
  final List<ProviderData> providerData;

  AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.phoneNumber,
    this.emailVerified = false,
    this.providerData = const [],
  });
}

class AppUserCredential {
  final AppUser user;
  AppUserCredential({required this.user});
}
