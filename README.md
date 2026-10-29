# Battle of the Soldiers — Godot 4 Android prototype

An offline, low-poly 3D third-person shooter prototype designed for mobile performance.

## Current prototype features
- Third-person player and follow camera
- Touch joystick, fire, jump and sprint buttons
- Keyboard controls for desktop testing
- Raycast shooting and enemy damage
- Six respawning enemy bots and two allied bots
- Simple 3D training arena with cover and buildings
- Health, kill count and saved best-kill record
- GitHub Actions Android APK build workflow

## Build on an Android phone with GitHub Actions
1. Create a new GitHub repository, for example `battle-of-the-soldiers-android`.
2. Upload the contents of this ZIP to the repository root. Upload the files and folders inside the ZIP, not the ZIP file itself.
3. Make sure `.github/workflows/build-android.yml` is present in the repository.
4. Open the repository's **Actions** tab and select **Build Battle of the Soldiers Android APK**.
5. Tap **Run workflow** if it has not started automatically after your upload.
6. When the workflow finishes successfully, open that run and download the `battle-of-the-soldiers-android-apk` artifact.
7. Extract the downloaded artifact ZIP to get `battle-of-the-soldiers.apk`, then install it on your Android phone. Android may ask you to allow installation from that browser or file manager.

## Important build notes
- The GitHub workflow uses Godot 4.3 and the Godot CI image's Android export setup.
- The Android export preset uses the package ID `com.example.battleofthesoldiers`; change it before publishing to Google Play.
- This prototype is not a finished commercial game. It does not yet include online multiplayer, drivable vehicles, prone/slide animations, a full weapon inventory, or seven finished maps.
- For publishing, configure your own release signing key securely using GitHub Secrets; never commit a private keystore or passwords to the repository.

## Desktop controls
- WASD: move
- Shift: sprint
- Space: jump
- F: fire

## Project layout
- `project.godot`: Godot project configuration
- `scenes/Main.tscn`: main scene
- `scenes/Player.tscn`: player scene
- `scenes/Bot.tscn`: bot scene
- `scripts/main.gd`: arena, AI spawning, HUD, score persistence
- `scripts/player.gd`: movement, camera-relative controls, raycast shooting
- `scripts/bot.gd`: enemy/ally AI, attacks, respawn
- `.github/workflows/build-android.yml`: cloud APK build
