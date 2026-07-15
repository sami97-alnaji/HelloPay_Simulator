# Developer guide

Requirements are Flutter stable, a supported Java 17 Android toolchain, and
Visual Studio desktop C++ tools for Windows builds.

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
flutter run -d windows
flutter run -d emulator-5554
```

Use `docs/local-api.md` for the endpoint contract. New visual flows should call
the controller/engine instead of reproducing domain decisions in widgets. New
network endpoints should be implemented in the dispatcher first and covered by
an actual loopback HTTP test before adding monitor presentation.
