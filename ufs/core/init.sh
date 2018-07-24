#!/sbin/sh
#
#	uniFlashScript
#
#	CodRLabworks
#	CodRCA : Christian Arvin
#
#

# HEADER DEFAULT MESSAGE
TMH1="TEST"
TMH2="############################"
TMH3="      uniFlashScript        "
TMH4="############################"
TMH5="TEST"

# FUNCTIONS
# ___________________________________________________________________________________________________________ <- 110 char
#

# placeholder functions
install_init(){ $ColdLog "I: INSTALLER.SH: install.sh was not loaded!"; return 0;}

install_main(){ $ColdLog "I: INSTALLER.SH: install.sh was not loaded!"; return 0;}

install_post(){ $ColdLog "I: INSTALLER.SH: install.sh was not loaded!"; return 0;}

abort () { ui_print "$1";exit 1; }

ui_print(){
	echo -n -e "ui_print $1\n" >> /proc/self/fd/$OUTFD
	echo -n -e "ui_print\n"    >> /proc/self/fd/$OUTFD
	echo "$(date "+%H:%M:%S") $1" >> $TMP_LOG
}

ColdLog() {
	echo "$(date "+%H:%M:%S") $1" >> $TMP_LOG
	printf "$1\n"
}

flush_log(){
	ColdLog "I: INIT.SH: Flushing TMP_LOG"
	ColdLog "I: INIT.SH: Flushing DONE!!"
	uFS_TL=/sdcard/logs/.devlogs/flush_$uFS_name.log
	echo $'\n\n\n'"FLUSH LOG $(date)"$'\n' >> $uFS_TL
	cat  "$TMP_LOG"                        >> $uFS_TL
	echo $'\n'"DONE..."$'\n\n'             >> $uFS_TL
}

INIT_TMP_LOG() {
	export TMP_LOG=/sdcard/logs/.devlogs/tmp_log
	# Create Directory
	[ ! -e "$TMP_LOG" ] && {
		install -d /sdcard/logs/.devlogs
		export INIT_TMP_LOG=true
		echo $'\n'"TMP_LOG INIT BY INIT.SH"$'\n' > $TMP_LOG
	}
}

# START TMP_LOG
[ -z "$INIT_TMP_LOG" ] && [ "$INIT_TMP_LOG" != "true" ] && INIT_TMP_LOG;


ColdLog=ColdLog


# INIT
# ___________________________________________________________________________________________________________ <- 110 char
#

# PRINT ESSENTIAL DEF
$ColdLog "D: INIT.SH: listing update-binary variables
COREDIR   -> $COREDIR
BINARIES  -> $BINARIES
LIBS      -> $LIBS
INSTALLER -> $INSTALLER
ZIP       -> $ZIP
OUTFD     -> $OUTFD
OUTFDLNK  -> $(readlink /proc/$$/fd/$OUTFD)"

# CHECK FOR PROPER update_binary DEF.
ERR=0
[ ! -e "$COREDIR" ] && {
	ui_print "W: COREDIR is not properly defined"
	ERR=$((++ERR))
}

[ ! -e "$LIBS" ] && {
	ui_print "W: LIBS is not properly defined"
	ERR=$((++ERR))
}

[ ! -e "$ZIP" ] && {
	ui_print "W: ZIP is not properly defined"
	ERR=$((++ERR))
}

[ "$ERR" -gt "0" ] && {
	ui_print "E: update_binary did not properly define variables"
	exit $ERR
}

# LOAD CONFIGS & LIBRARIES
# ___________________________________________________________________________________________________________ <- 110 char
#

ASLIB_LIBDP=$LIBS
ASLIB=$LIBS/aslib
$ColdLog "I: INIT.SH: LOADING $ASLIB"
command . $ASLIB || {
	ui_print "E: ERROR $E_ANL: aslib is not loadable!!"
	abort $E_ANL
}

# LOAD UFS CONFIGS
CONFLIST="er_code ufsconfig"
CONFGDIR="$COREDIR/config"
for CF in $CONFLIST; do
	command . $CONFGDIR/$CF && LM="LOADED" || LM="UNABLE TO LOAD"
	$ColdLog "I: INIT.SH: LOADING $(printf "%-32s %s\n" "$CF" "$LM")"
done

# LOAD USER CONFIGS
U_CONFLIST="config install.sh "
U_CONFGDIR="$COREDIR/install"
( unzip -o "$ZIP" "install/*" -d "$COREDIR" ) && {
	for CF in $U_CONFLIST; do
		command . $U_CONFGDIR/$CF && LM="LOADED" || LM="UNABLE TO LOAD"
		$ColdLog "I: INIT.SH: LOADING $(printf "%-32s %s\n" "$CF" "$LM")"
	done 
} || ColdLog "W: INIT.SH: UNABLE TO UNZIP USER CONFIGS"

# SETUP ASLIB
alLSet type 	$aslib_log_type        # FLASH TYPE
alLSet level	$aslib_log_level       # SET LEVEL 3
alLSet enable	$aslib_log_enabled     # ENABLE LOGGING
alLInit                                # INIT ASLIB LOGGING

# DEF_CHECK
loc_of_config=$UFSCONFIG
loc_of_aslib=$ASLIB
def_config_check || ui_print "W: Misconfigs Detetected! check logs"

# LOAD INIT.SH
# ___________________________________________________________________________________________________________ <- 110 char
#

# TURN-OVER TO USER QUALIFIED CANDIDATE INSTALLER.SH
USER_INSTALLERSH=$COREDIR/install/installer.sh
CORE_INSTALLERSH=$COREDIR/installer.sh
[ -e $USER_INSTALLERSH ] && {
	$ColdLog "I: INIT.SH: DETECTED USER INSTALLER.SH, HANDING OVER.."
	(
		. $USER_INSTALLERSH "$@"
		flush_log
	)
	INSTL_ERR=$?
	
} || {
	$ColdLog "I: INIT.SH: EXEC $CORE_INSTALLERSH"
	(
		. $CORE_INSTALLERSH "$@"
		flush_log
	)
	INSTL_ERR=$?
}

# HANDLE FLUSH_LOG ON ERROR
[ "$INSTL_ERR" -ne "0" ] && {
	$ColdLog "E: INIT.SH: Error Executing installer.sh, Check /sdcard/logs/.devlogs"
	flush_log
}

# clear list
clear_list;

# EXIT WITH ERRCODE FROM INSTALLER.SH
return "$INSTL_ERR"
