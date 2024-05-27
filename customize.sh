
CALC_PKG_NAME="CalcYou"
CALC_PKG_ID="net.youapps.calcyou"
CALC_PKG_URL=https://github.com/you-apps/${CALC_PKG_NAME}/releases/latest/download/app-release.apk

CLOCK_PKG_NAME="ClockYou"
CLOCK_PKG_ID="com.bnyro.clock"
CLOCK_PKG_URL=https://github.com/you-apps/${CLOCK_PKG_NAME}/releases/latest/download/app-release.apk

CONNECT_PKG_NAME="ConnectYou"
CONNECT_PKG_ID="com.bnyro.contacts"
CONNECT_PKG_URL=https://github.com/you-apps/${CONNECT_PKG_NAME}/releases/latest/download/app-release.apk

RECORD_PKG_NAME="RecordYou"
RECORD_PKG_ID="com.bnyro.recorder"
RECORD_PKG_URL=https://github.com/you-apps/${RECORD_PKG_NAME}/releases/latest/download/app-release.apk

TRANSLATE_PKG_NAME="TranslateYou"
TRANSLATE_PKG_ID="com.bnyro.translate"
TRANSLATE_PKG_URL=https://github.com/you-apps/${TRANSLATE_PKG_NAME}/releases/latest/download/app-libre-release.apk

VIBE_PKG_NAME="VibeYou"
VIBE_PKG_ID="app.suhasdissa.vibeyou"
VIBE_PKG_URL=https://github.com/you-apps/${VIBE_PKG_NAME}/releases/latest/download/app-release.apk

WALL_PKG_NAME="WallYou"
WALL_PKG_ID="com.bnyro.wallpaper"
WALL_PKG_URL=https://github.com/you-apps/${WALL_PKG_NAME}/releases/latest/download/app-release.apk

tmp=$MODPATH/tmp
mkdir -p $tmp

download() {
  local PKG_NAME=$1
  local PKG_URL=$2

  ui_print "* Download ${PKG_NAME}"
  curl -o $tmp/${PKG_NAME}.apk -L ${PKG_URL}
}

install() {
  local PKG_NAME=$1
  local PKG_ID=$2

  ui_print "* Install ${PKG_NAME}"
  SZ=$(stat -c "%s" $tmp/${PKG_NAME}.apk)
  if ! SES=$(pm install-create --user 0 -i com.android.vending -r -d -S "$SZ" 2>&1); then
    ui_print "ERROR: install-create failed"
    abort "$SES"
  fi
  SES=${SES#*[}
  SES=${SES%]*}
  set_perm "$tmp/${PKG_NAME}.apk" 1000 1000 644 u:object_r:apk_data_file:s0
  if ! op=$(pm install-write -S "$SZ" "$SES" "${PKG_ID}.apk" "$tmp/${PKG_NAME}.apk" 2>&1); then
    ui_print "ERROR: install-write failed"
    abort "$op"
  fi
  if ! op=$(pm install-commit "$SES" 2>&1); then
    if echo "$op" | grep -q INSTALL_FAILED_VERSION_DOWNGRADE; then
      ui_print "* INSTALL_FAILED_VERSION_DOWNGRADE. Uninstalling..."
      pm uninstall -k --user 0 ${PKG_ID}
      return 1
    fi
    ui_print "ERROR: install-commit failed"
    abort "$op"
  fi
  if BASEPATH=$(pm path ${PKG_ID}); then
    BASEPATH=${BASEPATH##*:}
    BASEPATH=${BASEPATH%/*}
  else
    abort "ERROR: install TranslateYou manually and reflash the module"
  fi
  sleep 1
  BASEPATHLIB=${BASEPATH}/lib/${ARCH}
  if [ -z "$(ls -A1 ${BASEPATHLIB})" ]; then
    ui_print "* Extracting native libs"
    mkdir -p $BASEPATHLIB
    if ! op=$(unzip -j $tmp/${PKG_NAME}.apk lib/${ARCH_LIB}/* -d ${BASEPATHLIB} 2>&1); then
      ui_print "ERROR: extracting native libs failed"
      abort "$op"
    fi
    set_perm_recursive ${BASEPATH}/lib 1000 1000 755 755 u:object_r:apk_data_file:s0
  fi
  ui_print "* Setting Permissions"
  set_perm $BASEPATH/base.apk 1000 1000 644 u:object_r:apk_data_file:s0
  am force-stop ${PKG_ID}
  ui_print "* Optimizing ${PKG_NAME}"
  nohup cmd package compile --reset ${PKG_ID} >/dev/null 2>&1 &
  ui_print "* Cleanup"
  rm -rf $tmp/${PKG_NAME}.apk
  ui_print ""; sleep 1
}

ui_print ""
download "${CALC_PKG_NAME}" "${CALC_PKG_URL}" 
download "${CLOCK_PKG_NAME}" "${CLOCK_PKG_URL}"
download "${CONNECT_PKG_NAME}" "${CONNECT_PKG_URL}"
download "${RECORD_PKG_NAME}" "${RECORD_PKG_URL}"
download "${TRANSLATE_PKG_NAME}" "${TRANSLATE_PKG_URL}"
download "${VIBE_PKG_NAME}" "${VIBE_PKG_URL}"
download "${WALL_PKG_NAME}" "${WALL_PKG_URL}"
ui_print ""; sleep 1

settings put global verifier_verify_adb_installs 0

install "${CALC_PKG_NAME}" "${CALC_PKG_ID}"
install "${CLOCK_PKG_NAME}" "${CLOCK_PKG_ID}"
install "${CONNECT_PKG_NAME}" "${CONNECT_PKG_ID}"
install "${RECORD_PKG_NAME}" "${RECORD_PKG_ID}"
install "${TRANSLATE_PKG_NAME}" "${TRANSLATE_PKG_ID}"
install "${VIBE_PKG_NAME}" "${VIBE_PKG_ID}"
install "${WALL_PKG_NAME}" "${WALL_PKG_ID}"

settings put global verifier_verify_adb_installs 1

ui_print ""
ui_print "* Cleanup"
rm -rf $tmp

touch "${MODPATH}/remove"
touch "${MODPATH}/disabled"
touch "/data/adb/modules/${MODID}/remove"
touch "/data/adb/modules/${MODID}/disabled"

ui_print ""
ui_print "* Success"
ui_print ""
