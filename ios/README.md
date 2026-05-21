# iOS Platform Folder

This folder was missing and needs to be regenerated.

## To regenerate:
```bash
flutter create --platforms=ios --org=com.akeli --project-name=akeli . --overwrite
```

## Manual Setup (if flutter CLI unavailable):
1. Copy iOS folder from a fresh Flutter project
2. Update Bundle ID in `Runner.xcodeproj/project.pbxproj` to `com.akeli.nutrition`
3. Configure signing in Xcode
4. Add required capabilities (Camera, Photo Library, etc.)
