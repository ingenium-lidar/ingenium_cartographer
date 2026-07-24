# ingenium_cartographer

&nbsp; &nbsp; &nbsp; 
This repository contains bash scripts and config files for installing all relevant tools and gathering and processing LiDAR data for the Wheaton College 
Tel Shimron lidar project. This fork is built on ROS2 Jazzy Jalisco. As of this writing (July 2026) this branch correctly installs and integrates all the
necessary tools, though the SLAM stage has yet to produce meaningful output.


![Screenshot](blanchard.png)



## Installation Instructions


### Quickstart

```bash
# Download install.sh
wget https://raw.githubusercontent.com/ingenium-lidar/ingenium_cartographer/refs/heads/main/install.sh
# Give install.sh permission to execute as an application
chmod +x install.sh
# Run install.sh with the appropriate arguments
./install.sh <-p|--package <name>> [-b|--branch <name>] [-h|--help] [-v|--verbose] [-q|--quiet] [-f|--force] [--version] [--omit-gui]
```

Example, including error logging:

`./install.sh -p dev-jazzy -b rfs-10-installer-refactoring -f -v 2>&1 | tee ~/default_apps_installer_log.txt`


### Installer Script Dependencies

Requires bash, wget, getopt, sudo, apt-get (all of these come installed by default on the Ubuntu distros listed below)

`dev-jazzy` requires Ubuntu 24.04 LTS Desktop (when using WSL, the `--omit-gui` option is strongly recommended)

`rpi-jazzy` requires Ubuntu 24.04 LTS Server (only tested on ARM64)

`dev-lyrical` will require Ubuntu 26.04 LTS Desktop 

`rpi-lyrical` will require Ubuntu 24.04 LTS Server 


### Arguments

`<-p|--package <name>>`    Which variant of our system you wish to install. Valid arguments are `dev-jazzy`, `rpi-jazzy`, and `sl`. 
This argument is required. More about these below.

`[-b|--branch <name>]`     Branch of ingenium_cartographer to install. Defaults to `main`, the latest stable branch.

`[-h|--help]`              Prints this help page.

`[-v|--verbose]`           Sets verbosity level to 2 (highest).

`[-q|--quiet]`             Sets verbosity level to 0 (lowest). Overrides -v.

`[-f|--force]`             Skip all prompts that it is possible to skip.

`[--version]`              Print the script version and exit.

`[--omit-gui]`             Applicable to `dev-*` packages only. Causes the installer script to omit all packages which require a graphical user interface. 


### Exit Codes

  0)   Success

  1)   General error

  2)   Invalid argument(s)

  3)   Failed to git switch to the correct branch (fatal)

### System Variants

  #### Currently available:

    * dev-jazzy             Set up a developer/"main" computer compatible with ROS 2 Jazzy Jalisco. Requires Ubuntu 24.04 Desktop. Includes SLAM, VS Code, other GUI tools.
    
    * rpi-jazzy             Set up an ultra-minimal computer compatible with ROS 2 Jazzy Jalisco. Requires Ubuntu 24.04 Server. 
                            Includes only bare-minimum data-acquisition tools. Intended to be run on a Raspberry Pi. 
    
    * sl                    Test the functionality of this installer script without significantly altering your device or directory structure. 

  #### Upcoming:

    * dev-lyrical           Will be the same as dev-jazzy, but updated for compatibility with ROS 2 Lyrical Luth.
    
    * rpi-lyrical           Will be the same as rpi-jazzy, but updated for compatibility with ROS 2 Lyrical Luth.

  #### Deprecated:

  #### No longer available:

    * dev-humble            Deprecated in May 2026, no longer supported since July 2026. 
    
    * slam                  Deprecated in May 2026, no longer supported since July 2026. 

### WARNING!

These installer scripts are fairly destructive of existing data, since they conform the filesystem to match our team's filesystem specification. It is strongly
recommended that you run these scripts only on clean, new installations of Ubuntu.



## Instructions for Gathering and Processing Data

0. Connect your LiDAR Hardware (this is tested with a Velodyne VLP-32C Ultra Puck) and IMU (this is tested with a LORD Microstrain 3DM-GX5-15/3DM-GX5-AR) to the data gathering device. Run `./record.sh`. This should procduce a .mcap file in `~/Documents/Data`

    - Optionally, you may include a parameter: `./record.sh [Location_Identifier]` where `[Location_Identifier]` is an arbitrary string that will help you remember where you took your data. If you do not include this parameter, the script will prompt you for a "Grid ID", which is the same thing. This identifier will be included in your output file path.

1. On the fastest available computer, run `./process.sh /path/to/your/file.mcap`. 

    [!NOTE] The dependencies for this script are not included in the minimal installation for Raspberry Pi!

    [!WARNING] While this script runs without errors, it does not yet produce meaningful output!

<details>

<summary>Instructions for Forking this Repository</summary>

## Instructions for Forking this Repository

### Step One: Rename The Current ingenium_cartographer Repository

Rename the current repository to `ingenium_cartographer_<ros version name>` so that the new repository that will be updated and used in the future can have the convenient name ingenium_cartographer that the URLs in install.sh always link to.

### Step Two: Fork this Repository using the GitHub Website

Make sure to name it ingenium_cartographer.

### Step Three: Change the Settings of the New Repository

Do this using the GitHub website.

The repository won't automatically have the same settings as the repository you forked from. I reccomend making sure that "Issues" is turned on and "Always suggest updating pull request branches" is turned on.

In order to make sure that people can't push changes directly to the main branch, go to “Code and automation” and “Branches” and create a ruleset. Make it Active, let no one bypass it, add a target branch (specifically the default branch), and use the following rules: "Restrict deletions", "Require a pull request before merging", and "Block force pushes".

### Step Four: In the Old Repository, Check for Where the Repository Name "ingenium_cartogarpher" is Used Within the Code

Run these lines within a clone of the old repository, in a bash terminal.

The things that come up will probably include the things in the sections below, but it MIGHT also include other things. Look carefully through the output to make sure you understand what the repository name is doing on each line. If there's anything that would be harmed by an automatic replacement of the old repository name (in this case, `ingenium_cartographer`) with the new repository name (in this case, `ingenium_cartographer_<name of ros version>`), make manual changes to it now so that everything will run smoothly; then add what you learned to this section of the README.

Here is a Bash line to find where the repository name is used within the repository: `find . -type f -exec grep -H "<old_repository_name>" {} +` (replacing the stuff within the <> with what it makes sense to).

### Step Five: In the Old Repository, Update the GitHub Links

Within a clone of the old repository, in a bash terminal, make these changes, make a commit, and push (to a branch that branches off of the main branch, as usual).

There are some files that have links to github repositories in them, and these will have to be changed to reflect the new repository. The last time this was done, they were found in four places:
1. README.sh
2. install.sh
3. Default_Apps_Installer.sh
4. RPi_Default_Apps_Installer.sh

They weren't just github.com links, either; there were tinyurl.com links that were used to point to github.com links. You may need to replace the links that point to tinyurl.com with links that point to the GitHub page holding the correct RAW file.

Replacing these links should be done manually.

### Step Six: In the Old Repository, Update Files that Use the Directory Name ingenium_cartographer So The Code Will Still Work On Future Clones of the Repository
Within a clone of the old repository, in a bash terminal, make these changes, make a commit, and push (to a branch that branches off of the main branch, as usual).

If you rename this repository, you will need to edit some files to match the new repository name (in this case, `ingenium_cartographer_<ros version name>`. The last time this was done, there were two ways the files used the name:
1. When navigating files and folders (so, the cd command and things like it)
2. In comments, when talking about this repository by name

Replacing these worked fine automatically using the following lines of bash below, which I ran from within the new repository (of course, replacing anything in <> with what makes sense):
```bash
grep -rl "<old_repository_name>" . | while read file; do
   sed -i 's/<old_repository_name>/<new_repository_name>/g' "$file"
done
```

### Step Seven: Anywhere Someone Has the Old Repository Cloned On their Computer, Rename the Directory
Step six above will break old clones of the repository once they pull that change, since they cloned the repository before its name changed, and the code is now written under the assumption that the repository has the new name. So, the directory/repository must be renamed on each local device that has this repository. The bash command for this is `mv <old directory name> <new directory name>`, which you run in the directory that is the parent of the repository. So, in this case, `mv ingenium_cartographer ingenium_cartographer_<ros version name>`.

</details>




<details>

<summary>Instructions for Downloading a Single File from GitHub with the Command Line</summary>

## Instructions for Downloading a Single File from GitHub with the Command Line

1. On the GitHub website, navigate to the file you want to download and open the preview

2. On the upper right of the page, select "Raw" and copy the URL

3. On your device, run

`wget -O [new_file_name] https://raw.githubusercontent.com/[my_user_name]/[my_repository]/refs/heads/[my_branch]/[name_of_my_file]`

For example, to download a deprecated version of `RPi_Default_Apps_Installer.sh`, run:

`wget -O RPi_Default_Apps_Installer.sh https://raw.githubusercontent.com/JohannesByle/ingenium_cartographer/refs/heads/jazzy/RPi_Default_Apps_Installer.sh`

</details>






<!-- 
0. Select the variant of this package that you want to install.

    The valid arguments are: 

    - `--dev-jazzy`
    - `--rpi`
    - `--sl`
    - `--help`

    The `--help` option provides more information about the different options. 

    `--dev-jazzy` is intended for use on the Ubuntu 24.04.1 LTS Desktop developer laptop for a LiDAR project. 

    `--rpi` is intended for use on an Ubuntu 24.04.2 LTS Server installation on a Raspberry Pi 3. It exclusively installs the dependencies and packages needed for recording data from the LiDAR puck and IMU. 

    For more details on `--sl`, see the help menu.

    Ommitting a parameter or submitting an invalid parameter is the same as calling `--help`. 


1. Once you have decided which variant you would like to run, insert the relevant argument into the following template:

    `bash <(curl -L tinyurl.com/ingenium-lidar-installer) [arg]`

    For example, to print the help menu without installing anything, I would run

    `bash <(curl -L tinyurl.com/ingenium-lidar-installer) --help` in terminal.

    To install the ROS Jazzy-flavored development environment, I would run 

    `bash <(curl -L tinyurl.com/ingenium-lidar-installer) --dev-jazzy`


<details>

<summary>Alternative Installation Instructions</summary>

## Alternative Installation Instructions

If you'd rather not run a random bash script straight off the web, you can use this method to download and inspect the relevant file before you run it. 

0. Use wget to download `install.sh` from the internet. We provide a tinyurl link to simplify this process. The appropriate command is

    `wget -O install.sh https://tinyurl.com/ingenium-lidar-installer`

    Insert a GitHub Raw link in place of the tinyurl link if you wish to clone from a specific branch.

1. Mark the downloaded script as executable by running `chmod +x install.sh`

2. Run the script with the appropriate argument to install a particular set of software packages from this repository. The valid arguments are explained above.

    To set up the dev-jazzy system, you would run

    `./install.sh -p dev-jazzy`
    
    These scripts frequently prompt sudo at various stages of the process. This is normal. 

</details> -->