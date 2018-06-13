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

ui_print(){
	echo -n -e "ui_print $1\n" >> /proc/self/fd/$OUTFD
	echo -n -e "ui_print\n"    >> /proc/self/fd/$OUTFD
	TMP_LOG="${TMP_LOG}"$'\n'"$(date "+%H:%M:%S") $1"
}

cold_log() {
	TMP_LOG="${TMP_LOG}"$'\n'"$(date "+%H:%M:%S") $1"
	printf "$1\n"
}

flush_log(){
	cold_log "I: INIT.SH: Flushing TMP_LOG"
	cold_log "I: INIT.SH: Flushing DONE!!"
	uFS_TL=/sdcard/logs/devlogs/$uFS_name"_flush.log"
	echo $'\n\n\n'"FLUSH LOG $(date)"$'\n' >> $uFS_TL
	echo "$TMP_LOG"                        >> $uFS_TL
	echo $'\n'"DONE..."$'\n\n'             >> $uFS_TL
}

cold_log=cold_log
[ -z "$TMP_LOG" ] && TMP_LOG="TMP_LOG INIT BY INIT.SH"


# INIT
# ___________________________________________________________________________________________________________ <- 110 char
#

# PRINT ESSENTIAL DEF
$cold_log "D: INIT.SH: listing update-binary variables
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

ASLIB=$LIBS/aslib
$cold_log "I: INIT.SH: LOADING $ASLIB"
(eval . $ASLIB 1>/dev/null) && \
. $ASLIB || {
	ui_print "E: ERROR $E_ANL: aslib is not loadable!!"
	abort $E_ANL
}

# LOAD UFS CONFIGS
ER_CODE=$COREDIR/config/er_code
UFSCONFIG=$COREDIR/config/ufsconfig
for config in $ER_CODE $UFSCONFIG; do
	$cold_log "I: INIT.SH: LOADING $config"
	(eval . $config 1>/dev/null) && \
	. $config  || \
	$cold_log "E: INIT.SH: INTEGRITY UNABLE TO LOAD"
done

# LOAD USER CONFIGS
USERCONFIG=$COREDIR/install/config 
USER_INSTALLSH=$COREDIR/install/install.sh 
( unzip -o "$ZIP" "install/*" -d "$COREDIR" ) && \
for config in $USERCONFIG $USER_INSTALLSH; do
	$cold_log "I: INIT.SH: LOADING $config"
	(eval . $config 1>/dev/null) && \
	. $config  || \
	$cold_log "E: INIT.SH: INTEGRITY UNABLE TO LOAD"
done || \
cold_log "W: INIT.SH: UNABLE TO UNZIP USER CONFIGS"

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
	$cold_log "I: INIT.SH: DETECTED USER INSTALLER.SH, HANDING OVER.."
	(
		. $USER_INSTALLERSH "$@"
		flush_log
	)
	INSTL_ERR=$?
	
} || {
	$cold_log "I: INIT.SH: EXEC $CORE_INSTALLERSH"
	(
		. $CORE_INSTALLERSH "$@"
		flush_log
	)
	INSTL_ERR=$?
}

# HANDLE FLUSH_LOG ON ERROR
[ "$INSTL_ERR" -ne "0" ] && {
	$cold_log "E: INIT.SH: Error Executing installer.sh, Check /sdcard/logs/devlogs"
	flush_log
}
# EXIT WITH ERRCODE FROM INSTALLER.SH
return "$INSTL_ERR"
