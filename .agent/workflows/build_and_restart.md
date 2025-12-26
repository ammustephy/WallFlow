---
description: Build Release APK and Restart Backend
---
## Restart Backend
1. **Stop** the currently running backend server in the terminal (Ctrl+C).
2. Navigate to the `BACKEND` directory: `cd BACKEND`
3. Start the server again to apply content limit and CORS changes: `npm run dev`

## Build Release APK
1. Navigate to the root directory: `cd "d:\Flutter Projects\wallflow"`
2. Run the build command: `flutter build apk --release`
3. Locate the APK at: `build/app/outputs/flutter-apk/app-release.apk`
4. Transfer this APK to your testing device.
