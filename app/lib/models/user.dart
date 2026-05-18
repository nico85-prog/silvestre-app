class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String? phone;
  final DateTime createdAt;
  final bool acceptedTos;
  final bool acceptedMarketing;
  final bool acceptedPortfolioUse;
  final String role; // 'customer' | 'staff' | 'admin'

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.phone,
    required this.createdAt,
    this.acceptedTos = false,
    this.acceptedMarketing = false,
    this.acceptedPortfolioUse = false,
    this.role = 'customer',
  });

  AppUser copyWith({
    String? displayName,
    String? phone,
    bool? acceptedMarketing,
    bool? acceptedPortfolioUse,
    String? role,
  }) =>
      AppUser(
        id: id,
        email: email,
        displayName: displayName ?? this.displayName,
        phone: phone ?? this.phone,
        createdAt: createdAt,
        acceptedTos: acceptedTos,
        acceptedMarketing: acceptedMarketing ?? this.acceptedMarketing,
        acceptedPortfolioUse:
            acceptedPortfolioUse ?? this.acceptedPortfolioUse,
        role: role ?? this.role,
      );

  bool get isOperator => role == 'staff' || role == 'admin';

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'phone': phone,
        'createdAt': createdAt.toIso8601String(),
        'role': role,
        'consents': {
          'termsAndPrivacy': acceptedTos,
          'marketing': acceptedMarketing,
          'portfolioUse': acceptedPortfolioUse,
        },
      };

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'displayName': displayName,
        'phone': phone,
        'createdAt': createdAt.toIso8601String(),
        'role': role,
        'acceptedTos': acceptedTos,
        'acceptedMarketing': acceptedMarketing,
        'acceptedPortfolioUse': acceptedPortfolioUse,
      };

  factory AppUser.fromFirestore(String uid, Map<String, dynamic> data) =>
      AppUser(
        id: uid,
        email: data['email'] as String? ?? '',
        displayName: data['displayName'] as String? ?? '',
        phone: data['phone'] as String?,
        createdAt: DateTime.tryParse(data['createdAt'] as String? ?? '') ??
            DateTime.now(),
        acceptedTos: data['acceptedTos'] as bool? ?? false,
        acceptedMarketing: data['acceptedMarketing'] as bool? ?? false,
        acceptedPortfolioUse: data['acceptedPortfolioUse'] as bool? ?? false,
        role: data['role'] as String? ?? 'customer',
      );
}
