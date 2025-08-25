# --- Configuration Variables ---
# LOG_FILE="hardening_script.log"
LOG="LOG:\n"

# --- Consolidated Configuration File Paths ---
AUDIT_RULES_FILE="/etc/audit/rules.d/99-cis-hardening.rules"
RSYSLOG_CONF="/etc/rsyslog.conf"
JOURNALD_CONF="/etc/systemd/journald.conf"

log_message() {
    echo "$1"
    LOG+="$1\n"
}

# --- System Detection (Run once) ---
PKG_MANAGER_CMD=""
if command -v dpkg &> /dev/null; then
    PKG_MANAGER_CMD="apt-get"
elif command -v dnf &> /dev/null; then
    PKG_MANAGER_CMD="dnf"
elif command -v yum &> /dev/null; then
    PKG_MANAGER_CMD="yum"
elif command -v zypper &> /dev/null; then
    PKG_MANAGER_CMD="zypper"
fi

# Function to check if a command is present
is_command_present() {
    command -v "$1" &> /dev/null
}

# Function to install a package
install_pkg() {
    log_message "Attempting to install package: $1"
    if [ -n "$PKG_MANAGER_CMD" ]; then
        $PKG_MANAGER_CMD install -y "$1"
    else
        log_message "Error: Unsupported package manager. Please install '$1' manually."
        return 1
    fi
}

# Function to enable a service
enable_service() {
    log_message "Enabling service: $1"
    systemctl enable "$1" --now
}

# Function to add auditd rules
add_audit_rules() {
    local description="$1"
    shift
    local rules=("$@")
    
    log_message "--- $description ---"
    
    local all_rules_exist=true
    for rule in "${rules[@]}"; do
        # Extract the key from the rule string
        local key=$(echo "$rule" | awk -F '-k ' '{print $2}' | awk '{print $1}')
        if [ -n "$key" ]; then
            # Check if a rule with this key is loaded
            if ! auditctl -l | grep -qF -- "-k $key"; then
                all_rules_exist=false
                break
            fi
        else
             log_message "Warning: Could not extract key from rule: $rule"
        fi
    done

    log_message "Precondition Check: Verifying audit rules for '$description' are loaded."
    if [ "$all_rules_exist" = true ]; then
        log_message "Result: All rules for '$description' appear to be loaded."
    else
        log_message "Result: One or more rules for '$description' are not loaded."
        log_message "Execution: Adding audit rules to persistent file for '$description'."
        for rule in "${rules[@]}"; do
            # Add rule to file only if it doesn't exist to avoid duplicates
            if ! grep -qF -- "$rule" "$AUDIT_RULES_FILE"; then
                echo "$rule" >> "$AUDIT_RULES_FILE"
            fi
        done
        
        log_message "Final Check: Verifying rules for '$description' are in file."
        local all_rules_in_file=true
        for rule in "${rules[@]}"; do
            grep -qF -- "$rule" "$AUDIT_RULES_FILE" || all_rules_in_file=false
        done
        
        if [ "$all_rules_in_file" = true ]; then
            log_message "Result: Rules for '$description' successfully added to file. Will be loaded on service restart."
        else
            log_message "Result: Failed to add all rules for '$description' to file."
        fi
    fi
    log_message ""
}


# --- Main Script Logic ---

log_message "Starting CIS Hardening Script at $(date)"
log_message "---"

# User-defined configuration flags
INSTALL_AUDITD=1
INSTALL_AUDITD_SERVICE=1

AUDIT_CHANGE_DT=1
AUDIT_CHANGE_USR_GRP=1
AUDIT_CHANGE_SELINUX_APPARMOR=1
AUDIT_LOGIN_LOGOUT=1
AUDIT_SESSION_INIT=1
AUDIT_CHANGE_FILE_ATTR=1
AUDIT_FILE_ACTIONS=1
AUDIT_SUCCESSFUL_FILE_MNTS=1
AUDIT_SUCCESSFUL_FS_MNTS=1
AUDIT_FILE_DELETION=1
AUDIT_CHANGE_SYSADMIN=1
AUDIT_KERNEL_MOD_CHANGES=1

IMMUT_AUDIT_CONF=1

INSTALL_RSYSLOG=1
ENABLE_RSYSLOG=1

HEIGHTEN_RSYSLOG_FILE_PERM=1
RSYSLOG_DISABLE_RECEIVE=1

JOURNALD_TO_SYSLOG=1
JOURNALD_COMPRESS=1
JOURNALD_WRITE_TO_DISK=1

# 4.1.2 Ensure auditd is installed
if [ "$INSTALL_AUDITD" -eq 1 ]; then
    log_message "--- CIS 4.1.2: Ensure auditd is installed ---"
    log_message "Precondition Check: Checking if auditd command is present."
    if is_command_present auditd; then
        log_message "Result: auditd command is present."
    else
        log_message "Result: auditd command is not present."
        log_message "Execution: Installing auditd package."
        # Debian/Ubuntu uses 'auditd', RedHat/CentOS uses 'audit'
        if [ "$PKG_MANAGER_CMD" = "apt-get" ]; then
            install_pkg auditd
            install_pkg audispd-plugins
        else
            install_pkg audit
        fi
        log_message "Final Check: Verifying auditd command is now present."
        if is_command_present auditd; then
            log_message "Result: auditd command is now present."
        else
            log_message "Result: Failed to install auditd."
        fi
    fi
    log_message ""
fi

# 4.1.3 Ensure auditd service is enabled
if [ "$INSTALL_AUDITD_SERVICE" -eq 1 ]; then
    log_message "--- CIS 4.1.3: Ensure auditd service is enabled ---"
    log_message "Precondition Check: Checking if auditd service is enabled."
    if systemctl is-enabled auditd &> /dev/null; then
        log_message "Result: auditd service is already enabled."
    else
        log_message "Result: auditd service is not enabled."
        log_message "Execution: Enabling auditd service."
        enable_service auditd
        log_message "Final Check: Verifying auditd service is enabled."
        if systemctl is-enabled auditd &> /dev/null; then
            log_message "Result: auditd service successfully enabled."
        else
            log_message "Result: Failed to enable auditd service."
        fi
    fi
    log_message ""
fi

# Create a rules file if it doesn't exist
if [ ! -f "$AUDIT_RULES_FILE" ]; then
    touch "$AUDIT_RULES_FILE"
    log_message "Created audit rules file: $AUDIT_RULES_FILE"
fi

# 4.1.5 Ensure events that modify date and time information are collected
if [ "$AUDIT_CHANGE_DT" -eq 1 ]; then
    rules=(
        "-a always,exit -F arch=b64 -S adjtimex -S settimeofday -k time-change"
        "-a always,exit -F arch=b32 -S adjtimex -S settimeofday -S stime -k time-change"
        "-w /etc/localtime -p wa -k time-change"
    )
    add_audit_rules "CIS 4.1.5: Audit Date/Time Modifications" "${rules[@]}"
fi

# 4.1.6 Ensure events that modify user/group information are collected
if [ "$AUDIT_CHANGE_USR_GRP" -eq 1 ]; then
    rules=(
        "-w /etc/group -p wa -k identity"
        "-w /etc/passwd -p wa -k identity"
        "-w /etc/gshadow -p wa -k identity"
        "-w /etc/shadow -p wa -k identity"
        "-w /etc/security/opasswd -p wa -k identity"
    )
    add_audit_rules "CIS 4.1.6: Audit User/Group Modifications" "${rules[@]}"
fi

# 4.1.8 Ensure events that modify the system's Mandatory Access Controls are collected
if [ "$AUDIT_CHANGE_SELINUX_APPARMOR" -eq 1 ]; then
    if [ -d "/etc/selinux" ]; then
        rules=("-w /etc/selinux/ -p wa -k MAC-policy")
        add_audit_rules "CIS 4.1.8: Audit SELinux MAC Modifications" "${rules[@]}"
    fi
    if [ -d "/etc/apparmor.d" ]; then
        rules=("-w /etc/apparmor.d/ -p wa -k MAC-policy")
        add_audit_rules "CIS 4.1.8: Audit AppArmor MAC Modifications" "${rules[@]}"
    fi
fi

# 4.1.9 Ensure login and logout events are collected
if [ "$AUDIT_LOGIN_LOGOUT" -eq 1 ]; then
    rules=(
        "-w /var/log/faillog -p wa -k logins"
        "-w /var/log/lastlog -p wa -k logins"
        "-w /var/log/tallylog -p wa -k logins"
    )
    add_audit_rules "CIS 4.1.9: Audit Login/Logout Events" "${rules[@]}"
fi

# 4.1.10 Ensure session initiation information is collected
if [ "$AUDIT_SESSION_INIT" -eq 1 ]; then
    rules=(
        "-w /var/run/utmp -p wa -k session"
        "-w /var/log/wtmp -p wa -k logins"
        "-w /var/log/btmp -p wa -k logins"
    )
    add_audit_rules "CIS 4.1.10: Audit Session Initiation" "${rules[@]}"
fi

# 4.1.11 Ensure discretionary access control permission modification events are collected
if [ "$AUDIT_CHANGE_FILE_ATTR" -eq 1 ]; then
    UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)
    [ -z "$UID_MIN" ] && UID_MIN=1000
    rules=(
        "-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -F auid>=${UID_MIN} -F auid!=-1 -k perm_mod"
        "-a always,exit -F arch=b32 -S chmod -S fchmod -S fchmodat -F auid>=${UID_MIN} -F auid!=-1 -k perm_mod"
        "-a always,exit -F arch=b64 -S chown -S fchown -S fchownat -S lchown -F auid>=${UID_MIN} -F auid!=-1 -k perm_mod"
        "-a always,exit -F arch=b32 -S chown -S fchown -S fchownat -S lchown -F auid>=${UID_MIN} -F auid!=-1 -k perm_mod"
    )
    add_audit_rules "CIS 4.1.11: Audit DAC Modifications" "${rules[@]}"
fi

# 4.1.12 Ensure unsuccessful unauthorized file access attempts are collected
if [ "$AUDIT_FILE_ACTIONS" -eq 1 ]; then
    UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)
    [ -z "$UID_MIN" ] && UID_MIN=1000
    rules=(
        "-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=${UID_MIN} -F auid!=-1 -k access"
        "-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=${UID_MIN} -F auid!=-1 -k access"
        "-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=${UID_MIN} -F auid!=-1 -k access"
        "-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=${UID_MIN} -F auid!=-1 -k access"
    )
    add_audit_rules "CIS 4.1.12: Audit Unsuccessful File Access" "${rules[@]}"
fi

# 4.1.14 Ensure successful file system mounts are collected
if [ "$AUDIT_SUCCESSFUL_FS_MNTS" -eq 1 ]; then
    UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)
    [ -z "$UID_MIN" ] && UID_MIN=1000
    rules=(
        "-a always,exit -F arch=b64 -S mount -F auid>=${UID_MIN} -F auid!=-1 -k mounts"
        "-a always,exit -F arch=b32 -S mount -F auid>=${UID_MIN} -F auid!=-1 -k mounts"
    )
    add_audit_rules "CIS 4.1.14: Audit Successful Mounts" "${rules[@]}"
fi

# 4.1.15 Ensure file deletion events by users are collected
if [ "$AUDIT_FILE_DELETION" -eq 1 ]; then
    UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)
    [ -z "$UID_MIN" ] && UID_MIN=1000
    rules=(
        "-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F auid>=${UID_MIN} -F auid!=-1 -k delete"
        "-a always,exit -F arch=b32 -S unlink -S unlinkat -S rename -S renameat -F auid>=${UID_MIN} -F auid!=-1 -k delete"
    )
    add_audit_rules "CIS 4.1.15: Audit File Deletion" "${rules[@]}"
fi

# 4.1.16 Ensure changes to system administration scope (sudoers) is collected
if [ "$AUDIT_CHANGE_SYSADMIN" -eq 1 ]; then
    rules=(
        "-w /etc/sudoers -p wa -k scope"
        "-w /etc/sudoers.d/ -p wa -k scope"
    )
    add_audit_rules "CIS 4.1.16: Audit Sudoers Changes" "${rules[@]}"
fi

# 4.1.18 Ensure kernel module loading and unloading is collected
if [ "$AUDIT_KERNEL_MOD_CHANGES" -eq 1 ]; then
    rules=(
        "-w /sbin/insmod -p x -k modules"
        "-w /sbin/rmmod -p x -k modules"
        "-w /sbin/modprobe -p x -k modules"
        "-a always,exit -F arch=b64 -S init_module -S delete_module -k modules"
    )
    add_audit_rules "CIS 4.1.18: Audit Kernel Module Changes" "${rules[@]}"
fi

# 4.1.19 Ensure the audit configuration is immutable
if [ "$IMMUT_AUDIT_CONF" -eq 1 ]; then
    rules=("-e 2")
    add_audit_rules "CIS 4.1.19: Make Audit Configuration Immutable" "${rules[@]}"
fi

# 4.2.1.1 Ensure rsyslog is installed
if [ "$INSTALL_RSYSLOG" -eq 1 ]; then
    log_message "--- CIS 4.2.1.1: Ensure rsyslog is installed ---"
    log_message "Precondition Check: Checking if rsyslogd command is present."
    if is_command_present rsyslogd; then
        log_message "Result: rsyslogd command is present."
    else
        log_message "Result: rsyslogd command is not present."
        log_message "Execution: Installing rsyslog package."
        install_pkg rsyslog
        log_message "Final Check: Verifying rsyslogd command is now present."
        if is_command_present rsyslogd; then
            log_message "Result: rsyslogd command is now present."
        else
            log_message "Result: Failed to install rsyslog."
        fi
    fi
    log_message ""
fi

# 4.2.1.2 Ensure rsyslog Service is enabled
if [ "$ENABLE_RSYSLOG" -eq 1 ]; then
    log_message "--- CIS 4.2.1.2: Ensure rsyslog service is enabled ---"
    log_message "Precondition Check: Checking if rsyslog service is enabled."
    if systemctl is-enabled rsyslog &> /dev/null; then
        log_message "Result: rsyslog service is already enabled."
    else
        log_message "Result: rsyslog service is not enabled."
        log_message "Execution: Enabling rsyslog service."
        enable_service rsyslog
        log_message "Final Check: Verifying rsyslog service is enabled."
        if systemctl is-enabled rsyslog &> /dev/null; then
            log_message "Result: rsyslog service successfully enabled."
        else
            log_message "Result: Failed to enable rsyslog service."
        fi
    fi
    log_message ""
fi

# 4.2.1.4 Ensure rsyslog default file permissions configured
if [ "$HEIGHTEN_RSYSLOG_FILE_PERM" -eq 1 ]; then
    log_message "--- CIS 4.2.1.4: Configure rsyslog default file permissions ---"
    log_message "Precondition Check: Checking rsyslog file creation mode."
    if grep -q '^\$FileCreateMode 0640' "$RSYSLOG_CONF"; then
        log_message "Result: rsyslog FileCreateMode is already configured."
    else
        log_message "Result: rsyslog FileCreateMode is not configured."
        log_message "Execution: Setting rsyslog FileCreateMode to 0640."
        echo '$FileCreateMode 0640' >> "$RSYSLOG_CONF"
        log_message "Final Check: Verifying rsyslog file creation mode."
        grep -q '^\$FileCreateMode 0640' "$RSYSLOG_CONF" && log_message "Result: Success." || log_message "Result: Failure."
    fi
    log_message ""
fi

# 4.2.1.6 Ensure remote rsyslog messages are only accepted on designated log hosts (disable receive)
# As requested by the user, this section is commented out.
# if [ "$RSYSLOG_DISABLE_RECEIVE" -eq 1 ]; then
#     log_message "--- CIS 4.2.1.6: Disable rsyslog remote message reception ---"
#     log_message "Precondition Check: Checking if rsyslog remote reception is disabled."
#     if ! grep -q '^\$ModLoad imtcp' "$RSYSLOG_CONF" && ! grep -q '^\$InputTCPServerRun' "$RSYSLOG_CONF"; then
#         log_message "Result: rsyslog remote reception is already disabled."
#     else
#         log_message "Result: rsyslog remote reception is enabled."
#         log_message "Execution: Disabling rsyslog remote reception."
#         sed -i 's/^\$ModLoad imtcp/#\$ModLoad imtcp/' "$RSYSLOG_CONF"
#         sed -i 's/^\$InputTCPServerRun/#\$InputTCPServerRun/' "$RSYSLOG_CONF"
#         log_message "Final Check: Verifying rsyslog remote reception is disabled."
#         if ! grep -q '^\$ModLoad imtcp' "$RSYSLOG_CONF" && ! grep -q '^\$InputTCPServerRun' "$RSYSLOG_CONF"; then
#             log_message "Result: Success."
#         else
#             log_message "Result: Failure."
#         fi
#     fi
#     log_message ""
# fi

# 4.2.2.1 Ensure journald is configured to send logs to rsyslog
if [ "$JOURNALD_TO_SYSLOG" -eq 1 ]; then
    log_message "--- CIS 4.2.2.1: Configure journald to send logs to rsyslog ---"
    log_message "Precondition Check: Checking if journald forwards to syslog."
    if grep -q '^ForwardToSyslog=yes' "$JOURNALD_CONF"; then
        log_message "Result: journald is already configured to forward to syslog."
    else
        log_message "Result: journald is not configured to forward to syslog."
        log_message "Execution: Configuring journald to forward to syslog."
        echo 'ForwardToSyslog=yes' >> "$JOURNALD_CONF"
        log_message "Final Check: Verifying journald forwards to syslog."
        grep -q '^ForwardToSyslog=yes' "$JOURNALD_CONF" && log_message "Result: Success." || log_message "Result: Failure."
    fi
    log_message ""
fi

# 4.2.2.2 Ensure journald is configured to compress large log files
if [ "$JOURNALD_COMPRESS" -eq 1 ]; then
    log_message "--- CIS 4.2.2.2: Configure journald to compress large log files ---"
    log_message "Precondition Check: Checking if journald compression is enabled."
    if grep -q '^Compress=yes' "$JOURNALD_CONF"; then
        log_message "Result: journald compression is already enabled."
    else
        log_message "Result: journald compression is not enabled."
        log_message "Execution: Enabling journald compression."
        echo 'Compress=yes' >> "$JOURNALD_CONF"
        log_message "Final Check: Verifying journald compression is enabled."
        grep -q '^Compress=yes' "$JOURNALD_CONF" && log_message "Result: Success." || log_message "Result: Failure."
    fi
    log_message ""
fi

# 4.2.2.3 Ensure journald is configured to write logfiles to persistent disk
if [ "$JOURNALD_WRITE_TO_DISK" -eq 1 ]; then
    log_message "--- CIS 4.2.2.3: Configure journald for persistent storage ---"
    log_message "Precondition Check: Checking if journald storage is persistent."
    if grep -q '^Storage=persistent' "$JOURNALD_CONF"; then
        log_message "Result: journald storage is already persistent."
    else
        log_message "Result: journald storage is not persistent."
        log_message "Execution: Setting journald storage to persistent."
        echo 'Storage=persistent' >> "$JOURNALD_CONF"
        log_message "Final Check: Verifying journald storage is persistent."
        grep -q '^Storage=persistent' "$JOURNALD_CONF" && log_message "Result: Success." || log_message "Result: Failure."
    fi
    log_message ""
fi

# Reload services to apply changes
log_message "--- Reloading services ---"
log_message "Reloading auditd..."
systemctl restart auditd
log_message "Reloading rsyslog..."
systemctl restart rsyslog
log_message "Reloading systemd-journald..."
systemctl restart systemd-journald

log_message "---"
log_message "CIS Hardening Script finished at $(date)"
log_message "---"

# --- Print Final Log ---
echo -e "\n--- FINAL ACCUMULATED LOG ---"
echo -e "$LOG"

