Pull latest main, bump the build number, archive, export, and upload to TestFlight.

Run the ship script:
```bash
/Users/wobbaf/saper/scripts/ship.sh
```

The script will:
1. `git pull origin main`
2. Increment `CURRENT_PROJECT_VERSION` in project.pbxproj
3. `xcodebuild archive` → `xcodebuild -exportArchive` → `xcrun altool --upload-app`
4. Commit and push the build number bump

If any step fails, stop and report the error — do not retry automatically.
After success, tell the user the build number and that it will appear in TestFlight in a few minutes.
