# RUET Cafeteria - Self-Service Ordering

A Flutter Web app for the RUET cafeteria. Students log in with their card ID and
PIN, see the menu with live stock, add items to a cart, and the best offers are
applied automatically. They pay from their card balance and get an itemized
bill. An admin manages the menu, stock, offers and card top-ups.

This repository is the coursework project for the Software Engineering lab. It
is written for teachers and classmates who want to run, review and extend it.

## Features (User Stories)

- **US1 - Login:** a student logs in with card ID and PIN; wrong credentials are rejected.
- **US2 - Menu with stock:** the menu shows every item, its price and the remaining stock.
- **US3 - Cart:** add items to the cart and remove them again; the total updates live.
- **US4 - Best-offer pricing:** the pricing engine always applies the cheapest valid combination:
  combo pack, free tea, coffee pair, and a bill discount where only the bigger
  discount applies (a bill of 100 Tk or more gets 15 Tk off).
- **US5 - Checkout with sold-out items:** if an item sold out during the session,
  the order is shrunk to the available quantity instead of failing.
- **US6 - Low balance:** if the card balance is too low, checkout is refused with
  a clear message and nothing is charged.
- **US7 - Itemized bill:** after paying, the student sees every line item, the
  applied offers and the total paid.
- **US8 - Order history:** students can review their previous orders.
- **US9 - Admin menu and stock:** the admin adds items and updates stock.
- **US10 - Admin offers and top-ups:** the admin enables or disables offers and
  tops up student card balances.

## Tech Stack

- **Flutter Web (Dart)** - UI and client-side domain logic.
- **Supabase (Postgres, auth, RPC)** - database, login and stored procedures.
- **mocktail** - mocks for unit tests.
- **GitHub Actions** - CI runs analyze, tests and coverage on every push and
  pull request to `main`.
- **Selenium WebDriver** - end-to-end system test in `selenium/`.
- **GitHub Projects** - Kanban board that tracks the user stories.

## Project Structure

```text
lib/
  domain/      cart.dart, offers.dart, offer_factory.dart,
               pricing_engine.dart, models.dart, exceptions.dart
  services/    checkout_service.dart
  data/        cafeteria_repository.dart (interface) + Supabase adapter
  ui/          screens (login, menu, cart, bill, admin)
test/          unit and widget tests
tool/          coverage_summary.dart
selenium/      Selenium end-to-end test and screenshot script
.github/       workflows/flutter-test.yml (CI)
```

## How to Run

1. Create `env.json` in the project root. It is git-ignored and must never be committed:

   ```json
   {
     "SUPABASE_URL": "https://<project>.supabase.co",
     "SUPABASE_ANON_KEY": "<anon key>"
   }
   ```

2. Fetch the dependencies and start the app:

   ```bash
   flutter pub get
   flutter run -d chrome --dart-define-from-file=env.json
   ```

Log in with a student card or an admin card that exists in your Supabase
database (demo accounts are shared privately, not in this repository).

## Running the Tests

Unit and widget tests:

```bash
flutter test
```

Coverage report (prints a summary per file):

```bash
flutter test --coverage
dart run tool/coverage_summary.dart
```

Static analysis:

```bash
flutter analyze
```

End-to-end test with Selenium (start the app in another terminal first):

```bash
flutter run -d web-server --web-port 8080 --dart-define-from-file=env.json
cd selenium
npm install
npm test
```

Screenshots of the main screens can be captured with `npm run screenshots`
(set the `ADMIN_ID` and `ADMIN_PIN` environment variables first)
(written to `../screenshots` by default, or to `SHOT_DIR`).

GitHub Actions runs analyze, tests and coverage automatically on every push and
pull request to `main`, so a red check means the branch is not ready.

## Design Patterns

| Pattern  | File | Why |
| -------- | ---- | --- |
| Strategy | `lib/domain/offers.dart` | `OfferStrategy` gives every offer the same interface. Each offer is its own class (`ComboPackOffer`, `FreeTeaOffer`, `CoffeePairOffer`), so offers can be combined and compared without long `if` chains. |
| Factory | `lib/domain/offer_factory.dart` | `OfferFactory` turns offer codes from the database into strategy objects and builds the `PricingEngine`. Offers that are switched off are simply skipped, so the database controls the active offers. |
| Observer | `lib/domain/cart.dart` | `Cart` is a `ChangeNotifier`. Screens listen to it and rebuild when items change, so the UI never keeps a stale copy of the cart. |
| Adapter | `lib/data/supabase_cafeteria_repository.dart` | Adapts the Supabase client API to our `CafeteriaRepository` interface. Services and tests do not depend on Supabase, and tests mock the interface with mocktail. |

## Known Limitations

The discount and best-offer price are calculated in the Flutter app (client
side). A modified client could therefore send a wrong total to the backend.
Future work: move pricing and checkout into a Supabase Edge Function (or a
database function) so the server calculates the final price.

`env.json` holds only the public anon key. Real security relies on Supabase Row
Level Security, so every table must have RLS policies before deployment.

## AI Tools Used

- **Claude Code** - planning, code review and running tests.
- **Claude in Chrome** - checking the live app and its aria-labels.
- **cmd-bridge worker deepseek-v4-flash** - writing parts of the code and docs.

All AI output was reviewed and tested by the student.
