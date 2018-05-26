#!/sbin/sh
#	
#	uniFlashScript
#
#	CodRLabworks
#	CodRCA : Christian Arvin
#	


##############################################################
# INIT
##############################################################
#
install_init(){
	# ! DO NOT REMOVE THE RETURN CODE !
	return 0
}

###############################################################
# MAIN
###############################################################
#
install_main() {
	uFS_name="tweakPropB"    		# addon name
	uFS_src_ver=b1.0.4				# Source
	uFS_rev_ver=08.22.2017          # Revision
	
	TMH1="Sub"
	TMH2="*******************************"
	TMH3="          TWEAK-PROP B"
	TMH4="*******************************"
	TMH5="app: $uFS_name"
	TMH6="src: $uFS_src_ver"
	TMH7="rev: $uFS_rev_ver"
	TMH8="#"
	
	export status_failsafe=false
	addon_filename="10-tweakpropB.sh"
	tweakpropB_loc=$COREDIR/install/$addon_filename
	
	tweak_list=
	
	
	backup() {
		if [ "$(dirname $1)" = "/" ];then
			if [ ! -e "$1" ];then
				ui_print "Backup Failed!"
				ex_s "$1 is not mounted or missing"
			fi
		fi
		if [ ! -d $1 ];
			then _target=$1
		else
			_target=$1/"${build##*/}.backup"
		fi
		echo "# Backup of $build created at `date` using tweakprop version $uFS_src_ver" > "$_target" || \
		ex_s "Cannot write to backup file $_target" && \
		(cat "$build" >> "$_target" && ui_print " -$build backed up at $_target.")
	}

	# Modified ex_s (exit_script) with failsafe_backup integration
	ex_s(){
		# restore backup before exit
		[ $status_failsafe -eq "true" ] && failsafe_backup restore
		ui_print "Error: $@"
		abort 1
	}

	# TweakProp Fail-Safe Backup
	failsafe_backup() { # Backup build.prop safely in an event that script error exist
		! is_mounted /tmp rw    && ! remount_mountpoint /tmp rw    && ex_s "Failed to get RW access on /tmp"
		! is_mounted /system rw && ! remount_mountpoint /system rw && ex_S "Failed to get RW access on /system"
		case $1 in
		backup) dd if=$build of=/tmp/build.prop
				[ ! -e "/tmp/build.prop" ] && ex_s "Failed to backup build.prop"
				status_failsafe=true
				;;
		restore)ui_print "  -Restoring Backup"
				[ ! -e "/tmp/build.prop" ] && ex_s "Missing build.prop Backup "
				dd if=/tmp/build.prop of=$build
				set_perm 0 0 0755 $build
				;;
		esac
	}

	# TweakProp Main Script
	tweakprop_me() {
		# personal file's name located anywhere on your internal storage
		name=tweak.prop
		# location of build prop in system
		# build=/system/build.prop
		echo "" >> "$build"
		
		ui_print " - Set write permissions for $build"
		chmod 0666 "$build"

		# search for files called $name and use first occurrence
		ui_print " - Searching personal file"
		tweak=$(find /tmp/* /data/* /sdcard* /storage* /ext* -name $name -type f -follow 2>/dev/null | sed 1q)

		# Abort execution if file is not found or empty
		test -s "$tweak" && ui_print "  # found tweak file -> $tweak" || ex_s "Personal file $name not found or empty"

		# check if original $build should be backed up
		for bak in BACKUP= backup= Backup=;do
			(cat $tweak | grep $bak) && answer=$(sed "s/$bak//p;d" "$tweak")
			[ -z "$answer" ] && answer=false
		done
	
		ui_print "  # backup buildprop -> $answer"
		
		case "$answer" in
		y|Y|yes|Yes|YES|true|True|TRUE)
			# use same directory where tweak.prop was found
			backup "${tweak%/*}/${build##*/}.backup"
			;;
		n|N|no|No|NO|false|FALSE|False)
			;;
		*)
			# check if empty or invalid
			[[ -z "$answer" || ! -d $(dirname "$answer") ]] && \
			ui_print "Warning!: Given path is empty\nparent directory does not exist" || \
			backup "$answer"
			;;
		esac

		ui_print " - Scanning $tweak"
		
		t_count=0
		
		# read only lines matching valid entry pattern (someVAR=someVAL, !someSTR, @someENTR|someSTR, $someVAR=someVAL)
		for line in $(sed -r '/(^#|^ *$|^BACKUP=|^backup=|^Backup=)/d;/(.*=.*|^\!|^\@.*\|.*|^\$.*\|.*)/!d' "$tweak") ;do
			# add list from the loaded tweakprop properties to tweak_list for addon integration
			tweak_list="${tweak_list}"$'\n'"$line";
			
			# remove entry
			if echo "$line" | grep -q '^\!'
			then
				entry=$(echo "${line#?}" | sed -e 's~[\~&]~\\&~g')
				# remove from $build if present
				grep -q "$entry" "$build" && {
					sed "~$entry~d" -i "$build" && {
						ui_print "  -removed \"$entry\"" && t_count=$((++t_count))
					} || alLog "I: error removing $var" 
				}
			# append string
			elif echo "$line" | grep -q '^\@'
			then
				entry=$(echo "${line#?}" | sed -e 's~[\~&]~\\&~g')
				var=$(echo "$entry" | cut -d\| -f1)
				app=$(echo "$entry" | cut -d\| -f2)
				# append string to $var's value if present in $build
				grep -q "$var" "$build" && {
					sed "s~^$var=.*$~&$app~" -i "$build" && {
						ui_print "  -appended \"$app\" to \"$var\"" && t_count=$((++t_count))
					} || alLog "I: error appending $var"
				}
			# change value only iif entry exists
			elif echo "$line" | grep -q '^\$'
			then
				entry=$(echo "${line#?}" | sed -e 's~[\~&]~\\&~g')
				var=$(echo "$entry" | cut -d\| -f1)
				new=$(echo "$entry" | cut -d\| -f2)
				# change $var's value iif $var present in $build
				grep -q "$var=" "$build" && {
					sed "s~^$var=.*$~$var=$new~" -i "$build" && {
						ui_print "  -changed \"$var\" to \"$new\"" && t_count=$((++t_count))
					} || alLog "I: error changing $var" 
				}
			# add or override entry
			else
				var=$(echo "$line" | cut -d= -f1)
				# if variable already present in $build
				if grep -q "$var" "$build"
				then
					# override value in $build if different
					grep -q "$(grep "$var" "$tweak")" "$build" || {
						sed "s~^$var=.*$~$line~" -i "$build" && {
							ui_print "  -overridden \"$var\"" && t_count=$((++t_count))
						} || alLog "I: error overriding $var" 
					}
				# else append entry to $build
				else
					echo "$line" >> "$build" && {
						ui_print "  -added \"$line\""
						t_count=$((++t_count))
					} || alLog "I: error appending $var" 
				fi
			fi
		done
		[ "$t_count" -gt "0" ] && {
			ui_print " - $t_count tweaks successfully applied!"	
		} || ui_print " - No modifications done"
		# trim empty and duplicate lines of $build
		sed '/^ *$/d' -i "$build"
		chmod 0644 "$build" && ui_print " - Original permissions for $build restored"
		return 0
	}
	
	# define build
	build=/system/build.prop
		
	# Create a Failsafe Backup
	failsafe_backup backup
	
	ui_print " - Tweaking props"
	(tweakprop_me) || {
		ui_print " - ERROR Restoring Backup"
		failsafe_backup restore
	} && {

		ui_print " - adding finishing touch"

		# set addon properties
		set_file_prop $tweakpropB_loc addon_name $uFS_name
		set_file_prop $tweakpropB_loc addon_src_ver $uFS_src_ver
		set_file_prop $tweakpropB_loc addon_app_rev $uFS_rev_ver

		# fix the prop list
		tweak_list=$(echo "${tweak_list}" | sort -ur | sed '/^$/d');

		# add prop list to tweakpropB
		for PROP in $tweak_list; do
			sed -i "\:tweak_prop=:a$PROP" $tweakpropB_loc
		done

		# clean-up same name addon.d script
		if [ -e $SYSTEM/addon.d/$addon_filename ]; then
			rm -rf $SYSTEM/addon.d/$addon_filename
		fi

		# copy addon_tweak props to system addon.d
		dd if=$tweakpropB_loc of=/system/addon.d/$addon_filename

		# set permission for addon.d script
		set_perm 0 0 0755 /system/addon.d/$addon_filename
	} 

	# ! DO NOT REMOVE THE RETURN CODE !
	return 0
}

###############################################################
# POST SCRIPTS
###############################################################
# WARNING DO NOT UNMOUNT SYSTEM
install_post() {
	# ! DO NOT REMOVE THE RETURN CODE !
	return 0
}
