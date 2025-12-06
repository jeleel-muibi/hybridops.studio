#!/usr/bin/env bash
# prestage-iso.sh - Manage ISO file availability on Proxmox storage for Packer builds
# Maintainer: HybridOps.Studio
# Date: 2025-11-16

set -euo pipefail

log_info() {
    printf "[INFO] %s\n" "$*"
}

log_success() {
    printf "[OK] %s\n" "$*"
}

log_warn() {
    printf "[WARN] %s\n" "$*"
}

log_error() {
    printf "[ERROR] %s\n" "$*" >&2
    exit 1
}

parse_arguments() {
    local proxmox_host="${1:-}"
    local mode="${2:-}"

    if [[ "$mode" == "--pkrvars" ]]; then
        local pkrvars_file="${3:-}"
        local field_type="${4:-iso}"

        [[ -z "$proxmox_host" || -z "$pkrvars_file" ]] && \
            log_error "Usage: $0 <proxmox_host> --pkrvars <file.pkrvars.hcl> [iso|virtio]"

        [[ ! -f "$pkrvars_file" ]] && \
            log_error "pkrvars file not found: $pkrvars_file"

        if [[ "$field_type" == "virtio" ]]; then
            ISO_FILE=$(grep -oP 'iso_file\s*=\s*"\K[^"]+' "$pkrvars_file" | tail -1)
            ISO_URL=$(grep -oP 'iso_url\s*=\s*"\K[^"]+' "$pkrvars_file" | tail -1)
            ISO_CHECKSUM=$(grep -oP 'iso_checksum\s*=\s*"\K[^"]+' "$pkrvars_file" | tail -1)
        else
            ISO_FILE=$(grep -oP '^iso_file\s*=\s*"\K[^"]+' "$pkrvars_file" | head -1)
            ISO_URL=$(grep -oP '^iso_url\s*=\s*"\K[^"]+' "$pkrvars_file" | head -1)
            ISO_CHECKSUM=$(grep -oP '^iso_checksum\s*=\s*"\K[^"]+' "$pkrvars_file" | head -1)
        fi

        [[ -z "$ISO_FILE" ]] && log_error "Could not extract iso_file from $pkrvars_file"
        [[ -z "$ISO_URL" ]] && log_error "Could not extract iso_url from $pkrvars_file"
    else
        ISO_FILE="${2:-}"
        ISO_URL="${3:-}"
        ISO_CHECKSUM="${4:-}"

        [[ -z "$proxmox_host" || -z "$ISO_FILE" || -z "$ISO_URL" ]] && \
            log_error "Usage: $0 <proxmox_host> <iso_file> <iso_url> [iso_checksum]"
    fi

    PROXMOX_HOST="$proxmox_host"
    ISO_PATH="/var/lib/vz/template/iso/${ISO_FILE}"
}

verify_existing_iso() {
    if ssh root@"$PROXMOX_HOST" "test -f $ISO_PATH" 2>/dev/null; then
        if [[ -n "$ISO_CHECKSUM" && "$ISO_CHECKSUM" != "none" ]]; then
            log_info "Validating checksum..."
            local remote_checksum
            remote_checksum=$(ssh root@"$PROXMOX_HOST" "sha256sum $ISO_PATH 2>/dev/null | cut -d' ' -f1")
            local expected_checksum="${ISO_CHECKSUM#sha256:}"

            if [[ "$remote_checksum" == "$expected_checksum" ]]; then
                log_success "ISO valid: $ISO_FILE"
                exit 0
            else
                log_warn "Checksum mismatch, re-downloading"
                ssh root@"$PROXMOX_HOST" "rm -f $ISO_PATH" 2>/dev/null || true
            fi
        else
            log_success "ISO exists: $ISO_FILE"
            exit 0
        fi
    fi
}

download_iso() {
    log_info "Downloading ISO: $ISO_FILE"
    log_info "Source: $ISO_URL"

    local download_tool=""
    if ssh root@"$PROXMOX_HOST" "command -v wget >/dev/null 2>&1"; then
        download_tool="wget"
    elif ssh root@"$PROXMOX_HOST" "command -v curl >/dev/null 2>&1"; then
        download_tool="curl"
    else
        log_error "Neither wget nor curl available on remote host"
    fi

    ssh root@"$PROXMOX_HOST" "bash -s" <<DOWNLOAD
set -e
cd /var/lib/vz/template/iso

if [[ "$download_tool" == "wget" ]]; then
    wget -c -q --show-progress --timeout=30 "$ISO_URL" -O "${ISO_FILE}.tmp"
else
    curl -L -C - --progress-bar --max-time 1800 "$ISO_URL" -o "${ISO_FILE}.tmp"
fi

if [[ ! -s "${ISO_FILE}.tmp" ]]; then
    echo "[ERROR] Download failed or file is empty"
    rm -f "${ISO_FILE}.tmp"
    exit 1
fi

mv "${ISO_FILE}.tmp" "$ISO_FILE"
DOWNLOAD

    [[ $? -ne 0 ]] && log_error "Download failed"
    log_success "ISO downloaded: $ISO_FILE"
}

verify_downloaded_iso() {
    if [[ -n "$ISO_CHECKSUM" && "$ISO_CHECKSUM" != "none" ]]; then
        log_info "Verifying checksum..."
        local downloaded_checksum
        downloaded_checksum=$(ssh root@"$PROXMOX_HOST" "sha256sum $ISO_PATH | cut -d' ' -f1")
        local expected_checksum="${ISO_CHECKSUM#sha256:}"

        if [[ "$downloaded_checksum" == "$expected_checksum" ]]; then
            log_success "Checksum verified"
        else
            log_error "Checksum verification failed"
        fi
    fi
}

main() {
    parse_arguments "$@"
    log_info "Verifying ISO: $ISO_FILE"
    verify_existing_iso
    download_iso
    verify_downloaded_iso
    log_success "ISO ready: $ISO_FILE"
}

main "$@"
