#!/sbin/ash
#
#	uniFlashScript
#
#	CodRLabworks
#	CodRCA : Christian Arvin
#
#

# scenario this script (installer.sh) is called by init.sh
#
# EXPORTED VARIABLES from update-binary
# export COREDIR     /tmp/core
# export BINARIES    /tmp/core/bin
# export LIBS        /tmp/core/library
# export INSTALLER   /tmp/core/installer.sh
# export ZIP		 This zip file full path directory
# export OUTFD
#

# PRE-INIT (P.I)
# ___________________________________________________________________________________________________________ <- 110 char
#


# INSTALL.SH
#############################
# LOAD INSTALL_INIT			#
#############################
$ColdLog "I: INSTALLER.SH: RUNNING install_init"
install_init || $ColdLog "E: INSTALLER.SH: install_init exited with error $?"

# print header message
# ----------------------------------------------- <- 50 char
#
is_enabled print_header_enabled && {
	print_header;
} || $ColdLog "I: INSTALLER.SH: print_header disabled"


# MOUNT USER SELECTED MOUNTPOINTS
[ -n "$mountpoints" ] && {
	ui_print " - Mounting $mountpoints"
	
	for MOUNT in $mountpoints; do
		remount_mountpoint /$MOUNT rw
	done
} || $ColdLog "I: INSTALLER.SH: No defined mountpoints in user config"

##### PRE-INIT ASLIB VERSION
# ------------------------------------------------------------------- <- 70 char

# ASLIB VERSION CHECK
[ "$aslib_version" -lt "$aslib_req" ] && {
	ui_print "E: ASLIB version mismatch"
	ui_print "I: Loaded   :$aslib_version"
	ui_print "I: Required :$aslib_req"
	abort $E_AVM
}

##### PRE-INIT SDK & DEVICE CHECK
# ------------------------------------------------------------------- <- 70 char

# SDK & DEVICE CHECK
cur_device=$(get_prop ro.product.device);				# GET DEVICE ID
cur_android_version=$(get_prop ro.build.version.sdk);	# GET DEVICE SDK

# DEVICE MATCHING DEVICE
[[ ! -z "$req_device" && "$cur_device" != "$req_device" ]] && {
	ui_print "W: Not a $req_device device device."
	exit 1
}

# DEVICE MATCHING SDK
[ "$req_force" -gt "0" ] && {
	[ -z "$cur_android_version" ] && {
		ui_print "E: Unable to determine SDK"
		abort $E_UAS
	}
	case $req_force in
		1) 	# ENFORCING
			if [ "$cur_android_version" != "$req_android_sdk" ];then
				ui_print "W: Android SDK Mismatch"
				ui_print "I: Current  : $cur_android_version"
				ui_print "I: Required : $req_android_sdk"
				abort $E_SDM
			fi
		;;
		2)	# LESS THAN EQUAL
			if [ "$cur_android_version" -gt "$req_android_sdk" ];then
				ui_print "W: Android SDK Mismatch"
				ui_print "I: Current   : $cur_android_version"
				ui_print "I: Required <= $req_android_sdk"
				abort $E_SDM
			fi
		;;
		3) # GREATER THAN EQUAL
			if [ "$cur_android_version" -lt "$req_android_sdk" ];then
				ui_print "W: Android SDK Mismatch"
				ui_print "I: Current   : $cur_android_version"
				ui_print "I: Required >= $req_android_sdk"
				abort $E_SDM
			fi
		;;
		*) $ColdLog "W: INSTALLER.SH: Unknown req_force value $req_force"
		;;
	esac
}

# INIT
# ___________________________________________________________________________________________________________ <- 110 char
#

# PRE_CHECK
# ----------------------------------------------- <- 50 char
#

pre_check;

# ##########################################################################################
#  EXTRACT SYSTEM & USER FOLDERS
# ##########################################################################################

# EXTRACT SYSTEM FOLDER & USER FOLDERS
is_enabled extract_system || is_enabled extract_folder && {
	ui_print " - Extracting"
}

set_progress 0.10
# AS_EXTRACT
# ----------------------------------------------- <- 50 char
#
is_enabled extract_system && {
	asExtract
}

set_progress 0.25
is_enabled extract_folder && {
	$ColdLog "I: INSTALLER.SH: extracting user folders.."
	[ ! -z "$user_folders" ] && {
		for FOLDERS in $user_folders; do
			$ColdLog "I: INSTALLER.SH: extracting -> $FOLDER"
			extract_zip "$ZIP" "$FOLDER/*" "$SOURCEFS"
		done
	} || $ColdLog "W: INSTALLER.SH: no defined user folders"
}


set_progress 0.30
# CREATE_WIPELIST
# ----------------------------------------------- <- 50 char
#

create_wipelist;

# ##########################################################################################
#  CALCULTE SYSTEM SPACE
# ##########################################################################################

##### INIT CALCULTE SOURCEFS VS SYSTEM FREE plus wipe_list
# ------------------------------------------------------------------- <- 70 char
#
set_progress 0.37
is_enabled calculatespace && {
	ui_print " - Calculating Space"
	wipe_size=0;tmp_size=0;install_size=0;wipe_file_count=0;


	$ColdLog "I: INSTALLER.SH: Calculating system INSTALL_SIZE"
	install_size=$(du -ck $SOURCESYS | tail -n 1 | awk '{ print $1 }')

	$ColdLog "I: INSTALLER.SH: Calculating system WIPE_SIZE"
	for TARGET in $(cat $wipe_list); do
		[ -e /system/$TARGET ] && {
			tmp_size=$(du -ck /system/$TARGET | tail -n 1 | awk '{ print $1 }')
			wipe_size=$(($tmp_size+$wipe_size))
			wipe_file_count=$((++wipe_file_count))
			$ColdLog "D: INSTALLER.SH: SIZE:$(printf "%-8s %s\n" $tmp_size "<- /system/$TARGET")"
		}
	done

	$ColdLog "I: INSTALLER.SH: Total system install size -> $install_size"
	$ColdLog "I: INSTALLER.SH: Total system wipe size    -> $wipe_size"
	$ColdLog "I: INSTALLER.SH: Total system free size    -> $pc_free_sys"

	[ "$install_size" -gt "$(($pc_free_sys + $wipe_size))" ] && {
		ui_print "E: INSTALLER.SH: Install size is to large for free system space."
		exit 1
	} || $ColdLog "I: INSTALLER.SH: Great! system has enough space for installation."
}

# ##########################################################################################
#  WIPE FILES IN WIPE LIST
# ##########################################################################################

set_progress 0.54
# AS_WIPELIST
# ----------------------------------------------- <- 50 char
#

is_enabled exec_wipe_list && {
	ui_print " - Removing Unwanted"
	asWipelist;
}


# INSTALLATION
# ___________________________________________________________________________________________________________ <- 110 char
#

# ##########################################################################################
#  INSTALL SYSTEM FILES FROM SYSTEM FOLDERS
# ##########################################################################################

set_progress 0.61
# AS_INSTALL
# ----------------------------------------------- <- 50 char
#
[ "$install_system" == "1" ] && {
	ui_print " - Installing System"
	asInstall;
}


# POST-INSTALLATION
# ___________________________________________________________________________________________________________ <- 110 char
#

set_progress 0.69
# INSTALL.SH
#############################
# LOAD INSTALL_MAIN			#
#############################
$ColdLog "I: INSTALLER.SH: RUNNING install_main"
install_main || $ColdLog "E: INSTALLER.SH: install_main exited with error $?"


# ##########################################################################################
#  CREATE AND CREATE ADDON.D SCRIPT
# ##########################################################################################

set_progress 0.72
# AS_ADDON
# ----------------------------------------------- <- 50 char
#
is_enabled create_addon_d && {
	ui_print " - Creating Addon Script"
	asAddon $addon_delay
}

# CLEAN-UP
# ___________________________________________________________________________________________________________ <- 110 char
#

set_progress 0.80
# CLEAN FILES
# ----------------------------------------------- <- 50 char
#
( is_enabled extract_system || is_enabled extract_folder ) && {
	ui_print " - Cleaning up"
	rm -rf "$SOURCESYS" || $ColdLog "W: INSTALLER.SH: Errors were found during $SOURCESYS cleaning $?"
	[ -e "$SOURCESYS" ] && {
		$ColdLog "W: INSTALLER.SH: Failed to remove $SOURCESYS"
		$ColdLog "I: INSTALLER.SH: Manually remove it on reboot"
	}
}

set_progress 0.94
# UNMOUNTING SYSTEM
# ----------------------------------------------- <- 50 char
is_mounted /system && {
	ui_print " - Un-mounting system"
	umount /system || $ColdLog "W: INSTALLER.SH: Errors were found during system unmount $?"
}
set_progress 1.0
# DONE
# ----------------------------------------------- <- 50 char
ui_print " - Done"
sleep 3

# POST-SCRIPT
# ___________________________________________________________________________________________________________ <- 110 char
#

# INSTALL.SH
#############################
# LOAD INSTALL_POST			#
#############################
$ColdLog "I: INSTALLER.SH: RUNNING install_post"
install_post || $ColdLog "W: INSTALLER.SH: install_post exited with error $?"