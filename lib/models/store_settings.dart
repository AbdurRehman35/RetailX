class StoreSettings {
  StoreSettings({
    required this.storeName,
    required this.currencySymbol,
    required this.taxRatePercent,
    required this.receiptFooter,
  });

  String storeName;
  String currencySymbol;
  double taxRatePercent;
  String receiptFooter;

  StoreSettings copyWith({
    String? storeName,
    String? currencySymbol,
    double? taxRatePercent,
    String? receiptFooter,
  }) {
    return StoreSettings(
      storeName: storeName ?? this.storeName,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      taxRatePercent: taxRatePercent ?? this.taxRatePercent,
      receiptFooter: receiptFooter ?? this.receiptFooter,
    );
  }
}
