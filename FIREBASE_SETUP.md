# Firebase setup for RetailX POS

All mock data has been removed. The app uses **Firebase Auth** + **Cloud Firestore** with real-time listeners.

## 1. Create a Firebase project

1. Open [Firebase Console](https://console.firebase.google.com/).
2. Create a project (or use an existing one).
3. Enable **Authentication → Email/Password**.
4. Create **Firestore Database** (production mode is fine; deploy rules from this repo).

## 2. Register apps & generate config

From the project root:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This creates `lib/firebase_options.dart` for Web, Android, iOS, etc.

## 3. Deploy Firestore rules

```bash
firebase login
firebase init firestore   # select your project, use firestore.rules
firebase deploy --only firestore:rules
```

Or paste `firestore.rules` into the Firebase Console → Firestore → Rules.

## 4. Create the first admin

1. **Authentication → Users → Add user**  
   Email + password for your admin.

2. Copy the user **UID**.

3. **Firestore → Start collection** `users` → document ID = **UID**:

```json
{
  "name": "Admin User",
  "email": "admin@example.com",
  "role": "admin",
  "active": true
}
```

4. Sign in to the app with that email/password.

## 5. Store settings (optional)

On first admin login, the app creates:

`stores/default/settings/main`

You can edit tax, currency, and store name in **Settings**.

## Collections

| Path | Purpose |
|------|---------|
| `users/{uid}` | Profiles & roles |
| `stores/default/settings/main` | Store config + receipt counter |
| `stores/default/products` | Catalog |
| `stores/default/customers` | Customers |
| `stores/default/sales` | Sales (real-time) |
| `stores/default/stock_movements` | Inventory history |
| `stores/default/suppliers` | Suppliers |
| `stores/default/purchases` | Supplier purchases |

## Cashiers

Admins create cashiers in **Settings → Create cashier**.  
Accounts are created in Firebase Auth and profiles in `users/{uid}` with `role: "cashier"`.

## Run

```bash
flutter pub get
flutter run -d chrome
```
