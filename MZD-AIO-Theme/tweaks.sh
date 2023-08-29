#!/bin/sh
# tweaks.sh - MZD-AIO-TI Version 2.8.6
# Special thanks to Siutsch for collecting all the tweaks and for the original AIO
# Big Thanks to Modfreakz, khantaena, Xep, ID7, Doog, Diginix, oz_paulb,
# Albuyeh, VIC_BAM85, lmagder, ameridan, anderml1955 & Tristan-cx5
# For more information visit https://mazdatweaks.com
# Enjoy, Trezdog44 - Trevelopment.com
# (C) 2020 Trevor G Martin

# Time
hwclock --hctosys

# AIO Variables
AIO_VER=2.8.6
AIO_DATE=2020.04.04
# Android Auto Headunit App Version
AA_VER=1.13
# Video Player Version
VP_VER=3.7
# Speedometer Version
SPD_VER=6.1
# AIO Tweaks App Version
AIO_TWKS_VER=1.0
# CASDK Version
CASDK_VER=0.0.5
# Variable paths to common locations for better code readability
# additionalApps.json
ADDITIONAL_APPS_JSON="/jci/opera/opera_dir/userjs/additionalApps.json"
# stage_wifi.sh
STAGE_WIFI="/jci/scripts/stage_wifi.sh"
# location of SD card
MZD_APP_SD="/tmp/mnt/sd_nav"
# CASDK Apps location
MZD_APP_DIR="/tmp/mnt/resources/aio/mzd-casdk/apps"
# Install location for native AIO apps
AIO_APP_DIR="/jci/gui/apps"
# New location for backup ".org" files (v70+)
NEW_BKUP_DIR="/tmp/mnt/resources/dev/org_files"

KEEPBKUPS=1
TESTBKUPS=1
SKIPCONFIRM=0
APPS2RESOURCES=0

COLORTHEME=SmoothAzure

NOALBM=0
FULLTITLES=1

NO_BTN_BG=1
NO_NP_BG=1
NO_LIST_BG=1
NO_CALL_BG=1
NO_TEXT_BG=1

UI_STYLE_ELLIPSE=0
UI_STYLE_MINICOINS=1
UI_STYLE_MINIFOCUS=0
UI_STYLE_NOGLOW=0
UI_STYLE_ALTLAYOUT=0
UI_STYLE_MAIN3D=0
UI_STYLE_LABELCOLOR=#ffffff

DATE_FORMAT=2
STATUS_BAR_APP=#49f92e
STATUS_BAR_CLOCK=#f1f1f1
STATUS_BAR_NOTIF=#49f92e
STATUS_BAR_OPACITY=0.5
STATUS_BAR_CTRL="background-image: none;"
SBN_CTRL="background-image: none;"

timestamp()
{
  date +"%D %T"
}
get_cmu_sw_version()
{
  _ver=$(grep "^JCI_SW_VER=" /jci/version.ini | sed 's/^.*_\([^_]*\)\"$/\1/')
  _patch=$(grep "^JCI_SW_VER_PATCH=" /jci/version.ini | sed 's/^.*\"\([^\"]*\)\"$/\1/')
  _flavor=$(grep "^JCI_SW_FLAVOR=" /jci/version.ini | sed 's/^.*_\([^_]*\)\"$/\1/')

  if [ ! -z "${_flavor}" ]; then
    echo "${_ver}${_patch}-${_flavor}"
  else
    echo "${_ver}${_patch}"
  fi
}
get_cmu_ver()
{
  _ver=$(grep "^JCI_SW_VER=" /jci/version.ini | sed 's/^.*_\([^_]*\)\"$/\1/' | cut -d '.' -f 1)
  echo ${_ver}
}
log_message()
{
  echo "$*" 1>&2
  echo "$*" >> "${MYDIR}/AIO_log.txt"
  /bin/fsync "${MYDIR}/AIO_log.txt"
}
aio_info()
{
  if [ $KEEPBKUPS -eq 1 ]
  then
    # echo "$*" 1>&2
    echo "$*" >> "${MYDIR}/AIO_info.json"
    /bin/fsync "${MYDIR}/AIO_info.json"
  fi
}
# CASDK functions
get_casdk_mode()
{
  if [ -e /jci/casdk/casdk.aio ]
  then
    source /jci/casdk/casdk.aio
    CASDK_MODE=1
  else
    _CASDK_VER=0
    CASDK_MODE=0
  fi
}
add_casdk_app()
{
  CASDK_APP=${2}
  if [ ${1} -eq 1 ] && [ -e ${MYDIR}/casdk/apps/app.${CASDK_APP} ]
  then
    sed -i /${CASDK_APP}/d ${MZD_APPS_JS}
    cp -a ${MYDIR}/casdk/apps/app.${CASDK_APP} ${MZD_APP_DIR}
    echo "  \"app.${CASDK_APP}\"," >> ${MZD_APPS_JS}
    show_message "INSTALL ${CASDK_APP} ..."
    CASDK_APP="${CASDK_APP}         "
    log_message "===                 Installed CASDK App: ${CASDK_APP:0:10}                   ==="
  fi
}
remove_casdk_app()
{
  CASDK_APP=${2}
  if [ ${1} -eq 1 ] && grep -Fq ${CASDK_APP} ${MZD_APPS_JS}
  then
    sed -i /${CASDK_APP}/d ${MZD_APPS_JS}
    show_message "UNINSTALL ${CASDK_APP} ..."
    CASDK_APP="${CASDK_APP}         "
    log_message "===                Uninstalled CASDK App: ${CASDK_APP:0:10}                  ==="
  fi
}
# Compatibility check falls into 7 groups:
# 70.00.336+ ($COMPAT_GROUP=7 *Temporary, until tested*)
# 70.00.XXX ($COMPAT_GROUP=6)
# 59.00.5XX ($COMPAT_GROUP=5)
# 59.00.4XX ($COMPAT_GROUP=4)
# 59.00.3XX ($COMPAT_GROUP=3)
# 58.00.XXX ($COMPAT_GROUP=2)
# 55.00.XXX - 56.00.XXX ($COMPAT_GROUP=1)
compatibility_check()
{
  _VER=$(get_cmu_ver)
  _VER_EXT=$(grep "^JCI_SW_VER=" /jci/version.ini | sed 's/^.*_\([^_]*\)\"$/\1/' | cut -d '.' -f 3)
  _VER_MID=$(grep "^JCI_SW_VER=" /jci/version.ini | sed 's/^.*_\([^_]*\)\"$/\1/' | cut -d '.' -f 2)
  if [ $_VER_MID -ne "00" ] # Only development versions have numbers other than '00' in the middle
  then
    echo 0 && return
  fi
  if [ $_VER -eq 55 ] || [ $_VER -eq 56 ]
  then
    echo 1 && return
  elif [ $_VER -eq 58 ]
  then
    echo 2 && return
  elif [ $_VER -eq 59 ]
  then
    if [ $_VER_EXT -lt 400 ] # v59.00.300-400
    then
      echo 3 && return
    elif [ $_VER_EXT -lt 500 ] # v59.00.400-500
    then
      echo 4 && return
    else
      echo 5 && return # 59.00.502+ is another level because it is not compatible with USB Audio Mod
    fi
  elif [ $_VER -eq 70 ]
  then
    if [ $_VER_EXT -le 360 ]
    then
      echo 6 && return # v70.00.352 For Integrity check
    else
      echo 7 && return # Past v70.00.352 is unknown and cannot be trusted
    fi
  else
    echo 0
  fi
}
remove_aio_css()
{
  if grep -Fq "${2}" "${1}"; then
    sed -i "/.. MZD-AIO-TI *${2} *CSS ../,/.. END AIO *${2} *CSS ../d" "${1}"
    INPUT="${1##*/}               "
    log_message "===               Removed CSS From ${INPUT:0:20}               ==="
  fi
}
remove_aio_js()
{
  if grep -Fq "${2}" "${1}"; then
    sed -i "/.. MZD-AIO-TI.${2}.JS ../,/.. END AIO.${2}.JS ../d" "${1}"
    INPUT=${1##*/}
    log_message "===            Removed ${2:0:11} JavaScript From ${INPUT:0:13}    ==="
  fi
}
rootfs_full_message()
{
  show_message "DANGER!! ROOTFS IS 100% FULL!\nRUN FULL SYSTEM RESTORE OR UNINSTALL TWEAKS\nTO RECOVER SPACE AND RELOCATE FILES"
  sleep 15
  log_message "ROOTFS IS 100% FULL - RUN FULL SYSTEM RESTORE TO RECOVER SPACE AND RELOCATE FILES - CHOOSE \"APPS TO RESOURCES\" OPTION WHEN INSTALLING TWEAKS TO AVOID RUNNING OUT OF SPACE"
  show_message_OK "DANGER!! ROOTFS IS 100% FULL!\nCONTINUING THE INSTALLATION COULD BE DANGEROUS!\nCONTINUE?"
  APPS2RESOURCES=1
}
# checks for remaining space
space_check()
{
  DATA_PERSIST=$(df -h | (grep 'data_persist' || echo 0) | awk '{ print $5 " " $1 }')
  _ROOTFS=$(df -h | (grep 'rootfs' || echo 0) | awk '{ print $5 " " $1 }')
  _RESOURCES=$(df -h | (grep 'resources' || echo 0) | awk '{ print $5 " " $1 }')
  USED=$(echo $DATA_PERSIST | awk '{ print $1}' | cut -d'%' -f1  )
  USED_ROOTFS=$(echo $_ROOTFS | awk '{ print $1}' | cut -d'%' -f1  )
  USED_RESOURCES=$(echo $_RESOURCES | awk '{ print $1}' | cut -d'%' -f1  )
  if [ $APPS2RESOURCES -ne 1 ]
  then
    if [ $USED_ROOTFS -gt 94 ]
    then
      log_message "=============== WARNING: ROOT FILESYSTEM OVER ${USED_ROOTFS}% FULL!! ================"
      APPS2RESOURCES=1
      TESTBKUPS=1
      KEEPBKUPS=1
      [ $COMPAT_GROUP -eq 6 ] && v70_integrity_check
    fi
    if [ $APPS2RESOURCES -eq 1 ]
    then
      AIO_APP_DIR="/tmp/mnt/resources/aio/apps"
      [ -e ${AIO_APP_DIR} ] || mkdir -p ${AIO_APP_DIR}
      [ -e ${NEW_BKUP_DIR} ] || mkdir -p ${NEW_BKUP_DIR}
      log_message "================= App Install Location set to resources ================="
    fi
  elif [ $USED_ROOTFS -gt 95 ]
  then
    log_message "======================== rootfs ${USED_ROOTFS}% used ================================"
  fi
  _ROOTFS=$(df -h | (grep 'rootfs' || echo 0) | awk '{ print $5 " " $1 }')
  USED_ROOTFS=$(echo $_ROOTFS | awk '{ print $1}' | cut -d'%' -f1  )
  if [ $USED_ROOTFS -ge 100 ]
  then
    rootfs_full_message
  fi
}
# Make a ".org" backup
# pass the full file path
# If creating backup fails the installation is aborted
backup_org()
{
  space_check
  FILE="${1}"
  BACKUP_FILE="${1}.org"
  FILENAME=$(basename -- "$FILE")
  FEXT="${FILENAME##*.}"
  FNAME="${FILENAME%.*}"
  NEW_BKUP_FILE="${NEW_BKUP_DIR}/${FILENAME}.org"
  # Test backup "before" copy
  if [ $TESTBKUPS -eq 1 ] && [ ! -e "${MYDIR}/bakups/test/${FNAME}_before.${FEXT}" ]
  then
    cp "${FILE}" "${MYDIR}/bakups/test/${FNAME}_before.${FEXT}"
  fi
  # New backup exists, return
  [ -e "${NEW_BKUP_FILE}" ] && return 0
  if [ ! -e "${BACKUP_FILE}" ]
  then
    if [ $COMPAT_GROUP -gt 5 ] && [ $APPS2RESOURCES -eq 1 ]
    then
      # new location for storing .org files for v70+
      [ -e "${NEW_BKUP_DIR}" ] || mkdir -p "${NEW_BKUP_DIR}"
      BACKUP_FILE="${NEW_BKUP_FILE}"
    fi
    cp -a "${FILE}" "${BACKUP_FILE}" && log_message "***\___  Created Backup of ${FILENAME} to ${BACKUP_FILE}  ___/***"
  fi
  # Make sure the backup is not an empty file
  [ ! -s "${BACKUP_FILE}" ] && v70_integrity_check
  # Keep backup copy
  if [ $KEEPBKUPS -eq 1 ] && [ ! -e "${MYDIR}/bakups/${FILENAME}.org" ]
  then
    cp "${BACKUP_FILE}" "${MYDIR}/bakups/"
    aio_info \"${FILENAME}\",
  fi
}
# Restore file from the ".org" backup
# pass the full file path (without ".org")
# return 1 if no ".org" file exists, 0 if it does
restore_org()
{
  FILE="${1}"
  BACKUP_FILE="${1}.org"
  FILENAME=$(basename -- "$FILE")
  FEXT="${FILENAME##*.}"
  FNAME="${FILENAME%.*}"
  NEW_BKUP_FILE="${NEW_BKUP_DIR}/${FILENAME}.org"
  # Test backups "before-restore" copy
  if [ $TESTBKUPS -eq 1 ] && [ ! -e "${MYDIR}/bakups/test/${FNAME}_before-restore.${FEXT}" ]
  then
    cp "${FILE}" "${MYDIR}/bakups/test/${FNAME}_before-restore.${FEXT}"
  fi
  if [ -e "${BACKUP_FILE}" ]
  then
    if [ -s "${BACKUP_FILE}" ]
    then
      cp -a "${BACKUP_FILE}" "${FILE}" && log_message "***+++ Restored ${FILENAME} From Backup ${BACKUP_FILE} +++***"
      if [ $KEEPBKUPS -eq 1 ] && [ ! -e "${MYDIR}/bakups/${FILENAME}.org" ]
      then
        cp "${BACKUP_FILE}" "${MYDIR}/bakups/"
        aio_info \"${FILENAME}\",
      fi
    else
      # backup file is blank so run v70_integrity check
      log_message "!!!*** WARNING: BACKUP FILE ${BACKUP_FILE} WAS BLANK!!! ***!!!"
      v70_integrity_check || return 1
    fi
    return 0
  else
    # new secondary location for storing .org files for v70+
    if [ -s "${NEW_BKUP_FILE}" ]
    then
      cp -a "${NEW_BKUP_FILE}" "${FILE}" && log_message "+++ Restored ${FILENAME} From Backup ${NEW_BKUP_FILE} +++"
      return 0
    fi
    return 1
  fi
}
# v70 integrity check will check all .org files in the /jci folder
# the files are either moved to the new backup location in /resources
# or deleted if a new backup exists or the file is blank
# if the file is blank a fallback file (from v70.00.100) is saved to the new backup location
# NO SYSTEM FILES ARE RESTORED WITH THIS FUNCION ONLY BACKUP ".org" FILES
v70_integrity_check()
{
  # if not v70.00.000 - 100 return
  log_message "*************************************************************************"
  log_message "********************** v70 INTEGRITY CHECK BEGIN ************************"
  if [ $COMPAT_GROUP -ne 6 ] || [ ! -d "${MYDIR}/config_org/v70/" ]
  then
    [ $COMPAT_GROUP -ne 6 ] && log_message "**************************** NOT V70 SKIPPING ***************************" \
    || log_message "*********************** FALBACK FILES UNAVAILABLE ***********************"
    return 1
  fi
  [ -e ${NEW_BKUP_DIR} ] || mkdir -p ${NEW_BKUP_DIR}
  orgs=$(find /jci -type f -name "*.org")
  [ -e /etc/profile.org ] && orgs="${orgs} /etc/profile.org"
  for i in $orgs; do
    ORG_FILE="$i"
    FILENAME=$(basename -- $ORG_FILE)
    [ "${FILENAME}" = "sm.conf.org" ] || [ "${FILENAME}" = "fps.js.org" ] && continue
    FILESIZE=$(stat -c%s $ORG_FILE || echo 0)
    FALLBK="${MYDIR}/config_org/v70/${FILENAME}"
    [ -e ${FALLBK} ] || continue
    FALBKSIZ=$(stat -c%s $FALLBK || echo 0)
    NEWBKUP="${NEW_BKUP_DIR}/${FILENAME}"
    [ -e ${NEWBKUP} ] && NEWSIZE=$(stat -c%s $NEWBKUP) || NEWSIZE=0
    # log_message "${FILENAME}: $FILESIZE, ${FALLBK}: $FALBKSIZ, ${NEWBKUP}: $NEWSIZE"
    sleep 1
    # New backup exists & is different from the jci backup file
    if [ -s "${NEWBKUP}" ] && [ $NEWSIZE -ne $FILESIZE ]
    then
      # New backup different from fallback
      if [ $NEWSIZE -ne $FALBKSIZ ]
      then
        cp -a "${FALLBK}" "${NEWBKUP}"
        log_message "***+++ Restored Backup ${NEWBKUP} From Fallback +++***"
      fi
      # backup exists in new locaion already delete extra bkup
      rm -f $ORG_FILE
      log_message "***--- Backup in New Location ${NEWBKUP}... Removing ${ORG_FILE} ---***"
      # No new backup or same as jci .org and dont match fallback
    elif [ $FILESIZE -ne $FALBKSIZ ]
    then
      # backup is invalid size
      cp -a "${FALLBK}" "${NEWBKUP}" && rm -f "${ORG_FILE}"
      log_message "***+++ Repaired Invalid Backup ${FILENAME} +++***"
    elif [ "${FILENAME}" != "opera.ini.org" ]
    then
      # move backup file to new location (all backups will be moved except opera.ini and sm.conf)
      mv "${ORG_FILE}" "${NEWBKUP}"
      log_message "***+++ Moved Backup ${FILENAME} to New Location ${NEWBKUP} +++***"
    else
      continue
    fi
  done
  log_message "*************************************************************************"
  log_message "$(df -h)"
  log_message "******************* v70 INTEGRITY CHECK COMPLETE ************************"
  log_message "*************************************************************************"
  return 0
}
show_message()
{
  sleep 5
  killall -q jci-dialog
  #	log_message "= POPUP: $* "
  /jci/tools/jci-dialog --info --title="MZD-AIO-TI  v.${AIO_VER}" --text="$*" --no-cancel &
}
show_message_OK()
{
  sleep 4
  killall -q jci-dialog
  #	log_message "= POPUP: $* "
  /jci/tools/jci-dialog --confirm --title="MZD-AIO-TI | CONTINUE INSTALLATION?" --text="$*" --ok-label="YES - GO ON" --cancel-label="NO - ABORT"
  if [ $? != 1 ]
  then
    killall -q jci-dialog
    return
  else
    log_message "************************ INSTALLATION ABORTED ***************************"
    show_message "INSTALLATION ABORTED! PLEASE UNPLUG USB DRIVE"
    sleep 10
    killall -q jci-dialog
    exit 0
  fi
}
# create additionalApps.json file from scratch if the file does not exist
create_app_json()
{
  if [ ! -e ${ADDITIONAL_APPS_JSON} ]
  then
    echo "[" > ${ADDITIONAL_APPS_JSON}
    echo "]" >> ${ADDITIONAL_APPS_JSON}
    chmod 777 ${ADDITIONAL_APPS_JSON}
    log_message "===                   Created additionalApps.json                     ==="
  fi
}
addon_common()
{
  # Copies the content of the addon-common folder
  if [ $APPS2RESOURCES -eq 1 ]
  then
    # symlink to resources
    if [ ! -e /tmp/mnt/resources/aio/addon-common ]
    then
      [ -e /tmp/mnt/resources/aio ] || mkdir /tmp/mnt/resources/aio
      cp -a ${MYDIR}/config/jci/gui/addon-common /tmp/mnt/resources/aio
      chmod 777 -R /tmp/mnt/resources/aio
      log_message "===            Copied addon-common folder to resources                ==="
    fi
    if [ ! -L /jci/gui/addon-common ]
    then
      rm -rf /jci/gui/addon-common
      ln -sf /tmp/mnt/resources/aio/addon-common /jci/gui/addon-common
      log_message "===         Created Symlink to resources for addon-common             ==="
    fi
  else
    if [ -L /jci/gui/addon-common ]
    then
      rm -rf /jci/gui/addon-common
      rm -rf /tmp/mnt/resources/aio/addon-common
      log_message "===         Removed Symlink to resources for addon-common             ==="
    fi
    if [ ! -e /jci/gui/addon-common/websocketd ] || [ ! -e /jci/gui/addon-common/jquery.min.js ]
    then
      cp -a ${MYDIR}/config/jci/gui/addon-common/ /jci/gui/
      chmod 777 -R /jci/gui/addon-common/
      log_message "===                   Copied addon-common folder                      ==="
    fi
  fi
}
info_log()
{
  INFOLOG="${MYDIR}/bakups/info.log"
  rm -f $INFOLOG
  show_version.sh > $INFOLOG
  echo "INFO LOG: ${INFOLOG} $(timestamp)" >> $INFOLOG
  echo "> df -h" >> $INFOLOG
  df -h >> $INFOLOG
  echo "> cat /proc/mounts" >> $INFOLOG
  cat /proc/mounts >> $INFOLOG
  echo "> cat /proc/meminfo" >> $INFOLOG
  cat /proc/meminfo >> $INFOLOG
  echo "> ps" >> $INFOLOG
  ps >> $INFOLOG
  echo "> dmesg" >> $INFOLOG
  dmesg >> $INFOLOG
  # echo "> netstat -a" >> $INFOLOG
  # netstat -a >> $INFOLOG
  # echo "> du -h /jci" >> $INFOLOG
  # du -h /jci >> $INFOLOG
  # echo "> du -h /tmp/mnt/resources" >> $INFOLOG
  # du -h /tmp/mnt/resources >> $INFOLOG
  echo "END INFO LOG: $(timestamp)" >> $INFOLOG
}
# script by vic_bam85
add_app_json()
{
  # check if entry in additionalApps.json still exists, if so nothing is to do
  count=$(grep -c '{ "name": "'"${1}"'"' ${ADDITIONAL_APPS_JSON})
  if [ $count -eq 0 ]
  then
    # try to use node if it exists
    if which node > /dev/null && which add_app_json.js > /dev/null
    then
      add_app_json.js ${ADDITIONAL_APPS_JSON} "${1}" "${2}" "${3}" >> ${MYDIR}/node.log 2>&1
      log_message "===                node add_app_json.js ${2:0:10}                    ==="
    elif [ -e ${MYDIR}/config/bin/node ] && [ -e ${MYDIR}/config/bin/add_app_json.js ]
    then
      ${MYDIR}/config/bin/node ${MYDIR}/config/bin/add_app_json.js ${ADDITIONAL_APPS_JSON} "${1}" "${2}" "${3}" >> ${MYDIR}/node.log 2>&1
      log_message "===   ${MYDIR}/config/bin/node add_app_json.js ${2:0:10}        ==="
    else
      log_message "===  ${2:0:10} not found in additionalApps.json, first installation  ==="
      mv ${ADDITIONAL_APPS_JSON} ${ADDITIONAL_APPS_JSON}.old
      sleep 2
      # delete last line with "]" from additionalApps.json
      grep -v "]" ${ADDITIONAL_APPS_JSON}.old > ${ADDITIONAL_APPS_JSON}
      sleep 2
      cp ${ADDITIONAL_APPS_JSON} "${MYDIR}/bakups/test/additionalApps${1}-2._delete_last_line.json"
      # check, if other entrys exists
      count=$(grep -c '}' ${ADDITIONAL_APPS_JSON})
      if [ $count -ne 0 ]
      then
        # if so, add "," to the end of last line to additionalApps.json
        echo "$(cat ${ADDITIONAL_APPS_JSON})", > ${ADDITIONAL_APPS_JSON}
        sleep 2
        cp ${ADDITIONAL_APPS_JSON} "${MYDIR}/bakups/test/additionalApps${1}-3._add_comma_to_last_line.json"
        log_message "===           Found existing entrys in additionalApps.json            ==="
      fi
      # add app entry and "]" again to last line of additionalApps.json
      log_message "===        Add ${2:0:10} to last line of additionalApps.json         ==="
      echo '  { "name": "'"${1}"'", "label": "'"${2}"'" }' >> ${ADDITIONAL_APPS_JSON}
      sleep 2
      if [ "${3}" != "" ]
      then
        sed -i 's/"label": "'"${2}"'" \}/"label": "'"${2}"'", "preload": "'"${3}"'" \}/g' ${ADDITIONAL_APPS_JSON}
      fi
      cp ${ADDITIONAL_APPS_JSON} "${MYDIR}/bakups/test/additionalApps${1}-4._add_entry_to_last_line.json"
      echo "]" >> ${ADDITIONAL_APPS_JSON}
      sleep 2
      rm -f ${ADDITIONAL_APPS_JSON}.old
    fi
    cp ${ADDITIONAL_APPS_JSON} "${MYDIR}/bakups/test/additionalApps${1}-5._after.json"
    if [ -e /jci/opera/opera_dir/userjs/nativeApps.js ]
    then
      echo "additionalApps = $(cat ${ADDITIONAL_APPS_JSON})" > /jci/opera/opera_dir/userjs/nativeApps.js
      log_message "===                    Updated nativeApps.js                          ==="
    fi
  else
    log_message "===         ${2:0:10} already exists in additionalApps.json          ==="
  fi
}
# script by vic_bam85
remove_app_json()
{
  if which node > /dev/null && which remove_app_json.js > /dev/null
  then
    remove_app_json.js ${ADDITIONAL_APPS_JSON} "${1}" >> ${MYDIR}/node.log 2>&1
    log_message "===              node remove_app_json.js ${1:1:10}                   ==="
  elif [ -e ${MYDIR}/config/bin/node ] && [ -e ${MYDIR}/config/bin/remove_app_json.js ]
  then
    ${MYDIR}/config/bin/node ${MYDIR}/config/bin/remove_app_json.js ${ADDITIONAL_APPS_JSON} "${1}" >> ${MYDIR}/node.log 2>&1
    log_message "===    ${MYDIR}/config/bin/node remove_app_json.js ${1:1:10}    ==="
  else
    # check if app entry in additionalApps.json still exists, if so, then it will be deleted
    count=$(grep -c '{ "name": "'"${1}"'"' ${ADDITIONAL_APPS_JSON})
    if [ "$count" -gt "0" ]
    then
      log_message "====   Remove ${count} entry(s) of ${1:0:10} found in additionalApps.json   ==="
      mv ${ADDITIONAL_APPS_JSON} ${ADDITIONAL_APPS_JSON}.old
      # delete last line with "]" from additionalApps.json
      grep -v "]" ${ADDITIONAL_APPS_JSON}.old > ${ADDITIONAL_APPS_JSON}
      sleep 2
      cp ${ADDITIONAL_APPS_JSON} "${MYDIR}/bakups/test/additionalApps${1}-2._delete_last_line.json"
      # delete all app entrys from additionalApps.json
      sed -i "/${1}/d" ${ADDITIONAL_APPS_JSON}
      sleep 2
      json="$(cat ${ADDITIONAL_APPS_JSON})"
      # check if last sign is comma
      rownend=$(echo -n $json | tail -c 1)
      if [ "$rownend" = "," ]
      then
        # if so, remove "," from back end
        echo ${json%,*} > ${ADDITIONAL_APPS_JSON}
        sleep 2
        log_message "===  Found comma at last line of additionalApps.json and deleted it   ==="
      fi
      cp ${ADDITIONAL_APPS_JSON} "${MYDIR}/bakups/test/additionalApps${1}-3._delete_app_entry.json"
      # add "]" again to last line of additionalApps.json
      echo "]" >> ${ADDITIONAL_APPS_JSON}
      sleep 2
      first=$(head -c 1 ${ADDITIONAL_APPS_JSON})
      if [ "$first" != "[" ]
      then
        sed -i "1s/^/[\n/" ${ADDITIONAL_APPS_JSON}
        log_message "===             Fixed first line of additionalApps.json               ==="
      else
        sed -i "1s/\[/\[\n/" ${ADDITIONAL_APPS_JSON}
      fi
      rm -f ${ADDITIONAL_APPS_JSON}.old
    else
      log_message "===            ${1:1:10} not found in additionalApps.json            ==="
    fi
  fi
  cp ${ADDITIONAL_APPS_JSON} "${MYDIR}/bakups/test/additionalApps${1}-4._after.json"
  if [ -e /jci/opera/opera_dir/userjs/nativeApps.js ]
  then
    echo "additionalApps = $(cat ${ADDITIONAL_APPS_JSON})" > /jci/opera/opera_dir/userjs/nativeApps.js
    log_message "===                    Updated nativeApps.js                          ==="
  fi
}
# disable watchdog and allow write access
echo 1 > /sys/class/gpio/Watchdog\ Disable/value
mount -o rw,remount /

MYDIR=$(dirname "$(readlink -f "$0")")
mount -o rw,remount ${MYDIR}

CMU_VER=$(get_cmu_ver)
CMU_SW_VER=$(get_cmu_sw_version)
COMPAT_GROUP=$(compatibility_check)
get_casdk_mode
info_log

# save logs
mkdir -p "${MYDIR}/bakups/test/"
logfile="${MYDIR}/bakups/AIO_log.log"
if [ -f "${MYDIR}/AIO_log.txt" ]; then
  if [ ! -f "${MYDIR}/bakups/count.txt" ]; then
    echo 0 > "${MYDIR}/bakups/count.txt"
  fi
  logcount=$(cat ${MYDIR}/bakups/count.txt)
  #mv "${MYDIR}/AIO_log.txt" "${MYDIR}/bakups/AIO_log-${logcount}.txt"
  logfile="${MYDIR}/bakups/AIO_log-${logcount}.log"
  echo $(($logcount + 1)) > "${MYDIR}/bakups/count.txt"
  rm -f "${MYDIR}/AIO_log.txt"
fi
rm -f "${MYDIR}/AIO_info.json"
# experimental new log will expose
# all the errors in my scripts ^_^
exec > $logfile 2>&1
log_message "========================================================================="
log_message "=======================   START LOGGING TWEAKS...  ======================"
log_message "======================= AIO v.${AIO_VER}  -  ${AIO_DATE} ======================"
log_message "=$(/jci/scripts/show_version.sh)"
log_message "======================= CMU_SW_VER = ${CMU_SW_VER} ======================"
log_message "=======================  COMPATIBILITY_GROUP  = ${COMPAT_GROUP} ======================="
#log_message "======================== CMU_VER = ${CMU_VER} ====================="
if [ $CASDK_MODE -eq 1 ]; then
  log_message "============================  CASDK MODE  ==============================="
  WELCOME_MSG="====== MZD-AIO-TI ${AIO_VER} ======\n\n===**** CASDK MODE ****===="
else
  log_message ""
  WELCOME_MSG="==== MZD-AIO-TI  ${AIO_VER} ====="
fi
log_message "=======================   MYDIR = ${MYDIR}    ======================"
log_message "==================      DATE = $(timestamp)        ================="

show_message "${WELCOME_MSG}"

aio_info '{"info":{'
aio_info \"CMU_SW_VER\": \"${CMU_SW_VER}\",
aio_info \"AIO_VER\": \"${AIO_VER}\",
aio_info \"USB_PATH\": \"${MYDIR}\",
aio_info \"KEEPBKUPS\": \"${KEEPBKUPS}\"
aio_info '},'
# first test, if copy from MZD to usb drive is working to test correct mount point
cp /jci/sm/sm.conf "${MYDIR}"
if [ -e "${MYDIR}/sm.conf" ]
then
  log_message "===         Copytest to sd card successful, mount point is OK         ==="
  log_message " "
  rm -f "${MYDIR}/sm.conf"
else
  log_message "===     Copytest to sd card not successful, mount point not found!    ==="
  /jci/tools/jci-dialog --title="ERROR!" --text="Mount point not found, have to reboot again" --ok-label='OK' --no-cancel &
  sleep 5
  reboot
fi
if [ $COMPAT_GROUP -eq 0 ] && [ $CMU_VER -lt 55 ]
then
  show_message "PLEASE UPDATE YOUR CMU FW TO VERSION 55 OR HIGHER\nYOUR FIRMWARE VERSION: ${CMU_SW_VER}\n\nUPDATE TO VERSION 55+ TO USE AIO"
  mv ${MYDIR}/tweaks.sh ${MYDIR}/_tweaks.sh
  show_message "INSTALLATION ABORTED REMOVE USB DRIVE NOW" && sleep 5
  log_message "************************* INSTALLATION ABORTED **************************" && reboot
  exit 1
fi

# Compatibility Check
if [ $COMPAT_GROUP -gt 6 ]
then
  sleep 2
  show_message_OK "WARNING! VERSION ${CMU_SW_VER} DETECTED\nAIO COMPATIBILITY HAS ONLY BEEN TESTED UP TO V70.00.352\nIF YOU ARE RUNNING A LATER FW VERSION\n***** USE EXTREME CAUTION!! *****\n***** CONTINUE AT YOUR OWN RISK *****"
elif [ $COMPAT_GROUP -ne 0 ]
then
  if [ $SKIPCONFIRM -eq 1 ]
  then
    show_message "MZD-AIO-TI v.${AIO_VER}\nDetected compatible version ${CMU_SW_VER}\nContinuing Installation..."
    sleep 5
  else
    show_message_OK "MZD-AIO-TI v.${AIO_VER}\nDetected compatible version ${CMU_SW_VER}\n\n To continue installation choose YES\n To abort choose NO"
  fi
  log_message "=======        Detected compatible version ${CMU_SW_VER}          ======="
else
  # Removing the comment (#) from the following line will allow MZD-AIO-TI to run with unknown fw versions ** ONLY MODIFY IF YOU KNOW WHAT YOU ARE DOING **
  # show_message_OK "Detected previously unknown version ${CMU_SW_VER}!\n\n To continue anyway choose YES\n To abort choose NO"
  log_message "Detected previously unknown version ${CMU_SW_VER}!"
  show_message "Sorry, your CMU Version is not compatible with MZD-AIO-TI\nE-mail aio@mazdatweaks.com with your\nCMU version: ${CMU_SW_VER} for more information"
  sleep 10
  show_message "UNPLUG USB DRIVE NOW"
  sleep 15
  killall -q jci-dialog
  # To run unknown FW you need to comment out or remove the following 2 lines
  mount -o ro,remount /
  exit 0
fi
# a window will appear for 4 seconds to show the beginning of installation
show_message "START OF TWEAK INSTALLATION\nMZD-AIO-TI v.${AIO_VER} By: Trezdog44 & Siutsch\n(This and the following message popup windows\n DO NOT have to be confirmed with OK)\nLets Go!"
log_message " "
log_message "======***********    BEGIN PRE-INSTALL OPERATIONS ...    **********======"
mount -o rw,remount /tmp/mnt/resources/
log_message "================== Remounted /tmp/mnt/resources ========================="

# disable watchdogs in /jci/sm/sm.conf to avoid boot loops if something goes wrong
if [ ! -e /jci/sm/sm.conf.org ]
then
  cp -a /jci/sm/sm.conf /jci/sm/sm.conf.org
  log_message "===============  Backup of /jci/sm/sm.conf to sm.conf.org  =============="
else
  log_message "================== Backup of sm.conf.org already there! ================="
fi
if ! grep -Fq 'watchdog_enable="false"' /jci/sm/sm.conf || ! grep -Fq 'args="-u /jci/gui/index.html --noWatchdogs"' /jci/sm/sm.conf
then
  sed -i 's/watchdog_enable="true"/watchdog_enable="false"/g' /jci/sm/sm.conf
  sed -i 's|args="-u /jci/gui/index.html"|args="-u /jci/gui/index.html --noWatchdogs"|g' /jci/sm/sm.conf
  log_message "===============  Watchdog In sm.conf Permanently Disabled! =============="
else
  log_message "=====================  Watchdog Already Disabled! ======================="
fi
if [ ! -s /jci/opera/opera_home/opera.ini ] && [ -e ${MYDIR}/config_org/v70/opera.ini.org ]
then
  cp -a ${MYDIR}/config_org/v70/opera.ini.org /jci/opera/opera_home/opera.ini
  log_message "======********** DANGER opera.ini WAS MISSING!! REPAIRED **********======"
fi
# -- Enable userjs and allow file XMLHttpRequest in /jci/opera/opera_home/opera.ini - backup first - then edit
if [ ! -s /jci/opera/opera_home/opera.ini.org ]
then
  cp -a /jci/opera/opera_home/opera.ini /jci/opera/opera_home/opera.ini.org
  log_message "======== Backup /jci/opera/opera_home/opera.ini to opera.ini.org ========"
else
  # checks to make sure opera.ini is not an empty file
  [ -s /jci/opera/opera_home/opera.ini ] || cp /jci/opera/opera_home/opera.ini.org /jci/opera/opera_home/opera.ini
  log_message "================== Backup of opera.ini already there! ==================="
fi
if ! grep -Fq 'User JavaScript=1' /jci/opera/opera_home/opera.ini
then
  sed -i 's/User JavaScript=0/User JavaScript=1/g' /jci/opera/opera_home/opera.ini
fi
count=$(grep -c "Allow File XMLHttpRequest=" /jci/opera/opera_home/opera.ini)
skip_opera=$(grep -c "Allow File XMLHttpRequest=1" /jci/opera/opera_home/opera.ini)
if [ $skip_opera -eq 0 ]
then
  if [ $count -eq 0 ]
  then
    sed -i '/User JavaScript=.*/a Allow File XMLHttpRequest=1' /jci/opera/opera_home/opera.ini
  else
    sed -i 's/Allow File XMLHttpRequest=.*/Allow File XMLHttpRequest=1/g' /jci/opera/opera_home/opera.ini
  fi
  log_message "============== Enabled Userjs & Allowed File Xmlhttprequest ============="
  log_message "==================  In /jci/opera/opera_home/opera.ini =================="
else
  log_message "============== Userjs & File Xmlhttprequest Already Enabled ============="
fi
if [ -e /jci/opera/opera_dir/userjs/fps.js ]
then
  mv /jci/opera/opera_dir/userjs/fps.js /jci/opera/opera_dir/userjs/fps.js.org
  log_message "======== Moved /jci/opera/opera_dir/userjs/fps.js to fps.js.org ========="
fi

# Fix missing /tmp/mnt/data_persist/dev/bin/ if needed
if [ ! -e /tmp/mnt/data_persist/dev/bin/ ]
then
  mkdir -p /tmp/mnt/data_persist/dev/bin/
  log_message "======== Restored Missing Folder /tmp/mnt/data_persist/dev/bin/ ========="
fi
chmod 777 -R /tmp/mnt/data_persist/dev
if [ -e ${ADDITIONAL_APPS_JSON} ] && grep -Fq ,, ${ADDITIONAL_APPS_JSON}
then
  # remove double commas
  sed -i 's/,,/,/g' ${ADDITIONAL_APPS_JSON}
  log_message "================ Fixed Issue with additionalApps.json ==================="
fi

space_check
log_message "======================= data_persist ${USED}% used ==========================="
log_message "======================== rootfs ${USED_ROOTFS}% used ================================"
log_message "====================== resources ${USED_RESOURCES}% used ==============================="

if [ $USED -ge 80 ]
then
  find /tmp/mnt/data_persist/log/dumps/ -name '*.bz2' | xargs rm -f
  DATA_PERSIST=$(df -h | (grep 'data_persist' || echo 0) | awk '{ print $5 " " $1 }')
  USED=$(echo $DATA_PERSIST | awk '{ print $1}' | cut -d'%' -f1  )
  log_message "========================= Delete Dump Files ============================="
  log_message "======================= data_persist ${USED}% used ==========================="
fi
if [ $APPS2RESOURCES -eq 1 ]
then
  AIO_APP_DIR="/tmp/mnt/resources/aio/apps"
  [ -e ${AIO_APP_DIR} ] || mkdir -p ${AIO_APP_DIR}
  [ -e ${NEW_BKUP_DIR} ] || mkdir -p ${NEW_BKUP_DIR}
  log_message "================= App Install Location set to resources ================="
fi
# start JSON array of backups
if [ $KEEPBKUPS -eq 1 ]
then
  aio_info '"Backups": ['
fi
log_message "=========************ END PRE-INSTALL OPERATIONS ***************========="
log_message " "

#--------------------------------------------------------------------------------------------

uninstall_backgroundRotator()
{
  restore background image and common.css to original
  log_message "======***********    UNINSTALL BACKGROUND ROTATOR ...    **********======"

  # one line uninstall
  sed -i "/.. MZD-AIO-TI CSS ../,/.. END AIO CSS ../d" /jci/gui/common/css/common.css
  log_message "===            Removed MZD-AIO-TI Custom CSS in common.css            ==="

  # Check for leftover code from old bg rotator, if not found moves on.
  if grep -Fq "animation: slide .* infinite" /jci/gui/common/css/common.css
  then
      log_message "===             Leftover code found Restoring common.css              ==="
      if ! (restore_org /jci/gui/common/css/common.css)
      then
          cp -a "${MYDIR}/config_org/BackgroundRotator/jci/gui/common/css/common.css" /jci/gui/common/css
          log_message "===    No backup available. Restored common.css from USB Fallback     ==="
      fi
  fi

  log_message "=====*********** END UNINSTALLATION OF BACKGROUND ROTATOR **********====="
  log_message " "
  Background Tweak should be run after this to restore background Image
}

#--------------------------------------------------------------------------------------------

install_custTheme()
{
show_message "INSTALL CUSTOM INFOTAINMENT THEME ..."
log_message "===******** INSTALL CUSTOM INFOTAINMENT THEME (${COLORTHEME}) ... ********==="

# Copy custom theme images
cp -a ${MYDIR}/config/color-schemes/theme/jci /
log_message "===                     ${COLORTHEME} Theme Applied                       ==="

log_message "=======********** END INSTALLATION OF ${COLORTHEME} THEME ***********========"
log_message " "
}

#---------------------------------------------------------------------------------------------

install_statusTweaks()
{
backup_org /jci/gui/common/controls/StatusBar/css/StatusBarCtrl.css
backup_org /jci/gui/common/controls/Sbn/css/SbnCtrl.css
# Statusbar Color Tweaks
# Trevelopment By: Trezdog44
# The Idea is to add to the end of the CSS file surrounded by a comment
# the uninstall would then just find the commented section and remove it
# No files are replaced and CSS files are safe to modify without fear of system damage
show_message "INSTALL STATUSBAR COLOR TWEAKS ..."
log_message "============****** INSTALL STATUSBAR COLOR TWEAKS ...  ********=========="

# Remove existing MZD-AIO-TI CSS and add new CSS to the end of the file
remove_aio_css /jci/gui/common/controls/StatusBar/css/StatusBarCtrl.css
remove_aio_css /jci/gui/common/controls/Sbn/css/SbnCtrl.css

	cat <<EOT >> /jci/gui/common/controls/StatusBar/css/StatusBarCtrl.css
/* MZD-AIO-TI CSS */
/* Main Statusbar Text Color */
.StatusBarCtrl {
	${STATUS_BAR_CTRL}
	background-color: rgba(40, 40, 45, ${STATUS_BAR_OPACITY}) !important;
	border-bottom: 1px solid #0006a7 !important;
}
/* App Name */
.StatusBarCtrlAppName {
	color: ${STATUS_BAR_APP};
	font-style: italic;
}
/* Clock */
.StatusBarCtrlClock {
	color: ${STATUS_BAR_CLOCK};
	font-style: italic;
    width: 112px !important;
    right: 4px !important;
    text-align: left !important;
}
.StatusBarCtrlIconContainer {
  height: 21px !important;
  margin-right: 128px;
  margin-left: 530px;
}
.StatusBarCtrlIcon {
  margin: 0 0 0 8px !important;
  opacity: 0.8 !important;
}
.StatusBarCtrlDivider {
  background: none !important;
}

/* END AIO CSS */
EOT
	cat <<EOT >> /jci/gui/common/controls/Sbn/css/SbnCtrl.css
/* MZD-AIO-TI CSS */
/* Sbn Status Notification Text Color */
.SbnCtrl,
.SbnCtrl_Style01_Text1,
.SbnCtrl_Style02_Text1,
.SbnCtrl_Style03_Text1,
.SbnCtrl_Style06_Text1 {
	color: ${STATUS_BAR_NOTIF};
	font-style: italic;
}
.SbnCtrl {
	${SBN_CTRL}
}

/* END AIO CSS */
EOT

log_message "===                  CSS Added for Statusbar tweaks                   ==="
log_message " "
}

#--------------------------------------------------------------------------------------------

install_menuTweaks()
{
backup_org /jci/gui/apps/system/controls/MainMenu/css/MainMenuCtrl.css

# MAIN MENU Tweaks
# Trevelopment By: Trezdog44
show_message "INSTALL MAIN MENU TWEAKS ..."
log_message "=======**************  INSTALL MAIN MENU TWEAKS ... **************======="

Remove existing Main Menu CSS and add new CSS to the end of the file
remove_aio_css /jci/gui/apps/system/controls/MainMenu/css/MainMenuCtrl.css MAINMENU

echo "/* MZD-AIO-TI MAINMENU CSS */" >> /jci/gui/apps/system/controls/MainMenu/css/MainMenuCtrl.css

if [ $UI_STYLE_ELLIPSE -eq 1 ]
then
  cat <<EOT >> /jci/gui/apps/system/controls/MainMenu/css/MainMenuCtrl.css
  /* Main Menu Ellipse */
  .MainMenuCtrlEllipse {
    opacity: 0.75;
  }
EOT
  log_message "===                    Removed Main Menu Ellipse                      ==="
fi
if [ $UI_STYLE_ALTLAYOUT -eq 1 ]
then
  cat "${MYDIR}/config/MainMenuTweaks/StarA.css" >> /jci/gui/apps/system/controls/MainMenu/css/MainMenuCtrl.css
  log_message "===         Added CSS for Alternative Main Menu (Star Points)         ==="
elif [ $UI_STYLE_ALTLAYOUT -eq 2 ]
then
  cat "${MYDIR}/config/MainMenuTweaks/StarB.css" >> /jci/gui/apps/system/controls/MainMenu/css/MainMenuCtrl.css
  log_message "===         Added CSS for Alternative Main Menu (Star Points)         ==="
elif [ $UI_STYLE_ALTLAYOUT -eq 3 ]
then
  cat "${MYDIR}/config/MainMenuTweaks/Inverted.css" >> /jci/gui/apps/system/controls/MainMenu/css/MainMenuCtrl.css
  log_message "===           Added CSS for Alternative Main Menu (Inverted)          ==="
elif [ $UI_STYLE_ALTLAYOUT -eq 4 ]
then
  cat "${MYDIR}/config/MainMenuTweaks/FlatLine.css" >> /jci/gui/apps/system/controls/MainMenu/css/MainMenuCtrl.css
  log_message "===          Added CSS for Alternative Main Menu (Flatline)           ==="
fi
if [ $UI_STYLE_MINICOINS -eq 1 ]
then
  cat <<EOT >> /jci/gui/apps/system/controls/MainMenu/css/MainMenuCtrl.css
  /* Small Main Menu Coins */
  .MainMenuCtrlAppDiv,
  .MainMenuCtrlNavDiv,
  .MainMenuCtrlComDiv,
  .MainMenuCtrlSetDiv,
  .MainMenuCtrlEntDiv {
    -o-transform: scale(.5, .5);
    transform: scale(.5, .5);
  }
EOT
log_message "===                     Added CSS for Small Coins                     ==="
fi
if [ $UI_STYLE_MINIFOCUS -eq 1 ]
then
  cat <<EOT >> /jci/gui/apps/system/controls/MainMenu/css/MainMenuCtrl.css
  /* Small Main Menu Coins */
  .MainMenuCtrlAppDiv.MainMenuCtrlCoinFocus,
  .MainMenuCtrlNavDiv.MainMenuCtrlCoinFocus,
  .MainMenuCtrlComDiv.MainMenuCtrlCoinFocus,
  .MainMenuCtrlSetDiv.MainMenuCtrlCoinFocus,
  .MainMenuCtrlEntDiv.MainMenuCtrlCoinFocus {
    -o-transform: scale(.5, .5) translate(0px, -10px);
    transform: scale(.5, .5) translate(0px, -10px);
  }
  .MainMenuCtrl [class*=Highlight] {
    background-size: 60%;
    background-position: center 75%;
  }
EOT
  if [ $UI_STYLE_ALTLAYOUT -eq 1 ]
  then
    cat "${MYDIR}/config/MainMenuTweaks/StarASmallFocused.css" >> /jci/gui/apps/system/controls/MainMenu/css/MainMenuCtrl.css
  elif [ $UI_STYLE_ALTLAYOUT -eq 2 ]
  then
    cat "${MYDIR}/config/MainMenuTweaks/StarBSmallFocused.css" >> /jci/gui/apps/system/controls/MainMenu/css/MainMenuCtrl.css
  elif [ $UI_STYLE_ALTLAYOUT -eq 3 ]
  then
    cat "${MYDIR}/config/MainMenuTweaks/InvertedSmallFocused.css" >> /jci/gui/apps/system/controls/MainMenu/css/MainMenuCtrl.css
  elif [ $UI_STYLE_ALTLAYOUT -eq 4 ]
  then
    cat "${MYDIR}/config/MainMenuTweaks/FlatLineSmallFocused.css" >> /jci/gui/apps/system/controls/MainMenu/css/MainMenuCtrl.css
  else
    cat "${MYDIR}/config/MainMenuTweaks/DefaultSmallFocused.css" >> /jci/gui/apps/system/controls/MainMenu/css/MainMenuCtrl.css
  fi
  log_message "===                  Added CSS for Small Focused Coin                 ==="
fi
if [ $UI_STYLE_MAIN3D -eq 1 ]
then
  cat <<EOT >> /jci/gui/apps/system/controls/MainMenu/css/MainMenuCtrl.css
  /* 3D MAIN MENU TEXT! */
  .MainMenuCtrlIconName.Visible {
    text-shadow: 0 1px 0 #ccc,
    0 2px 0 #c9c9c9,
    0 3px 0 #bbb,
    0 4px 0 #b9b9b9,
    0 5px 0 #aaa,
    0 6px 1px rgba(0,0,0,.1),
    0 0 5px rgba(0,0,0,.1),
    0 1px 3px rgba(0,0,0,.3),
    0 3px 5px rgba(0,0,0,.2),
    0 5px 10px rgba(0,0,0,.25),
    0 10px 10px rgba(0,0,0,.2),
    0 20px 20px rgba(0,0,0,.15);
  }
EOT
  log_message "===                  Added CSS for 3D Main Menu Label                 ==="
elif [ $UI_STYLE_MAIN3D -eq 2 ]
then
  cat <<EOT >> /jci/gui/apps/system/controls/MainMenu/css/MainMenuCtrl.css
  /* HIDE MAIN MENU TEXT! */
  .MainMenuCtrlIconName.Visible {
    display:none!important;
  }
EOT
  log_message "===                 Added CSS for Hide Main Menu Label                ==="
elif [ $UI_STYLE_MAIN3D -eq 3 ]
then
  cat <<EOT >> /jci/gui/apps/system/controls/MainMenu/css/MainMenuCtrl.css
  /* COLORED MAIN MENU TEXT! */
  .MainMenuCtrlIconName.Visible {
    color: ${UI_STYLE_LABELCOLOR};
  }
EOT
  log_message "===                Added CSS for color Main Menu Label                ==="
fi
if [ $UI_STYLE_NOGLOW -eq 1 ]
then
  cat <<EOT >> /jci/gui/apps/system/controls/MainMenu/css/MainMenuCtrl.css
  /* Remove Coin Glow */
  .MainMenuCtrl .Visible:not(.MainMenuCtrlIconName) {
    display:none!important;
  }
EOT
  log_message "===                    Added CSS for Hide Coin Glow                   ==="
fi
echo "/* END AIO MAINMENU CSS */" >> /jci/gui/apps/system/controls/MainMenu/css/MainMenuCtrl.css
log_message "===                     Modified  MainMenuCtrl.css                    ==="

if [ $TESTBKUPS -eq 1 ]
then
  cp /jci/gui/apps/system/controls/MainMenu/css/MainMenuCtrl.css "${MYDIR}/bakups/test/MainMenuCtrl_after.css"
fi

log_message "=====**********   END INSTALLATION OF MAIN MENU TWEAKS    **********====="
log_message " "
}

#--------------------------------------------------------------------------------------------

install_reverseTweaks()
{
# remove safety warning from reverse camera for 12 different countries
show_message "REMOVE SAFETY WARNING FROM REVERSE CAMERA ..."
log_message "===******* INSTALL REMOVE SAFETY WARNING FROM REVERSE CAMERA ... *****==="

# Copy reverse camera safety warning images
cp -a ${MYDIR}/config/safety-warning-reverse-camera/jci/nativegui/images/*.png /jci/nativegui/images/
log_message "===               Reverse Camera Safety Warning Removed               ==="

log_message "==*** END INSTALLATION OF REMOVE SAFETY WARNING FROM REVERSE CAMERA ***=="
log_message " "

# semi-transparent parking sensor graphics for the proximity sensors
show_message "INSTALL SEMI-TRANSPARENT PARKING SENSOR GRAPHICS ..."
log_message "====****** INSTALL SEMI-TRANSPARENT PARKING SENSOR GRAPHICS ... *****===="

Copy parking sensor images
cp -a ${MYDIR}/config/transparent-parking-sensor/jci/nativegui/images/HorizontalSensors/*  /jci/nativegui/images/HorizontalSensors/
log_message "===        Copied /jci/nativegui/images/HorizontalSensors/*.png       ==="
cp -a ${MYDIR}/config/transparent-parking-sensor/jci/nativegui/images/VerticalSensors/*  /jci/nativegui/images/VerticalSensors/
log_message "===         Copied /jci/nativegui/images/VerticalSensors/*.png        ==="
cp -a ${MYDIR}/config/transparent-parking-sensor/jci/nativegui/images/MiniView/*  /jci/nativegui/images/MiniView/
log_message "===            Copied /jci/nativegui/images/MiniView/*.png            ==="

log_message "===*** END INSTALLATION OF SEMITRANSPARENT PARKING SENSOR GRAPHICS ***==="
log_message " "
}

#--------------------------------------------------------------------------------------------

install_menuLoop()
{
backup_org /jci/gui/apps/system/controls/MainMenu/js/MainMenuCtrl.js

# main menu loop
show_message "INSTALL MAIN_MENU_LOOP ..."
log_message "=====*****************  INSTALL MAIN_MENU_LOOP ... *****************====="

if [ $COMPAT_GROUP -le 6 ]
then
	# Copy modified MainMenuCtrl.js
	cp -a "${MYDIR}/config/main-menu-loop/jci/gui/apps/system/controls/MainMenu/js/MainMenuCtrl.js" /jci/gui/apps/system/controls/MainMenu/js/
	log_message "=== Copied /jci/gui/apps/system/controls/MainMenu/js/MainMenuCtrl.js  ==="
fi

log_message "=======******       END INSTALLATION OF MAIN_MENU_LOOP      ******======="
log_message " "

backup_org /jci/gui/common/controls/List2/js/List2Ctrl.js

# list_loop_mod
show_message "INSTALL LIST_LOOP_MOD ..."
log_message "=========************** INSTALL LIST_LOOP_MOD ... *************=========="

SHORTER_DELAY_MOD=0
if grep -Fq "Shorter Delay Mod" /jci/gui/common/controls/List2/js/List2Ctrl.js
then
  SHORTER_DELAY_MOD=1
fi

# NO MORE COMPATIBILITY CHECK NEEDED - UNIVERSAL COMPATIBILITY FROM v55 - v70.00.100
# v70.00.100+ will not install mod/needs verification of compatibility
if [ $COMPAT_GROUP -le 6 ]
then
  cp -a "${MYDIR}/config/list-loop/jci/gui/common/controls/List2/js/List2Ctrl.js" /jci/gui/common/controls/List2/js/
  log_message "===                       Copied List2Ctrl.js                         ==="
else
  log_message "===         No Compatible List2Ctrl.js found for ${CMU_SW_VER}        ==="
  log_message "===          E-mail aio@mazdatweaks.com for Compatibility Check       ==="
fi

if [ $SHORTER_DELAY_MOD -eq 1 ]
then
  sed -i 's/autoscrollTier1Timeout :                1500,/autoscrollTier1Timeout :                150,/g' /jci/gui/common/controls/List2/js/List2Ctrl.js
  sed -i 's/autoscrollTier2Timeout :                5000,/autoscrollTier2Timeout :                300,/g' /jci/gui/common/controls/List2/js/List2Ctrl.js
  sed -i 's/autoscrollTier1Interval :               500,/autoscrollTier1Interval :               200,/g' /jci/gui/common/controls/List2/js/List2Ctrl.js
  sed -i 's/autoscrollTier2Interval :               1000,/autoscrollTier2Interval :               300,/g' /jci/gui/common/controls/List2/js/List2Ctrl.js
  sed -i '/autoscrollTier2Interval :               300,/ a\        \/\/Shorter Delay Mod' /jci/gui/common/controls/List2/js/List2Ctrl.js
  log_message "===                  Modified Delay in List2Ctrl.js                   ==="
fi

log_message "=======************ END INSTALLATION OF LIST_LOOP_MOD ************======="
log_message " "
}

#--------------------------------------------------------------------------------------------

install_noMoreDisclaimer()
{
backup_org /jci/gui/apps/system/js/systemApp.js

# no-more-disclaimer
log_message "========***********    INSTALL NO-MORE-DISCLAIMER ... ***********========"

TRACKORDER_DISCLAIMER=2
# Compatibility Check
if [ $COMPAT_GROUP -eq 1 ]
then
  TRACKORDER_DISCLAIMER=0
elif [ $COMPAT_GROUP -ge 2 ] && [ $COMPAT_GROUP -le 5 ]
then
  TRACKORDER_DISCLAIMER=1
  TRACKORDER_DISCLAIMER_FILE=59
  log_message "===       FW ${CMU_SW_VER} detected, copy matching systemApp.js       ==="
elif [ $COMPAT_GROUP -eq 6 ]
then
  TRACKORDER_DISCLAIMER=1
  TRACKORDER_DISCLAIMER_FILE=70
  log_message "===       FW ${CMU_SW_VER} detected, copy matching systemApp.js       ==="
elif [ $COMPAT_GROUP -gt 6 ]
then
  killall -q jci-dialog
  /jci/tools/jci-dialog --confirm --title="NO MORE DISCLAIMER TWEAK" --text="YOUR FW VERSION IS ${CMU_SW_VER}\nNO MORE DISCLAIMER TWEAK HAS ONLY\n BEEN TESTED UP TO V70.00.335\n\n***** INSTALL AT YOUR OWN RISK! *****" --ok-label="INSTALL" --cancel-label="SKIP"
  TRACKORDER_DISCLAIMER=$(($?+1))
  TRACKORDER_DISCLAIMER_FILE=70
fi
[ $TRACKORDER_DISCLAIMER -le 1 ] && show_message "REMOVE DISCLAIMER ..."

# Compatibility check falls into 3 groups:
# 70.00.XXX ($COMPAT_GROUP=6)
# 58.00.XXX - 59.00.XXX ($COMPAT_GROUP=2-5)
# 55.XX.XXX - 56.XX.XXX ($COMPAT_GROUP=1)
if [ $TRACKORDER_DISCLAIMER -ne 2 ]
then
  cp -a "${MYDIR}/config/audio_order_AND_no_More_Disclaimer/systemApp.js.disclaimer" /jci/gui/apps/system/js/
  log_message "===               Added marker 'systemApp.js.disclaimer'              ==="

  if [ -e /jci/gui/apps/system/js/systemApp.js.audio ] && grep -q "^var aaAudioPos" /jci/gui/apps/system/js/systemApp.js.audio
  then
    if [ $TRACKORDER_DISCLAIMER -eq 1 ]
    then
      #cp -a "${MYDIR}/config/audio_order_AND_no_More_Disclaimer/both/jci/gui/apps/system/js/systemApp.${TRACKORDER_DISCLAIMER_FILE}.js" /jci/gui/apps/system/js/systemApp.js
      cat /jci/gui/apps/system/js/systemApp.js.audio  "${MYDIR}/config/audio_order_AND_no_More_Disclaimer/both/jci/gui/apps/system/js/systemApp.${TRACKORDER_DISCLAIMER_FILE}.js" > /jci/gui/apps/system/js/systemApp.js
      log_message "=== Removed Disclaimer for ${CMU_SW_VER}, audio order still changed ==="
    else
      #cp -a "${MYDIR}/config/audio_order_AND_no_More_Disclaimer/both/jci/gui/apps/system/js/systemApp.js" /jci/gui/apps/system/js/
      cat /jci/gui/apps/system/js/systemApp.js.audio "${MYDIR}/config/audio_order_AND_no_More_Disclaimer/both/jci/gui/apps/system/js/systemApp.js" > /jci/gui/apps/system/js/systemApp.js
      log_message "===           Removed Disclaimer, audio order still changed           ==="
    fi
  else
    if [ $TRACKORDER_DISCLAIMER -eq 1 ]
    then
      cp -a "${MYDIR}/config/audio_order_AND_no_More_Disclaimer/only_no_More_Disclaimer/jci/gui/apps/system/js/systemApp.${TRACKORDER_DISCLAIMER_FILE}.js" /jci/gui/apps/system/js/systemApp.js
      log_message "=== Removed Disclaimer ${CMU_SW_VER} (audio order change not installed) ==="
    else
      cp -a "${MYDIR}/config/audio_order_AND_no_More_Disclaimer/only_no_More_Disclaimer/jci/gui/apps/system/js/systemApp.js" /jci/gui/apps/system/js/
      log_message "===      Removed Disclaimer (audio order change was not installed)    ==="
    fi
  fi
else
  show_message "=== NO MORE DISCLIMER PATCH INSTALLATION SKIPPED  ==="
  log_message "**********          Remove Disclaimer Mod Skipped           *************"
  cp /jci/gui/apps/system/js/systemApp.js "${MYDIR}"
fi
if [ $TESTBKUPS -eq 1 ]
then
  cp /jci/gui/apps/system/js/systemApp.js "${MYDIR}/bakups/test/systemApp_after-disclaimer.js"
fi

log_message "=====*********** END INSTALLATION OF NO-MORE-DISCLAIMER ***********======"
log_message " "
}

#--------------------------------------------------------------------------------------------

install_sourceList()
{
backup_org /jci/gui/apps/system/js/systemApp.js

# change order of the audio source list
log_message "======****** INSTALL CHANGE ORDER OF AUDIO SOURCE LIST ... *******======="
TRACKORDER_AUDIO=2
# Compatibility Check
if [ $COMPAT_GROUP -eq 1 ]
then
  TRACKORDER_AUDIO=0
elif [ $COMPAT_GROUP -ge 2 ] && [ $COMPAT_GROUP -le 5 ]
then
  TRACKORDER_AUDIO=1
  TRACKORDER_AUDIO_FILE=59
  log_message "===       FW ${CMU_SW_VER} detected, copy matching systemApp.js       ==="
elif [ $COMPAT_GROUP -eq 6 ]
then
  TRACKORDER_AUDIO=1
  TRACKORDER_AUDIO_FILE=70
  log_message "===       FW ${CMU_SW_VER} detected, copy matching systemApp.js       ==="
elif [ $COMPAT_GROUP -gt 6 ]
then
  killall -q jci-dialog
  /jci/tools/jci-dialog --confirm --title="ORDER OF AUDIO SOURCES TWEAK" --text="YOUR FW VERSION IS ${CMU_SW_VER}\nORDER OF AUDIO SOURCES TWEAK HAS ONLY\n BEEN TESTED UP TO V70.00.335\n\n***** INSTALL AT YOUR OWN RISK! *****" --ok-label="INSTALL" --cancel-label="SKIP"
  TRACKORDER_AUDIO=$(($?+1))
  TRACKORDER_AUDIO_FILE=70
fi
[ $TRACKORDER_AUDIO -le 1 ] && show_message "CHANGE ORDER OF AUDIO SOURCE LIST ..."

# Compatibility check falls into 3 groups:
# 70.00.XXX ($COMPAT_GROUP=6)
# 58.00.XXX - 59.00.XXX ($COMPAT_GROUP=2-5)
# 55.XX.XXX - 56.XX.XXX ($COMPAT_GROUP=1)
if [ $TRACKORDER_AUDIO -ne 2 ]
then
  cp -a "${MYDIR}/config/audio_order_AND_no_More_Disclaimer/systemApp.js.audio" /jci/gui/apps/system/js/
  log_message "===                 Added marker 'systemApp.js.audio'                 ==="

  if [ -e /jci/gui/apps/system/js/systemApp.js.disclaimer ]
  then
    if [ $TRACKORDER_AUDIO -eq 1 ]
    then
      cat "${MYDIR}/config/audio_order_AND_no_More_Disclaimer/systemApp.js.audio" "${MYDIR}/config/audio_order_AND_no_More_Disclaimer/both/jci/gui/apps/system/js/systemApp.${TRACKORDER_AUDIO_FILE}.js" > /jci/gui/apps/system/js/systemApp.js
      log_message "===     Changed order of audio source list, disclaimer still gone     ==="
    else
      cat "${MYDIR}/config/audio_order_AND_no_More_Disclaimer/systemApp.js.audio" "${MYDIR}/config/audio_order_AND_no_More_Disclaimer/both/jci/gui/apps/system/js/systemApp.js" > /jci/gui/apps/system/js/systemApp.js
      log_message "===     Changed order of audio source list, disclaimer still gone     ==="
    fi
  else
    if [ $TRACKORDER_AUDIO -eq 1 ]
    then
      cat "${MYDIR}/config/audio_order_AND_no_More_Disclaimer/systemApp.js.audio" "${MYDIR}/config/audio_order_AND_no_More_Disclaimer/only_change_audio_order/jci/gui/apps/system/js/systemApp.${TRACKORDER_AUDIO_FILE}.js" > /jci/gui/apps/system/js/systemApp.js
      log_message "===      Changed order of audio source list (no no-more-disclaimer)   ==="
    else
      cat "${MYDIR}/config/audio_order_AND_no_More_Disclaimer/systemApp.js.audio" "${MYDIR}/config/audio_order_AND_no_More_Disclaimer/only_change_audio_order/jci/gui/apps/system/js/systemApp.js" > /jci/gui/apps/system/js/systemApp.js
      log_message "===     Changed order of audio source list (no no-more-disclaimer)    ==="
    fi
  fi
else
  show_message "=== ORDER OF AUDIO SOURCES PATCH SKIPPED  ==="
  log_message "********         Audio Source List Order Tweak Skipped           ********"
fi
if [ $TESTBKUPS -eq 1 ]
then
  cp /jci/gui/apps/system/js/systemApp.js "${MYDIR}/bakups/test/systemApp_after-audiosources.js"
fi
log_message "====****** END INSTALLATION OF ORDER OF THE AUDIO SOURCE LIST ******====="
log_message " "
}

#--------------------------------------------------------------------------------------------

install_removeBackgrounds()
{
# Remove CSS that is already been added
sed -i "/.. MZD-AIO-TI NO-BTN-BG ../,/.. END AIO CSS ../d" /jci/gui/common/controls/Ump3/css/Ump3Ctrl.css
# Append css
echo "/* MZD-AIO-TI NO-BTN-BG */" >> /jci/gui/common/controls/Ump3/css/Ump3Ctrl.css

if [ $NO_BTN_BG -eq 1 ]
then
		cat <<EOT >> /jci/gui/common/controls/Ump3/css/Ump3Ctrl.css
	/* Remove Button Backgrounds */
	.Ump3CtrlBgArch,
	.Ump3CtrlSeparator {
		background:none!important;
	}
EOT
log_message "===                Removed Behind Buttons Background                  ==="
fi
if [ $NO_NP_BG -eq 1 ]
then
		cat <<EOT >> /jci/gui/common/controls/Ump3/css/Ump3Ctrl.css
	/* Remove Now Playing Background*/
	.NowPlaying4Ctrl {
		background:none!important;
	}
EOT
log_message "===                  Removed Now Playing Overlay                      ==="
fi
if [ $NO_LIST_BG -eq 1 ]
then
		cat <<EOT >> /jci/gui/common/controls/Ump3/css/Ump3Ctrl.css
	/* Remove List Background*/
	.List2Ctrl {
		background:none!important;
	}
EOT
log_message "===                    Removed List View Overlay                      ==="
fi
if [ $NO_CALL_BG -eq 1 ]
then
		cat <<EOT >> /jci/gui/common/controls/Ump3/css/Ump3Ctrl.css
	/* Remove In Call Background*/
	.InCall2ContactActiveBkg,
	.InCall2InCallBG {
		background:none!important;
	}
EOT
log_message "===                   Removed In-Call Overlay                         ==="
fi
if [ $NO_TEXT_BG -eq 1 ]
then
		cat <<EOT >> /jci/gui/common/controls/Ump3/css/Ump3Ctrl.css
	/* Remove In Call Background*/
	.Messaging2CtrlBackground {
		background:none!important;
	}
EOT
log_message "===                Removed Text Message View Overlay                  ==="
fi

echo "/* END AIO CSS */" >> /jci/gui/common/controls/Ump3/css/Ump3Ctrl.css

log_message "========***** END INSTALLATION OF REMOVE BACKGROUND OVERLAYS *****======="
log_message " "
}

#--------------------------------------------------------------------------------------------

install_biggerArt()
{
backup_org /jci/gui/common/controls/NowPlaying4/css/NowPlaying4Ctrl.css

# bigger album art
show_message "BIGGER ALBUM ART ..."
log_message "========*********      INSTALL BIGGER ALBUM ART ...      *********======="

# Copy Images
cp -a ${MYDIR}/config/bigger-album-art/jci/gui/common/controls/InCall2/images/NowPlayingImageFrame.png /jci/gui/common/controls/InCall2/images
cp -a ${MYDIR}/config/bigger-album-art/jci/gui/common/controls/NowPlaying4/images/NowPlayingImageFrame.png /jci/gui/common/controls/NowPlaying4/images

# Remove Existing CSS
remove_aio_css /jci/gui/common/controls/NowPlaying4/css/NowPlaying4Ctrl.css BIGGERALBM

# Add CSS
echo "/* MZD-AIO-TI BIGGERALBM CSS */" >> /jci/gui/common/controls/NowPlaying4/css/NowPlaying4Ctrl.css

cat ${MYDIR}/config/bigger-album-art/big-albm.css >> /jci/gui/common/controls/NowPlaying4/css/NowPlaying4Ctrl.css

if [ $FULLTITLES -eq 1 ]
then
	cat ${MYDIR}/config/bigger-album-art/full-titles.css >> /jci/gui/common/controls/NowPlaying4/css/NowPlaying4Ctrl.css
	log_message "===                  Added for Full Width Titles                      ==="
fi

if [ $NOALBM -eq 1 ]
then
	cat ${MYDIR}/config/bigger-album-art/no-albm.css >> /jci/gui/common/controls/NowPlaying4/css/NowPlaying4Ctrl.css
	log_message "===               Added CSS For Hide Album Art Option                 ==="
fi

echo "/* END AIO BIGGERALBM CSS */" >> /jci/gui/common/controls/NowPlaying4/css/NowPlaying4Ctrl.css

log_message "===              CSS Added for Bigger Album Art Tweak                 ==="

log_message "========*******   END INSTALLATION OF BIGGER ALBUM ART   ********========"
log_message " "
}

#-----------------------------------------------------------------------------------------------

replace_albumFrame_controlBg()
{
# remove blank album art frame
show_message "REPLACE ALBUM ART FRAME & CONTROLS BG..."
log_message "=======******** INSTALL REMOVE BLANK ALBUM ART FRAME ... ********========"

cp -a "${MYDIR}/config/blank-album-art-frame/jci/gui/common/controls/InCall2/images/NowPlayingImageFrame.png" /jci/gui/common/controls/InCall2/images
cp -a "${MYDIR}/config/blank-album-art-frame/jci/gui/common/controls/NowPlaying4/images/NowPlayingImageFrame.png" /jci/gui/common/controls/NowPlaying4/images
cp -a "${MYDIR}/config/blank-album-art-frame/jci/gui/common/images/no_artwork_icon.png" /jci/gui/common/images
cp -a "${MYDIR}/config/blank-album-art-frame/jci/gui/common/images/radio_icon.png" /jci/gui/common/images
cp -a "${MYDIR}/config/blank-album-art-frame/jci/gui/common/images/controls_bg.png" /jci/gui/common/images
log_message "===                     Replaced Blank Album Art                      ==="

log_message "======*******  END REPLACE ALBUM ART FRAME & CONTROLS BG  *******======="
log_message " "
}

#--------------------------------------------------------------------------------------------

install_changeBackgrpounds()
{
# change background image
show_message "CHANGING BACKGROUND IMAGE ..."
log_message "=======*********  INSTALL CHANGE BACKGROUND IMAGE ...   *********========"

if [ $KEEPBKUPS -eq 1 ]
then
  cp /jci/gui/common/images/background.png "${MYDIR}/bakups/background.png"
  aio_info \"background.png\",
  log_message "===             Previous Infotainment Background Saved To:            === "
  log_message "===                ${MYDIR}/bakups/background.png                ==="
fi
if [ -s ${MYDIR}/config/background.png ]
then
  cp -a "${MYDIR}/config/background.png" /jci/gui/common/images
  log_message "===                   Background Image Changed                        ==="
else
  show_message "ERROR MISSING BACKGROUND IMAGE FILE!!!"
  log_message "===              ERROR: Mising Background Image File                  ==="
fi

log_message "======*********** END INSTALLATION OF BACKGROUND IMAGE ***********======="
log_message " "

backup_org /jci/gui/apps/system/controls/OffScreen/images/OffScreenBackground.png

# change off screen background image
show_message "CHANGING OFF SCREEN BACKGROUND IMAGE ..."
log_message "=====********** INSTALL OFF SCREEN BACKGROUND IMAGE ...  ***********====="
if [ -s ${MYDIR}/config/OffScreenBackground.png ]
then
  cp -a ${MYDIR}/config/OffScreenBackground.png /jci/gui/apps/system/controls/OffScreen/images/
  log_message "===                 Replaced Off Screen Background Image              ==="
else
  show_message "ERROR MISSING OFF-SCREEN BACKGROUND FILE!!!"
  log_message "===             ERROR: Off Screen Background Image not found          ==="
fi

log_message "====********* END INSTALLATION OFF SCREEN BACKGROUND IMAGE **********===="
log_message " "
}

#------------------------- Install functions - uncomment to activate -----------------------------------------

# uninstall_backgroundRotator

install_custTheme

install_statusTweaks

install_menuTweaks

install_reverseTweaks

install_menuLoop

install_noMoreDisclaimer

install_sourceList

install_removeBackgrounds

install_biggerArt

replace_albumFrame_controlBg

install_changeBackgrpounds

#------------------------------------------------------------------------------------------------------------

show_message "========== END OF TWEAKS INSTALLATION =========="
[ -s /etc/profile ] || restore_org /etc/profile
if [ -f "${MYDIR}/AIO_log.txt" ]
then
  END_ROOTFS=$(df -h | (grep 'rootfs' || echo 0) | awk '{ print $5 " " $1 }')
  END_RESOURCES=$(df -h | (grep 'resources' || echo 0) | awk '{ print $5 " " $1 }')
  END_ROOTFS="$(echo $END_ROOTFS | awk '{ print $1}' | cut -d'%' -f1)"
  END_RESOURCES="$(echo $END_RESOURCES | awk '{ print $1}' | cut -d'%' -f1)"
  sleep 2
  log_message "======================== rootfs $END_ROOTFS% used ================================"
  log_message "====================== resources $END_RESOURCES% used ==============================="
  [ $END_ROOTFS -gt 95 ] && log_message "$(df -h )"
  log_message "======================= END OF TWEAKS INSTALLATION ======================"
fi
if [ $KEEPBKUPS -eq 1 ] && [ -e ${MYDIR}/AIO_info.json ]
then
  json="$(cat ${MYDIR}/AIO_info.json)"
  rownend=$(echo -n $json | tail -c 1)
  if [ "$rownend" = "," ]
  then
    # if so, remove "," from back end
    echo -n ${json%,*} > ${MYDIR}/AIO_info.json
    sleep 2
  fi
  aio_info ']}'
fi
# a window will appear before the system reboots automatically
sleep 1
killall -q jci-dialog
/jci/tools/jci-dialog --info --title="SELECTED AIO TWEAKS APPLIED" --text="THE SYSTEM WILL REBOOT IN A FEW SECONDS!" --no-cancel &
sleep 5
killall -q jci-dialog
/jci/tools/jci-dialog --info --title="MZD-AIO-TI v.${AIO_VER}" --text="YOU CAN REMOVE THE USB DRIVE NOW\n\nENJOY!" --no-cancel &
sleep 0.1
reboot &
exit 0

