# Errors & Warnings Report — `default_apps_installer_log.txt`

Log reviewed against `Default_Apps_Installer.sh` (referred to in its own terminal output as `DAI.sh`). The run completed end‑to‑end (it reached the final `Rebooting now!` message), but it hit **8 distinct failures** plus several benign warnings along the way.

---

## 1. Failed `apt` package installs (apt_packages loop)

The `for package in "${apt_packages[@]}"; do ... sudo apt install -y "$package"; done` loop (script lines 68–72) installs each package independently, so a single missing package doesn't stop the script — but two packages failed outright:

- **`gdm-settings`** (script line 38)
  > `Error: Unable to locate package gdm-settings`
  This means `gnome-tweaks`-adjacent theming tool wasn't found in the configured apt repositories on this system.

- **`python3.12-venv`** (script line 52)
  > `Error: Unable to locate package python3.12-venv`
  > `Error: Couldn't find any package by glob 'python3.12-venv'`
  The log shows the machine is actually running a much newer Python (`python3.14`, per the apt upgrade list around line 89 of the raw upgrade output), so a Python 3.12-specific venv package doesn't exist in this repo — the package name is stale for whatever Ubuntu release/Python version is now default.

## 2. `ros2-apt-source.deb` failed to install (inside `Install_Jazzy.sh`)

Script line 152 calls `./Install_Jazzy.sh`, a file not included for review, but the log captures the failure it produced while downloading/installing the ROS 2 apt-source package:

> `dpkg-deb: error: unexpected end of file in archive magic version number in /tmp/ros2-apt-source.deb`
> `dpkg: error processing archive /tmp/ros2-apt-source.deb (--install):`
> ` dpkg-deb --control subprocess failed with exit status 2`
> `Errors were encountered while processing:`
> ` /tmp/ros2-apt-source.deb`

The curl download immediately preceding this shows only **9 bytes** transferred (`100 9 100 9 ... `), i.e. `ros2-apt-source.deb` was truncated/empty — the download silently failed but `Install_Jazzy.sh` tried to install it anyway. This is the root cause of the ROS 2 package failures below.

## 3. ROS 2 apt repository never got registered → cascading package failures

Because the `ros2-apt-source.deb` install failed, the ROS 2 apt repository was never added, so every subsequent step that tries to `apt install ros-jazzy-*` or ROS-related pip/apt tooling fails to find those packages. This produced errors in two separate places in the log:

**Inside `Install_Jazzy.sh`:**
> `Error: Unable to locate package ros-jazzy-desktop`
> `E: Unable to locate package ros-jazzy-rosbag2`

(`Install_Jazzy.sh` itself is not available for review, but its own console output labels these steps "Installing ros-jazzy-desktop...", "Installing rosbag2...", "Installing colcon...".)

**Back in `Default_Apps_Installer.sh`, in the "INSTALL ROS-HOSTED APT PACKAGES" section (script lines 166–173):**
- Line 166 — `sudo apt install ros-jazzy-velodyne -y`
  > `Error: Unable to locate package ros-jazzy-velodyne`
- Line 167 — `sudo apt install ros-jazzy-microstrain-inertial-driver -y`
  > `Error: Unable to locate package ros-jazzy-microstrain-inertial-driver`
- Line 170 — `sudo apt install python3-colcon-common-extensions -y`
  > `Error: Unable to locate package python3-colcon-common-extensions`
- Line 171 — `sudo apt install python3-rosdep -y`
  > `Error: Unable to locate package python3-rosdep`

## 4. `rosdep` command not found (direct consequence of #3)

Since `python3-rosdep` never installed, the next two commands fail:
- Script line 172 — `sudo rosdep init`
  > `sudo: 'rosdep': command not found`
- Script line 173 — `rosdep update`
  > `./DAI.sh: line 173: rosdep: command not found`

## 5. `nmcli` command not found

Script line 184 (the network-configuration section, after `get_ethernet_address.sh` prompts the user for their ethernet interface name and successfully captures it as `eth0`):
> `./DAI.sh: line 184: nmcli: command not found`

This means the `network-manager`/`nmcli` package is not installed on this machine (it isn't in the `apt_packages` array in `Default_Apps_Installer.sh`), so the ethernet static-IP configuration for the Velodyne LiDAR (`192.168.1.201`) was never applied.

## 6. GNOME Terminal `gsettings` schema errors

In the "CONFIGURE UI" section (script lines ~204–210), the script queries and sets GNOME Terminal profile colors via `gsettings`:
> `No such schema "org.gnome.Terminal.ProfilesList"`
> `No such schema "org.gnome.Terminal.Legacy.Profile"` *(×3 more, once per subsequent `gsettings set` call)*

This indicates the machine's default terminal app is not GNOME Terminal (or the schema isn't installed), so `UUID=$(gsettings get org.gnome.Terminal.ProfilesList default ...)` (script line ~207) returned nothing usable, and the four dependent `gsettings set ... org.gnome.Terminal.Legacy.Profile:...` calls (script lines ~208–210) all failed for the same reason.

---

## Non-fatal / informational warnings (no action needed)

These appeared repeatedly but did not stop the script or indicate a real problem:

- **`WARNING: apt does not have a stable CLI interface. Use with caution in scripts.`** — printed before nearly every `apt` invocation; this is apt's standard scripting disclaimer, not an error specific to this run.
- **`rehash: warning: skipping ca-certificates.crt, it does not contain exactly one certificate or CRL`** — emitted while `ca-certificates` updated its trust store; harmless.
- **`SyntaxWarning: 'return' in a 'finally' block`** (from `twisted/internet/test/test_posixbase.py`) and a similar `SyntaxWarning` from `vtkmodules/web/testing.py` (`"\." is an invalid escape sequence`) — Python deprecation warnings from third-party packages' own bundled files, not from anything in `Default_Apps_Installer.sh`.
- **`update-alternatives: warning: skip creation of /usr/share/man/man1/f95.1.gz ...`** (and two similar lines for `f77` and `mpiexec`) — missing man-page symlink targets for Fortran/MPI tools that weren't installed; cosmetic only.
- **`snapd.failure.service is a disabled or a static unit not running, not starting it.`** and **`rsync.service is a disabled or a static unit not running, not starting it.`** — normal systemd notices for services that are intentionally inactive by default.
- **`Waiting for cache lock: Could not get lock /var/lib/dpkg/lock-frontend. It is held by process 28903 (apt)...`** — appeared a few times during the large `libpcl-dev`/ROS dependency installs; apt simply retried until the lock freed. Worth noting only because it shows another apt-related process (likely `unattended-upgrades`) was competing for the dpkg lock during the run, which is a common source of intermittent flakiness on a freshly-updated system.

---

## Summary table

| # | Error | Location | Script line(s) |
|---|-------|----------|-----------------|
| 1 | `Unable to locate package gdm-settings` | apt_packages loop | 38 |
| 2 | `Unable to locate package python3.12-venv` (×2 messages) | apt_packages loop | 52 |
| 3 | `dpkg-deb: error: unexpected end of file in archive magic version number in /tmp/ros2-apt-source.deb` (truncated download) | `Install_Jazzy.sh` (external) | 152 (call site) |
| 4 | `Unable to locate package ros-jazzy-desktop` / `ros-jazzy-rosbag2` | `Install_Jazzy.sh` (external) | 152 (call site) |
| 5 | `Unable to locate package ros-jazzy-velodyne` / `ros-jazzy-microstrain-inertial-driver` | ROS-hosted apt packages section | 166, 167 |
| 6 | `Unable to locate package python3-colcon-common-extensions` / `python3-rosdep` | ROS-hosted apt packages section | 170, 171 |
| 7 | `rosdep: command not found` (×2) | Colcon/rosdep section | 172, 173 |
| 8 | `nmcli: command not found` | Ports/IP configuration section | 184 |
| 9 | `No such schema "org.gnome.Terminal.ProfilesList"` / `...Legacy.Profile"` (×4) | Configure UI section | ~207–210 |

Errors 4–7 are all downstream of error 3 (the corrupted `ros2-apt-source.deb` download), so fixing the source of that truncated download should resolve most of the ROS 2-related failures in one pass.
