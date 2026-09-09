# Quickshell lock screen

Requires Quickshell 0.3.1, a compositor supporting `ext-session-lock-v1` and idle notifications, systemd-logind, `python-dbus`, and `python-gobject`. `install.sh` includes these Python packages. Arch's `/etc/pam.d/system-local-login` supplies authentication. Other distributions must set `lockPamService` in `Config.qml` to an appropriate installed PAM service. Never use a permissive PAM configuration.

## Controls

- `qs ipc call lockscreen lock` locks immediately. No IPC unlock exists.
- Hyprland and Niri use Super+Alt+L. Launcher → Power → Lock uses the same command.
- `loginctl lock-session` requests locking through logind.
- Enter submits the PAM response. Escape clears the input, never unlocks.
- All monitors receive a real session-lock surface. Passwords stay in QML/PAM memory, never command arguments, files, logs, or IPC.

`Theme.qml` supplies all colors and watches Matugen's existing `colors.json`. The current wallpaper sits behind an opaque-weight tint for readable text. No new Matugen template is needed. UI stays static, with immediate press feedback and no vestibular motion.

## Idle and sleep

`Config.qml` uses seconds:

| Setting | Default |
| --- | --- |
| `lockTimeout` | 300 |
| `lockDisplayOffTimeout` | 600 |
| `lockSuspendTimeout` | 0, disabled |

Zero disables each timer independently. Idle monitors respect compositor idle inhibitors. Display-off supports Hyprland and Niri; input restores displays. Automatic suspend is opt-in and uses `systemctl suspend`, not the old swayidle `suspend-then-hibernate`. Both display-off and automatic suspend wait for the compositor's secure confirmation.

A small Python child bridges logind because this Quickshell version lacks native logind integration. It holds a sleep delay inhibitor, requests locking before suspend, and releases the inhibitor only after the compositor confirms coverage. It also handles lid-triggered sleep and launcher suspend. Resume restores displays. Bridge failure locks the session and retries the bridge every five seconds.

**Sleep delay is bounded by logind's `InhibitDelayMaxSec`. A hung compositor, dead Quickshell process, or forced sleep that ignores inhibitors can defeat lock-before-sleep.** This is not a promise of protection when the lock process is absent. Keep Quickshell running throughout the session.

## First activation and recovery

1. Install dependencies before restarting Quickshell: `sudo pacman -S python-dbus python-gobject`.
2. Save work. Keep a separate authenticated TTY available for recovery.
3. Restart Quickshell while unlocked. Do not run another locker at the same time.
4. Run `qs ipc call lockscreen lock`. Check wrong-password rejection, correct-password unlock, keyboard-only use, and every monitor, including hotplug.
5. Check `loginctl lock-session`, idle lock, display wake, then suspend/resume and lid close. Check `systemd-inhibit --list` for Quickshell's delay inhibitor.
6. Stop any already-running hypridle/swayidle after those checks. Niri no longer starts swayidle. Legacy locker configs and their Matugen templates have been removed. Installed packages are not uninstalled by this change.

**Never kill or restart Quickshell while locked.** Its existing fish reload alias kills the process. A conforming compositor keeps the session locked after the lock process dies, potentially leaving a solid screen. Recovery may require logging into a TTY and terminating the graphical session, which loses unsaved work. Do not edit/reload lock code during authentication.

No live locking or suspend test is run automatically by the coding agent. These actions disrupt the current session and must be tested locally before relying on this replacement.

## Checks

`test-lockscreen.py` runs the production JavaScript handlers in Qt 6 QtTest with mocked PAM, compositor, and process objects. It covers late authentication success during sleep, fresh authentication after resume, compositor readiness, and acknowledgment counts. It never locks the desktop. On Arch, install `qt6-declarative` for `/usr/lib/qt6/bin/qmltestrunner`. Live PAM and compositor checks above remain necessary.

```sh
qmllint -I /usr/lib/qt6/qml config/quickshell/modules/LockScreen.qml config/quickshell/Config.qml config/quickshell/shell.qml
/usr/bin/python3 config/quickshell/scripts/test-lock-session.py
/usr/bin/python3 config/quickshell/scripts/test-lockscreen.py
bash -n install.sh
```
