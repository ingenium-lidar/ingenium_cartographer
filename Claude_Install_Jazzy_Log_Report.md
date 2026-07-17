# Errors & Warnings Report — `jazzy_installer_log.txt`

Log reviewed against the edited `Install_Jazzy.sh` (referred to in its own terminal output as `IJ.sh`), run standalone this time rather than as a step inside `Default_Apps_Installer.sh`.

**Good news first:** the fix for the previous report's root cause worked. The `curl` call on script line 29 now has `--fail --retry 5 --retry-delay 5 --retry-all-errors --location`, and `ros2-apt-source.deb` downloaded in full this time (**4436 bytes**, log lines 70‑71) instead of the truncated 9‑byte file from before. `sudo dpkg -i /tmp/ros2-apt-source.deb` (line 30) succeeded cleanly (log lines 72‑76). That whole failure chain from the last report is gone.

However, the run surfaced a **new** root-cause failure, plus some issues that look like they may be specific to running Jazzy on this particular Ubuntu release. 6 distinct problems total.

---

## 1. `dpkg` package-conflict during the second `apt upgrade` (new root cause)

Script lines 32‑35 ("Updating apt a second time...") run `sudo apt update && sudo apt upgrade -y` now that the ROS 2 apt repo is registered. This pulls in upgraded `python3-colcon-*` and `python3-catkin-pkg*` packages from `packages.ros.org`, and two of them collide:

> `dpkg: error processing archive /tmp/apt-dpkg-install-0lNTjZ/03-python3-catkin-pkg-modules_1.1.0-2_all.deb (--unpack):`
> ` trying to overwrite '/usr/lib/python3/dist-packages/catkin_pkg/__init__.py', which is also in package python3-catkin-pkg (1.1.0-3)`
> `Errors were encountered while processing:`
> ` /tmp/apt-dpkg-install-0lNTjZ/03-python3-catkin-pkg-modules_1.1.0-2_all.deb`
> `Error: Sub-process /usr/bin/dpkg returned an error code (1)`

`python3-catkin-pkg-modules` and the already-installed `python3-catkin-pkg` both ship `catkin_pkg/__init__.py`, and neither package's metadata declares a `Replaces`/`Breaks` relationship that would let dpkg know it's safe to overwrite. `dpkg` refuses and aborts the unpack, which leaves `python3-catkin-pkg-modules` **not installed** even though `apt` already unpacked most of the other upgraded colcon packages around it (visible in the "Unpacking ... over (...)" lines just above and below the failure, log lines 165‑199).

This one failure is the root cause of everything in sections 2–5 below — it leaves the system's package database in a broken/half-upgraded state for the rest of the script.

## 2. `ros-jazzy-desktop` not found (script line 39)

> `Error: Unable to locate package ros-jazzy-desktop`

## 3. Unmet-dependency errors on every subsequent `apt` step (fallout from #1)

Because `python3-catkin-pkg-modules` never installed, `apt` now reports `python3-catkin-pkg` as broken every time it re-evaluates the package set:

- During "Updating and upgrading apt..." (script line 52):
  > `Unsatisfied dependencies:`
  > ` python3-catkin-pkg : Depends: python3-catkin-pkg-modules (>= 1.1.0) but it is not installed`
  > `Error: Unmet dependencies. Try 'apt --fix-broken install' with no packages (or specify a solution).`

- During "Installing Colcon and rosdep..." (script line 69, `python3-colcon-common-extensions`):
  > `Unsatisfied dependencies:`
  > ` python3-catkin-pkg : Depends: python3-catkin-pkg-modules (>= 1.1.0) but it is not going to be installed`
  > ` python3-colcon-common-extensions : Depends: python3-colcon-powershell but it is not going to be installed`
  > `                                    Recommends: python3-colcon-override-check but it is not going to be installed`
  > `Error: Unmet dependencies. Try 'apt --fix-broken install' with no packages (or specify a solution).`

- Immediately after, on `python3-rosdep` (script line 70):
  > `Unsatisfied dependencies:`
  > ` python3-catkin-pkg : Depends: python3-catkin-pkg-modules (>= 1.1.0) but it is not going to be installed`
  > ` python3-rosdep : Depends: python3-rosdep-modules (>= 0.26.0) but it is not going to be installed`
  > `Error: Unmet dependencies. Try 'apt --fix-broken install' with no packages (or specify a solution).`

None of these three installs actually completed — `apt` refused all of them rather than installing on top of a broken dependency graph.

## 4. `rosdep` command not found (script lines 71–72, direct consequence of #3)

Since `python3-rosdep` never installed:
> `sudo: 'rosdep': command not found` *(from `sudo rosdep init`, script line 71)*
> `./IJ.sh: line 72: rosdep: command not found` *(from `rosdep update`, script line 72)*

## 5. dpkg lock contention caused by the backgrounded `rosbag2` install

Script line 57 now runs:
```
sudo apt-get install -y ros-jazzy-rosbag2 &
```
The trailing `&` backgrounds this install so the script can move on immediately — but nothing later in the script `wait`s for it before running the next `apt`/`sudo` commands (lines 65‑66, "Installing hardware drivers..."). The result is a race: the `ros-jazzy-velodyne` install starts while the backgrounded `rosbag2` install still holds the dpkg lock:

> `Reading package lists...E: Could not get lock /var/lib/dpkg/lock-frontend. It is held by process 3252 (apt)`
> `E: Unable to acquire the dpkg frontend lock (/var/lib/dpkg/lock-frontend), is another process using it?`

No output from the `rosbag2` install itself ever appears distinctly in the log — its stdout/stderr is interleaved with (and effectively swallowed by) the "Installing hardware drivers..." section, so there's no way to tell from this log alone whether `ros-jazzy-rosbag2` succeeded, failed, or is still silently running when the script exits. This is a script bug independent of the dpkg conflict in #1: any `&`-backgrounded `apt` call needs a `wait` (or at least should not be followed by more `apt`/`dpkg` calls) before the script proceeds.

## 6. `ros-jazzy-velodyne` / `ros-jazzy-microstrain-inertial-driver` not found (script lines 65–66)

> `Error: Unable to locate package ros-jazzy-velodyne`
> `Error: Unable to locate package ros-jazzy-microstrain-inertial-driver`

This is worth flagging separately from #2/#3 because the evidence doesn't cleanly point to the dpkg-conflict fallout as the sole cause. The `packages.ros.org` repo for this OS *is* reachable and *does* serve packages — e.g. the `resolute`-flavored `python3-colcon-*`/`python3-catkin-pkg*` packages downloaded and mostly installed successfully from `http://packages.ros.org/ros2/ubuntu resolute/main amd64 Packages` (log lines 85‑87, 128‑148). Pure-Python (`all`-architecture) ROS tooling packages exist for `resolute`, but `ros-jazzy-desktop`, `ros-jazzy-velodyne`, and `ros-jazzy-microstrain-inertial-driver` are architecture-specific metapackages/driver bindings that have to be built per-distribution by the ROS buildfarm. ROS Jazzy officially targets Ubuntu 24.04 ("noble"); this machine is on a release codenamed **"resolute"** (visible throughout the apt output, e.g. log lines 6‑9), which is not Ubuntu 24.04. It's plausible the ROS buildfarm simply hasn't published `ros-jazzy-desktop`/`ros-jazzy-velodyne`/`ros-jazzy-microstrain-inertial-driver` binaries for `resolute` at all, independent of the dpkg breakage — worth confirming directly (e.g. `apt-cache search ros-jazzy-velodyne` or checking https://packages.ros.org/ros2/ubuntu/dists/resolute/main/binary-amd64/Packages) before assuming a fix to #1 will make these installs succeed.

---

## Non-fatal / informational warnings (no action needed)

- **`WARNING: apt does not have a stable CLI interface. Use with caution in scripts.`** — apt's standard scripting disclaimer, printed before nearly every `apt` call.
- **`Get more security updates through Ubuntu Pro with 'esm-apps' enabled: ...`** — an upsell notice, not an error.
- **`(Reading database ... 5% ... 100%)`** progress ticks and the `curl` progress-bar `\r` output — normal terminal progress indicators, not warnings.

---

## Summary table

| # | Error | Location | Script line(s) |
|---|-------|----------|-----------------|
| 1 | `trying to overwrite '/usr/lib/python3/dist-packages/catkin_pkg/__init__.py'` / `dpkg returned an error code (1)` | second `apt upgrade` | 34–35 |
| 2 | `Unable to locate package ros-jazzy-desktop` | ros-jazzy-desktop install | 39 |
| 3 | `Unmet dependencies` (×3, on `apt upgrade`, `python3-colcon-common-extensions`, `python3-rosdep`) | multiple sections | 52, 69, 70 |
| 4 | `rosdep: command not found` (×2) | rosdep init/update | 71, 72 |
| 5 | `Unable to acquire the dpkg frontend lock` | hardware drivers section, racing against backgrounded rosbag2 install | 57 (background job) vs. 65 |
| 6 | `Unable to locate package ros-jazzy-velodyne` / `ros-jazzy-microstrain-inertial-driver` | hardware drivers section | 65, 66 |

Fixed since the last report: the truncated `ros2-apt-source.deb` download (now downloads correctly, script line 29) and the resulting missing ROS 2 apt repository.

Errors 2–4 are fallout from error 1 (the `catkin_pkg` file-conflict), so resolving that conflict — e.g. by running `sudo apt --fix-broken install` first, or forcing the overwrite/removing the stale `python3-catkin-pkg` before the upgrade — should clear most of this chain in one pass. Error 5 is a separate script bug (missing `wait` after the backgrounded `rosbag2` install) that should be fixed regardless. Error 6 may or may not resolve once #1 is fixed — it's worth verifying independently that ROS Jazzy actually publishes binaries for this OS's release codename before re-running.
