## TweakPropB
**Dynamic Build.Prop Tweaker | FLASH INSTALLER**

**Description:**

Dynamically Modifies your android build.prop from your defined tweak.prop files.


## Features
- [x] Searches your tweak.prop files in all defined search locations.
- [x] Backup Your build.prop.
- [x] Restores your original build.prop incase of error.
- [x] Creates a addon.d script for OTA Survival
- [ ] Magisk Integration **still undecided**

## Abstract
The code searches for the first occurance of **`tweak.prop`** file in all pre-defined locations and validates the file.
All valid entries will be applied to your build.prop located in **`/system/build.prop`**.
A Failsafe Backup of your current **`build.prop`** will be copied and stored in **`/tmp`**. This will be restored if an error is encountered.
After all the modifications are applied an **`addon.d script`** will be installed in **`/system/addon.d`**, All of the entries applied will be saved inside this addon.d script and will be auto applied if you upgrade your system.


## Usage
TweakPropB uses [uniFlashScript Template](https://github.com/nivranaitsirhc/uniFlashScript)

Method 1 **`EDIT AND FORGET`** <br/>
* Edit/Add your entries to **`tweak.prop`** from **`/install/tweak.prop`** and install the zip.

Method 2 **`EDIT, BACKUP, AND FORGET`**
* Edit/Add your entries to **`tweak.prop`** from **`/install/tweak.prop`**.
* Remove the **`tweak.prop`** from **`/install/tweak.prop`** and put it anywhere on your internal/sdcard
* Edit the line **`Backup=No`** and change it to **`Yes`**, This will generate a backup of your current **`build.prop`** alongside with your **`tweak.prop`** when this file is read during installtion.
* Install the zip without the tweak.prop.
<br/><br/>

**Tweak.Prop File** 
```
-----------------------------------------------------------------------------------------------
# If you want to backup your build.prop before editing, change Yes or No
# or specify a custom path. Already existing backup files will be overridden.
#

BACKUP=yes                # creates /sdcard/build.prop.backup since tweak.prop resides there
#BACKUP=/foo/bar/foo.bar  # chose your own path

#
# simply add your entries below
#

# set exactly this entry even if it overrides the already existing value
ro.sf.lcd_density=240

# remove every entry containing the string "debug.egl"
!debug.egl

# append the string ",ppp0" to the value string of the variable "mobiledata.interfaces" if it exists
@mobiledata.interfaces|,ppp0

# Override the value of the variable "telephony.lteOnCdmaDevice" to "1" if and only if the entry already exists
$telephony.lteOnCdmaDevice|1
-----------------------------------------------------------------------------------------------
```

## External Sources
This repo inspired from [kl3](https://forum.xda-developers.com/showthread.php?t=2664332) Dynamic automated build.prop editing.
Much of the codes I used are based on his work, and heavely modified to suite my needs.<br/>
Check out his [SourceCode](https://notabug.org/kl3/tweakprop)


<br /> <br />
**CodRLabworks** <br />
**CodR C.A | Christian Arvin** <br/>
**Contact: [Me](mailto:naitsirhc.uriel@gmail.com)**<br />
**Donations: [Paypal](https://paypal.me/caccabo?locale.x=en_US)**<br />
