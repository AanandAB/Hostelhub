/// Subscription rates: monthly, yearly, and per-extra-property (₹).
class Pricing {
  final int monthly;
  final int yearly;
  final int extraProperty;

  const Pricing({
    required this.monthly,
    required this.yearly,
    required this.extraProperty,
  });

  factory Pricing.fromJson(Map<String, dynamic> json) => Pricing(
        monthly: (json['monthly'] as num?)?.toInt() ?? 0,
        yearly: (json['yearly'] as num?)?.toInt() ?? 0,
        extraProperty: (json['extra_property'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'monthly': monthly,
        'yearly': yearly,
        'extra_property': extraProperty,
      };
}

/// Global rates plus per-owner overrides (set from the admin panel).
class PricingConfig {
  final Pricing global;
  final Map<String, Pricing> overrides;

  const PricingConfig({required this.global, this.overrides = const {}});

  /// The rates that actually apply to a given owner.
  Pricing effectiveFor(String ownerId) => overrides[ownerId] ?? global;

  factory PricingConfig.fromJson(Map<String, dynamic> json) => PricingConfig(
        global: Pricing.fromJson(
            (json['global'] as Map<String, dynamic>?) ?? const {}),
        overrides: (json['overrides'] as Map<String, dynamic>? ?? const {})
            .map((k, v) =>
                MapEntry(k, Pricing.fromJson(v as Map<String, dynamic>))),
      );
}
