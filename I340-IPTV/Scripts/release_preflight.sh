#!/bin/bash
#
# Release Preflight
#
# Fails a Release build while any placeholder or test value is still in place.
# Debug builds are left alone on purpose: they are meant to run on test IDs.
#
# Wired as a build phase on the I340-IPTV target, before "Compile Sources".

set -u

if [ "${CONFIGURATION}" != "Release" ]; then
    echo "Release Preflight: skipped (CONFIGURATION=${CONFIGURATION})"
    exit 0
fi

FAILURES=0

fail() {
    echo "error: Release Preflight — $1" >&2
    FAILURES=$((FAILURES + 1))
}

XCCONFIG="${SRCROOT}/I340-IPTV/Environments/AppRelease.xcconfig"
INFO_PLIST="${SRCROOT}/I340-IPTV/Resources/Info.plist"
FIREBASE_PLIST="${SRCROOT}/I340-IPTV/Resources/GoogleService-Info.plist"

# --- 1. Placeholders left in the Release xcconfig -----------------------------

if [ ! -f "${XCCONFIG}" ]; then
    fail "AppRelease.xcconfig not found at ${XCCONFIG}"
else
    # Only real settings count; the header comments mention __SET_ME__ on purpose.
    UNSET_KEYS=$(grep -nE "^[A-Za-z_][A-Za-z0-9_]*[[:space:]]*=.*__SET_ME__" "${XCCONFIG}" \
        | sed -E 's/^([0-9]+):([A-Za-z_][A-Za-z0-9_]*).*/\2/' | tr '\n' ' ')
    if [ -n "${UNSET_KEYS}" ]; then
        fail "AppRelease.xcconfig still unset: ${UNSET_KEYS}— ask the PM for the real values."
    fi

    # Google's public test ad unit prefix.
    if grep -q "ca-app-pub-3940256099942544" "${XCCONFIG}"; then
        fail "AppRelease.xcconfig still uses Google TEST ad unit IDs (ca-app-pub-3940256099942544)."
    fi

    if grep -qE "^\s*(OneTime|IAPWeekly|IAPYearly|IAPMonthly|IAPYearlySaleOff|IAPMiniPackage)\s*=\s*com\.test\." "${XCCONFIG}"; then
        fail "AppRelease.xcconfig still uses com.test.* IAP product IDs."
    fi

    if grep -qE "^\s*ApplicationID\s*=\s*id0+\s*$" "${XCCONFIG}"; then
        fail "AppRelease.xcconfig ApplicationID is still the placeholder id0000000000."
    fi

    if grep -qE "^\s*EmailDeveloper\s*=\s*your-email@example\.com" "${XCCONFIG}"; then
        fail "AppRelease.xcconfig EmailDeveloper is still your-email@example.com."
    fi

    if grep -qE "^\s*IAPSubcriptionSecret\s*=\s*$" "${XCCONFIG}"; then
        fail "AppRelease.xcconfig IAPSubcriptionSecret is empty."
    fi
fi

# --- 2. Bundle identifier ------------------------------------------------------

case "${PRODUCT_BUNDLE_IDENTIFIER}" in
    com.test.*|*.test.*|"")
        fail "PRODUCT_BUNDLE_IDENTIFIER is a test bundle (${PRODUCT_BUNDLE_IDENTIFIER})."
        ;;
esac

# --- 3. Firebase plist must match the bundle identifier ------------------------

if [ ! -f "${FIREBASE_PLIST}" ]; then
    fail "GoogleService-Info.plist not found at ${FIREBASE_PLIST}"
else
    FIREBASE_BUNDLE=$(/usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" "${FIREBASE_PLIST}" 2>/dev/null || echo "")
    if [ -z "${FIREBASE_BUNDLE}" ]; then
        fail "GoogleService-Info.plist has no BUNDLE_ID."
    elif [ "${FIREBASE_BUNDLE}" != "${PRODUCT_BUNDLE_IDENTIFIER}" ]; then
        fail "GoogleService-Info.plist BUNDLE_ID (${FIREBASE_BUNDLE}) != PRODUCT_BUNDLE_IDENTIFIER (${PRODUCT_BUNDLE_IDENTIFIER}). Create a Firebase app for this bundle."
    fi
fi

# --- 4. Export compliance ------------------------------------------------------

if ! /usr/libexec/PlistBuddy -c "Print :ITSAppUsesNonExemptEncryption" "${INFO_PLIST}" >/dev/null 2>&1; then
    fail "Info.plist is missing ITSAppUsesNonExemptEncryption."
fi

# --- 5. Adjust app token -------------------------------------------------------

TOKEN_FILE="${SRCROOT}/I340-IPTV/Sources/Data/Services/Analytics/DefaultConfigToken.swift"
if [ -f "${TOKEN_FILE}" ]; then
    if grep -qE 'case \.adjustToken:\s*$' -A2 "${TOKEN_FILE}" 2>/dev/null && \
       grep -A2 'case \.adjustToken:' "${TOKEN_FILE}" | grep -qE 'return ""'; then
        fail "DefaultConfigToken.adjustToken is empty. Ask the PM for this app's Adjust app token."
    fi
fi

# --- Result --------------------------------------------------------------------

if [ "${FAILURES}" -gt 0 ]; then
    echo "error: Release Preflight failed with ${FAILURES} issue(s). Fix them before archiving." >&2
    exit 1
fi

echo "Release Preflight: OK"
exit 0
