# KusinaBook

KusinaBook is a Flutter recipe companion for Filipino home cooking. Browse recipes by meal category, check ingredients while cooking, save favorites, rate recipes, and keep a personal shopping list in one place.

## Features

- Browse Filipino recipes by meal category: breakfast (`almusal`), lunch (`tanghalian`), snacks (`merienda`), dinner (`hapunan`), and dessert (`panghimagas`)
- Search and filter recipes by category, difficulty, cooking time, and origin
- View ingredients, directions, servings, estimated cost, cooking time, and recipe notes
- Track ingredient availability and cooking progress
- Add ingredients to a shopping list and mark items as purchased
- Save favorite recipes and record personal ratings
- Add recipe photos from the device
- Persist favorites, ratings, cooking progress, shopping items, and custom recipes locally
- Switch between light and dark themes

## Tech Stack

- Flutter and Dart
- Material 3
- `shared_preferences` for local data persistence
- `image_picker` for recipe images
- `path_provider` for local file storage
- `google_fonts` for typography

## Requirements

- Flutter SDK with Dart `3.12.2` or newer
- Android Studio or Xcode for mobile development
- A connected device or emulator, or a supported desktop/web target

Check your Flutter installation with:

```bash
flutter doctor
```

## Getting Started

Clone the repository and install dependencies:

```bash
git clone https://github.com/23-41792/KusinaBook.git
cd KusinaBook
flutter pub get
```

Run the app on an available device:

```bash
flutter devices
flutter run
```

Run the test suite:

```bash
flutter test
```

Analyze the project for Dart and Flutter issues:

```bash
flutter analyze
```

## Building

Build an Android APK:

```bash
flutter build apk
```

Build for other supported targets with the corresponding Flutter command, for example `flutter build ios`, `flutter build web`, or `flutter build windows`.

## Project Structure

```text
lib/main.dart       Application code and recipe experience
assets/             Recipe, logo, and launcher images
android/            Android project files
ios/                iOS project files
web/                Web project files
linux/              Linux project files
macos/              macOS project files
windows/            Windows project files
test/               Flutter tests
```

Recipe images are grouped under `assets/` by meal category. The asset directories are registered in `pubspec.yaml`.

## Data and Privacy

KusinaBook stores user-created recipes, preferences, favorites, ratings, and cooking or shopping progress locally on the device. The app does not require a server or account for its core features.

When adding a recipe photo, the app uses the device image picker and local file storage. Platform permissions may be requested by Android or iOS when this feature is used.

## Contributing

1. Create a feature branch.
2. Make the change and add or update tests where appropriate.
3. Run `flutter analyze` and `flutter test`.
4. Open a pull request with a clear description of the change.

## License

No license has been specified for this repository yet.
