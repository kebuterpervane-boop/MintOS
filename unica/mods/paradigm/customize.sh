LOG_STEP_IN "- Adding Now Brief"
ADD_TO_WORK_DIR "pa1qxxx" "system" "system/priv-app/SamsungSmartSuggestions/SamsungSmartSuggestions.apk" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "pa1qxxx" "system" "system/priv-app/Moments/Moments.apk" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "pa1qxxx" "system" "system/etc/permissions/privapp-permissions-com.samsung.android.app.moments.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "pa1qxxx" "system" "system/etc/default-permissions/default-permissions-com.samsung.android.app.moments.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "pa1qxxx" "system" "system/etc/sysconfig/moments.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "pa1qxxx" "system" "system/etc/permissions/privapp-permissions-com.samsung.android.smartsuggestions.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "pa1qxxx" "system" "system/etc/default-permissions/default-permissions-com.samsung.android.smartsuggestions.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "pa1qxxx" "system" "system/etc/sysconfig/samsungsmartsuggestions.xml" 0 0 644 "u:object_r:system_file:s0"
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_COMMON_CONFIG_AI_VERSION" "20253"
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_FRAMEWORK_SUPPORT_PERSONALIZED_DATA_CORE" "TRUE"

# AI Servis Pil Optimizasyonu: Moments (Now Brief) power-save whitelist'ten cikarilir
# Boylece Doze sistemi AI islerini idle/sarj zamanina iter
# Ozellik kaybi yok: AI islemleri sarjda ve bosta normal calisir, pilde sadece maintenance window'da
LOG "- Optimizing AI service power management for battery life"
MOMENTS_CFG="$WORK_DIR/system/system/etc/sysconfig/moments.xml"
if [ -f "$MOMENTS_CFG" ]; then
    sed -i '/allow-in-power-save /d' "$MOMENTS_CFG"
    sed -i '/allow-in-power-save-except-idle/d' "$MOMENTS_CFG"
fi
LOG_STEP_OUT
