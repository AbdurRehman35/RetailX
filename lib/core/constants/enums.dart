enum UserRole { admin, cashier }

enum PaymentMethod { cash, card, online }

enum StockMovementType { sale, purchase, adjustment, initial }

extension UserRoleLabel on UserRole {
  String get label => switch (this) {
        UserRole.admin => 'Admin',
        UserRole.cashier => 'Cashier',
      };
}

extension PaymentMethodLabel on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.cash => 'Cash',
        PaymentMethod.card => 'Card',
        PaymentMethod.online => 'Online',
      };
}

extension StockMovementTypeLabel on StockMovementType {
  String get label => switch (this) {
        StockMovementType.sale => 'Sale',
        StockMovementType.purchase => 'Purchase',
        StockMovementType.adjustment => 'Adjustment',
        StockMovementType.initial => 'Initial',
      };
}
