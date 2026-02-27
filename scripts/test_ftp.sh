#!/bin/bash
# ============================================================================
# FTP Test Script for Inception Project
# Demonstrates: connection, upload, download, directory listing, cleanup
# ============================================================================

set -e

FTP_HOST="localhost"
FTP_USER="ftpuser"
FTP_PASS="ftppassword123"
FTP_PORT=21

# Check if lftp or curl is available
if command -v lftp &>/dev/null; then
    FTP_CLIENT="lftp"
elif command -v curl &>/dev/null; then
    FTP_CLIENT="curl"
else
    echo "ERROR: Neither 'lftp' nor 'curl' found. Install one:"
    echo "  sudo apt install lftp   # or   sudo apt install curl"
    exit 1
fi

echo "============================================"
echo "  FTP Demonstration & Test Script"
echo "  Using: $FTP_CLIENT"
echo "============================================"
echo ""

# Create a test file to upload
TESTFILE="/tmp/ftp_test_inception_$(date +%s).txt"
echo "Hello from FTP test! Timestamp: $(date)" > "$TESTFILE"
TESTNAME=$(basename "$TESTFILE")

if [ "$FTP_CLIENT" = "lftp" ]; then

    # ── 1. Test connection & list root ──────────────────────────────
    echo "▶ 1. Connecting & listing FTP root directory..."
    lftp -u "$FTP_USER","$FTP_PASS" "ftp://$FTP_HOST:$FTP_PORT" -e "
        set ssl:verify-certificate no
        set ftp:ssl-allow no
        ls
        bye
    " 2>/dev/null
    echo ""

    # ── 2. Upload test file ─────────────────────────────────────────
    echo "▶ 2. Uploading test file '$TESTNAME'..."
    lftp -u "$FTP_USER","$FTP_PASS" "ftp://$FTP_HOST:$FTP_PORT" -e "
        set ssl:verify-certificate no
        set ftp:ssl-allow no
        put $TESTFILE
        bye
    " 2>/dev/null
    echo "   Uploaded."
    echo ""

    # ── 3. Verify upload ────────────────────────────────────────────
    echo "▶ 3. Verifying file exists on server..."
    lftp -u "$FTP_USER","$FTP_PASS" "ftp://$FTP_HOST:$FTP_PORT" -e "
        set ssl:verify-certificate no
        set ftp:ssl-allow no
        ls $TESTNAME
        bye
    " 2>/dev/null
    echo ""

    # ── 4. Download and compare ─────────────────────────────────────
    echo "▶ 4. Downloading file back..."
    DLFILE="/tmp/ftp_download_verify.txt"
    rm -f "$DLFILE"
    lftp -u "$FTP_USER","$FTP_PASS" "ftp://$FTP_HOST:$FTP_PORT" -e "
        set ssl:verify-certificate no
        set ftp:ssl-allow no
        get $TESTNAME -o $DLFILE
        bye
    " 2>/dev/null
    echo "   Downloaded to $DLFILE"
    echo "   Original : $(cat "$TESTFILE")"
    echo "   Downloaded: $(cat "$DLFILE")"
    if diff -q "$TESTFILE" "$DLFILE" &>/dev/null; then
        echo "   ✓ Files match!"
    else
        echo "   ✗ Files differ!"
    fi
    echo ""

    # ── 5. Delete test file from server ─────────────────────────────
    echo "▶ 5. Cleaning up — removing test file from FTP..."
    lftp -u "$FTP_USER","$FTP_PASS" "ftp://$FTP_HOST:$FTP_PORT" -e "
        set ssl:verify-certificate no
        set ftp:ssl-allow no
        rm $TESTNAME
        bye
    " 2>/dev/null
    echo "   Removed."
    echo ""

elif [ "$FTP_CLIENT" = "curl" ]; then

    # ── 1. List FTP root ────────────────────────────────────────────
    echo "▶ 1. Connecting & listing FTP root directory..."
    curl -s --list-only "ftp://$FTP_HOST:$FTP_PORT/" \
         --user "$FTP_USER:$FTP_PASS" 2>/dev/null || echo "(listing may be empty for new WP install)"
    echo ""

    # ── 2. Upload test file ─────────────────────────────────────────
    echo "▶ 2. Uploading test file '$TESTNAME'..."
    curl -s -T "$TESTFILE" "ftp://$FTP_HOST:$FTP_PORT/$TESTNAME" \
         --user "$FTP_USER:$FTP_PASS" 2>/dev/null
    echo "   Uploaded."
    echo ""

    # ── 3. Verify upload ────────────────────────────────────────────
    echo "▶ 3. Verifying file exists on server..."
    curl -s --list-only "ftp://$FTP_HOST:$FTP_PORT/" \
         --user "$FTP_USER:$FTP_PASS" 2>/dev/null | grep "$TESTNAME" && echo "   ✓ Found!" || echo "   ✗ Not found"
    echo ""

    # ── 4. Download and compare ─────────────────────────────────────
    echo "▶ 4. Downloading file back..."
    DLFILE="/tmp/ftp_download_verify.txt"
    curl -s -o "$DLFILE" "ftp://$FTP_HOST:$FTP_PORT/$TESTNAME" \
         --user "$FTP_USER:$FTP_PASS" 2>/dev/null
    echo "   Original : $(cat "$TESTFILE")"
    echo "   Downloaded: $(cat "$DLFILE")"
    if diff -q "$TESTFILE" "$DLFILE" &>/dev/null; then
        echo "   ✓ Files match!"
    else
        echo "   ✗ Files differ!"
    fi
    echo ""

    # ── 5. Delete test file (FTP DELE via curl quote) ───────────────
    echo "▶ 5. Cleaning up — removing test file from FTP..."
    curl -s "ftp://$FTP_HOST:$FTP_PORT/" \
         --user "$FTP_USER:$FTP_PASS" \
         -Q "DELE $TESTNAME" 2>/dev/null || true
    echo "   Removed."
    echo ""
fi

# Clean local temp files
rm -f "$TESTFILE" "$DLFILE" 2>/dev/null

echo "============================================"
echo "  ✓ All FTP tests completed!"
echo "============================================"
echo ""
echo "FTP access details for manual testing:"
echo "  Host: $FTP_HOST  Port: $FTP_PORT"
echo "  User: $FTP_USER  Pass: $FTP_PASS"
echo "  FTP root maps to: /var/www/html (WordPress files)"
