# Errors & Warnings in `default_apps_installer_log_ubuntu_24.txt`

The log records one full run of `Default_Apps_Installer.sh` (which in turn calls `Install_Jazzy.sh` and sources `get_ethernet_address.sh`). Below are all the errors and warnings found, in chronological order, with the log line number and the script/line that produced them where that context is available.

## 1. `rehash` warning — malformed CA certificate
**Log line 670:**
> `rehash: warning: skipping ca-certificates.crt,it does not contain exactly one certificate or CRL`

Triggered during the `ca-certificates` package upgrade in the apt update/upgrade step (Default_Apps_Installer.sh, line 18: `sudo apt-get upgrade -y`). Benign — one certificate bundle entry didn't parse cleanly during rehashing.

## 2. `snapd.failure.service` not running
**Log line 701:**
> `snapd.failure.service is a disabled or a static unit not running, not starting it.`

Occurs during the `snapd` package install/upgrade (from the `apt_packages` array, Default_Apps_Installer.sh line 40). Informational — this systemd unit is intentionally disabled by default.

## 3. Python `SyntaxWarning`s in `aptdaemon`
**Log lines 4902–4926** (nine occurrences), e.g.:
> `/usr/lib/python3/dist-packages/aptdaemon/core.py:96: SyntaxWarning: invalid escape sequence '\-'`
> `/usr/lib/python3/dist-packages/aptdaemon/progress.py:57: SyntaxWarning: invalid escape sequence '\['`
> `/usr/lib/python3/dist-packages/aptdaemon/worker/pkworker.py:462: SyntaxWarning: invalid escape sequence '\S'`

These come from system-installed `aptdaemon` Python files (not project code) being byte-compiled during a dependency install. Not related to any Ingenium script — pre-existing upstream Debian packaging issue.

## 4. `ls: cannot access '/etc/NetworkManager/system-connections'`
**Log line 4265:**
> `ls: cannot access '/etc/NetworkManager/system-connections': No such file or directory`

Fires during unpacking of the `network-manager` package (pulled in as a dependency of the `network-manager` apt package listed in Default_Apps_Installer.sh line 32). The directory doesn't exist yet on a fresh install — a package post-install script probing for it before it's created. Harmless.

## 5. `usbmuxd` home directory warning
**Log line 4323:**
> `info: The home dir /var/lib/usbmux you specified can't be accessed: No such file or directory`

Occurs while `usbmuxd` (pulled in transitively, likely via `gnome-tweaks`/`gvfs`) creates its `usbmux` system user. The directory is created immediately afterward by the same postinst script, so this is just an ordering artifact, not a failure.

## 6. `update-alternatives` warnings — missing gfortran man pages
**Log lines 7563 and 7565:**
> `update-alternatives: warning: skip creation of /usr/share/man/man1/f95.1.gz because associated file /usr/share/man/man1/gfortran.1.gz (of link group f95) doesn't exist`
> `update-alternatives: warning: skip creation of /usr/share/man/man1/f77.1.gz because associated file /usr/share/man/man1/gfortran.1.gz (of link group f77) doesn't exist`

From a gfortran-related dependency (likely pulled in by `libpcl-dev` or `cloudcompare`, both in the `apt_packages` array). Cosmetic — no man page for a symlink group that isn't installed.

## 7. `SyntaxWarning` in VTK Python bindings
**Log line 7590:**
> `/usr/lib/python3/dist-packages/vtkmodules/util/vtkMethodParser.py:304: SyntaxWarning: invalid escape sequence '\S'`

Same class of issue as #3, from the VTK library pulled in as a dependency of `cloudcompare` (Default_Apps_Installer.sh line 26). Not a project bug.

## 8. `apt` CLI stability warnings
**Log lines 8104–8246** (repeated ~9 times):
> `WARNING: apt does not have a stable CLI interface. Use with caution in scripts.`

This is apt's standard warning any time `apt` (rather than `apt-get`) is invoked from a script. It appears repeatedly because Default_Apps_Installer.sh's package-install loop:
```bash
for package in "${apt_packages[@]}"; do
    ...
    sudo apt-get install -y "$package" 
done
```
(lines 37–41) and Install_Jazzy.sh both call apt tooling many times. Not a fault, just apt's routine disclaimer.

## 9. Failed network connection: `lidar-puck`
**Log line 11328:**
> `Error: Failed to add 'lidar-puck' connection: Insufficient privileges`

This is the most consequential error in the run. It occurs immediately after `get_ethernet_address.sh` prompts for and reads the ethernet port name (get_ethernet_address.sh, line 15: `read -p "> " ethernet`), when Default_Apps_Installer.sh then runs:
```bash
nmcli connection add type ethernet ifname $ethernet con-name lidar-puck autoconnect yes ipv4.addresses "192.168.1.201" ipv4.method manual
```
(Default_Apps_Installer.sh, line 133). `nmcli` was invoked without sufficient privileges, so **the static IP configuration needed to talk to the Velodyne LiDAR (192.168.1.201/lidar-puck) was never created.** Since `get_ethernet_address.sh` is `source`d rather than run with `sudo`, and the `nmcli` call itself has no `sudo` prefix, this command runs as the invoking user, and on this system that user apparently lacks the NetworkManager polkit permission — likely the root cause.

## 10. GSettings schema errors — Terminal theming
**Log lines 11480–11484:**
> `No such schema "org.gnome.Terminal.ProfilesList"`
> `No such schema "org.gnome.Terminal.Legacy.Profile"` *(×4)*

These come from the "Configure UI" section of Default_Apps_Installer.sh:
```bash
UUID=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$UUID/ use-theme-colors false
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$UUID/ palette "[...]"
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$UUID/ background-color 'rgb(30,30,30)'
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$UUID/ foreground-color 'rgb(208,207,204)'
```
(Default_Apps_Installer.sh, lines 176–180). The `org.gnome.Terminal.ProfilesList` and `org.gnome.Terminal.Legacy.Profile` GSettings schemas aren't registered on this system — most likely because GNOME Terminal (the classic `gnome-terminal` package, which owns these schemas) isn't actually installed; the apt package list only installs `firefox`, `code`, etc., with no explicit `gnome-terminal` entry, so Ubuntu 24.04's default terminal app may be something else (e.g., the new Ptyxis/Console app) that doesn't ship the legacy schema. **As a result, the entire dark-theme/terminal-color customization block silently failed.**

---

## Notes on items *not* flagged as errors
- **`Install_rsasaki_slam.sh`** was intentionally skipped, per Default_Apps_Installer.sh's own commented-out line and loud console notice (log line 14118 / script line ~150), so its absence is expected, not a bug.
- The many `Get:` lines, `Selecting/Unpacking/Setting up` lines, and snap download progress spam are normal apt/snap output, not errors.
- No errors were found in the `git clone` steps, the `chmod` loop, the `VeloView` download/install block, or `Install_Jazzy.sh`'s ROS Jazzy/rosdep install steps — those all completed cleanly in this log.

If you'd like, I can also draft a patch for the `nmcli` privilege issue (line 133) and the GSettings terminal-theming block, since those are the two failures with real functional impact (no LiDAR subnet configured, no dark terminal theme applied).