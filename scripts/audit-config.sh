# anything and everything that has to do with auditing and logging

# log variable
LOG="LOG:\n"

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

if [ "$JOURNALD_TO_SYSLOG" -eq 1 ] && [ -f cat /etc/systemd/journald.conf ] && [[ ! "$(cat /etc/systemd/journald.conf)" =~ "^(?!.*#)\s*ForwardToSyslog\s*=\s*yes" ]]; then
    echo "Compress=yes" > /etc/systemd/journald.conf
    echo "setting compression on journald.conf"
    
    if [[ "$(cat /etc/systemd/journald.conf)" =~ "Compress\s=\syes" ]]; then
        echo "compress = yes success journald"
        LOG+="compress = yes journald SUCCESS"
    else
        echo "compress = yes fail journald"
        LOG+="compress = yes journald FAILED"
    fi
fi
