#!/usr/bin/env bash

# Set strict mode
set -euo pipefail

# --- Configuration ---
readonly LOG_SOURCE_DIR="/var/log/myapp"
readonly ARCHIVE_DIR="/var/log/myapp/archive"
readonly RETENTION_DAYS=30

# Ensure directories exist
mkdir -p "${ARCHIVE_DIR}"

# --- Execution ---
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Starting log archival..."

# 1. Check if source directory exists
if [[ ! -d "${LOG_SOURCE_DIR}" ]]; then
    echo "ERROR: Directory ${LOG_SOURCE_DIR} does not exist." >&2
    exit 1
fi

# 2. Find and process logs older than RETENTION_DAYS
# We look for files ending in .log, excluding those already in the archive
find "${LOG_SOURCE_DIR}" -maxdepth 1 -name "*.log" -mtime +${RETENTION_DAYS} -print0 | while IFS= read -r -d '' file; do
    
    filename=$(basename "${file}")
    target="${ARCHIVE_DIR}/${filename}.$(date +%Y%m%d).gz"
    
    echo "Archiving: ${filename}"
    
    # Compress and move
    if gzip -c "${file}" > "${target}"; then
        rm -f "${file}"
        echo "Successfully archived to ${target}"
    else
        echo "ERROR: Failed to archive ${file}" >&2
        exit 1
    fi
done

# 3. Cleanup: Remove archives older than 90 days to free disk space
find "${ARCHIVE_DIR}" -name "*.gz" -mtime +90 -exec rm -f {} \;

echo "[$(date +'%Y-%m-%d %H:%M:%S')] Archival process finished successfully."
