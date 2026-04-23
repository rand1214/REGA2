class SponserModel {
  final String id;
  final int order;
  final String imageUrl;
  final DateTime validFrom;
  final DateTime validUntil;
  final int displayDuration;

  const SponserModel({
    required this.id,
    required this.order,
    required this.imageUrl,
    required this.validFrom,
    required this.validUntil,
    this.displayDuration = 4,
  });

  // SECURITY: Sponsor validity is enforced server-side in SupabaseService.getActiveSponsors()
  // which filters by valid_from and valid_until timestamps. This prevents users from
  // bypassing sponsor validity by manipulating their device clock.
  // This getter is kept for reference but should not be used for filtering.
  @Deprecated('Use server-side filtering in SupabaseService.getActiveSponsors() instead')
  bool get isValid {
    final now = DateTime.now();
    return now.isAfter(validFrom) && now.isBefore(validUntil);
  }

  factory SponserModel.fromJson(Map<String, dynamic> json) {
    return SponserModel(
      id: json['id'] as String,
      order: json['order'] as int,
      imageUrl: json['image_url'] as String,
      validFrom: DateTime.parse(json['valid_from'] as String),
      validUntil: DateTime.parse(json['valid_until'] as String),
      displayDuration: json['display_duration'] as int? ?? 4,
    );
  }
}
