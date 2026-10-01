<div align="center">
<h1 align="center"> Locus </h1> 
<h3>Locus is a native macOS app designed to help you lock your focus. Create focused work sessions, reduce distractions, and keep your attention on what matters. Simple, lightweight, and built for deep work — right where you work.
</br></h3>
<img src="https://img.shields.io/badge/Progress-10%25-red"> <img src="https://img.shields.io/badge/Feedback-Welcome-green">
</br>
</br>
<img src="./docs/images/locus-icon.png" width="256px"> 
</div>

## Build & Run
Requires macOS 13+ and the Swift toolchain (Xcode or the Command Line Tools).

```sh
./scripts/build-app.sh   # builds build/Locus.app
open build/Locus.app
```

On first launch, grant Locus Accessibility access in **System Settings → Privacy & Security → Accessibility**. Locus needs it to put windows in full screen and keep them there.

## Usage
1. Click into the app you want to focus on.
2. Click the lock icon in the menu bar. The window goes full screen and a 25-minute countdown starts in the menu bar.
3. Trying to leave (exit full screen, ⌘Tab, ⌘Q, ⌘H, switching Spaces…) brings you back and asks for your unlock password.
4. When the timer ends, the lock is released and you get a notification.

Run the tests with `./scripts/test.sh`.
