# ingenium_cartographer

&nbsp; &nbsp; &nbsp; This repository contains bash scripts and config files for installing all relevant tools and gathering and processing data for the Wheaton College Tel Shimron lidar project. This branch is built on ROS2 Jazzy Jalisco. As of this writing (June 2026) this branch is NOT complete, and NOT functional.


![Screenshot](blanchard.png)



## Installation Instructions

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

1. Mark the downloaded script as executable by running `chmod +x install.sh`

2. Run the script with the appropriate argument to install a particular set of software packages from this repository. The valid arguments are explained above.

    To set up the dev-jazzy system, you would run

    `./install.sh --dev-jazzy`
    
    These scripts frequently prompt sudo at various stages of the process. This is normal. 

</details>

## Instructions for Gathering and Processing Data

0. Connect your LiDAR Hardware (this is tested with a Velodyne VLP-32C Ultra Puck) and IMU (this is tested with a LORD Microstrain 3DM-GX5-15/3DM-GX5-AR) to the data gathering device. Run `./record_to_bag.sh`. This should procduce a .mcap file in `~/Documents/Data`

    - Optionally, you may include a parameter: `./record_to_bag.sh [Location_Identifier]` where `[Location_Identifier]` is an arbitrary string that will help you remember where you took your data. If you do not use this parameter, the script will prompt you for a "Grid ID", which is the same thing. This identifier will be included in your file path.

1. On the fastest available computer, run `./process_bag.sh /path/to/your/mcap/file.mcap`. 

    [!NOTE] The dependencies for this script are not included in the minimal installation for Raspberry Pi!

    [!WARNING] this script is not yet functional!

## Instructions for Forking this Repository

### Step One: Rename The Current ingenium_cartographer Repository
Rename the current repository to `ingenium_cartographer_<ros version name>` so that the new repository that will be updated and used in the future can have the convenient name ingenium_cartographer that the URLs in install.sh always link to.

### Step Two: Actually Make the Fork of this Repository using the GitHub Website
Make sure to name it ingenium_cartographer.

### Step Three: Change the Settings of the New Repository
Do this using the GitHub website.

The repository won't automatically have the same settings as the repository you forked from. I reccomend making sure that "Issues" is turned on and "Always suggest updating pull request branches" is turned on.

In order to make sure that people can't push changes directly to the main branch, go to “Code and automation” and “Branches” and create a ruleset. Make it Active, let no one bypass it, add a target branch (specifically the default branch), and use the following rules: "Restrict deletions", "Require a pull request before merging", and "Block force pushes".

### Step Four: In the Old Repository, Check for Where the Repository Name "ingenium_cartogarpher" is Used Within the Code
Run these lines within a clone of the old repository, in a bash terminal.

The things that come up will probably include the things in the sections below, but it MIGHT also include other things. Look carefully through the output to make sure you understand what the repository name is doing on each line. If there's anything that would be harmed by an automatic replacement of the old repository name (in this case, `ingenium_cartographer`) with the new repository name (in this case, `ingenium_cartographer_<name of ros version>`), make manual changes to it now so that everything will run smoothly; then add what you learned to this section of the README.

Bash line to find where the repository name is used within the repository: `find . -type f -exec grep -H "<old_repository_name>" {} +` (replacing the stuff within the <> with what it makes sense to).

### Step Five: In the Old Repository, Update the GitHub Links
Within a clone of the old repository, in a bash terminal, make these changes, make a commit, and push (to a branch that branches off of the main branch, as usual).

There are some files that have links to github repositories in them, and these will have to be changed to reflect the new repository. The last time this was done, they were found in four places:
1. README.sh
2. install.sh
3. Default_Apps_Installer.sh
4. RPi_Default_Apps_Installer.sh

They weren't just github.com links, either; there were tinyurl.com links that were used to point to github.com links. You may need to create a link on tinyurl.com that links to the correct GitHub page holding the correct RAW file, and then in the original file you were looking at, replace the old tinyurl link with your new one.

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


