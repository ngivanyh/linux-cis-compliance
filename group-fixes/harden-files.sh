# hardens files of important purpose to make sure whoever's doing things to it is legit, mostly changing file perms to only root

# LOG variable, for the log
LOG=""

# config 1 = yes (to changes soon applied) 0 = no
BOOTLOADER_PERM=1
BOOTLOADER_PSSWD=1

MOTD_CONFIG=1
MOTD_CONFIG_TXT="" # no \m \r \s \v

LOCAL_LOGIN_BANNER_CONFIG=1
LOCAL_LOGIN_BANNER_TXT="" # no \m \r \s \v

REMOTE_LOGIN_BANNER_CONFIG=1
REMOTE_LOGIN_BANNER_TXT="" # no \m \r \s \v

MOTD_PERM=1

LOCAL_LOGIN_BANNER_PERM=1

REMOTE_LOGIN_BANNER_PERM=1

GDM_LOGIN_BANNER_PERM=1

HOSTS_ALLOW_PERM=1

HOSTS_DENY_CONFIG=1
HOSTS_DENY_PERM=1

GSHADOW_DASH_FILE_PERM=1

GROUP_DASH_FILE_PERM=1

SHADOW_DASH_FILE_PERM=1

PSSWD_DASH_FILE_PERM=1

GSHADOW_FILE_PERM=1

GROUP_FILE_PERM=1

SHADOW_FILE_PERM=1

PSSWD_FILE_PERM=1

SSH_PUBLIC_HOST_PERM=1

SSH_PRIVATE_HOST_PERM=1

SSHD_CONFIG_PERM=1

AT_CRON_PERM=1

CRON_D_PERM=1
CRON_MONTHLY_PERM=1
CRON_WEEKLY_PERM=1
CRON_DAILY_PERM=1
CRON_HOURLY_PERM=1
CRONTAB_PERM=1

if [ "$EUID" -ne 0 ]; then
    echo "run this script with root"
    exit 1
fi

harden() {
    local harden_file="$1"
    local chown_opt="$2"
    local chmod_opt="$3"
    local target_perm_code="$4"

    if [ ! -f "$harden_file" ]; then
        echo "$harden_file does not exist, will be skipped"
        return 1
    fi

    echo "changing perms of $harden_file"
    chown "$chown_opt" "$harden_file"
    chmod "$chmod_opt" "$harden_file"

    local filestat=$(stat -Lc "%a %A %u %U %g %G" "$harden_file")

    if [[ $filestat =~ $target_perm_code ]] && [[ $filestat =~ 0 root 0 root ]]; then
        echo "$harden_file file permissions changed successfully to $filestat"
        LOG+="HARDENED $harden_file with file permissions $filestat"
        return 0
    fi

    echo "$harden_file file permissions change failed to change to $filestat"
    LOG+="FAILED to harden $harden_file with file permissions $filestat"
    return 2
}

print_settings() {
  echo "BOOTLOADER_PERM: $BOOTLOADER_PERM"
  echo "BOOTLOADER_PSSWD: $BOOTLOADER_PSSWD"
  echo "MOTD_CONFIG: $MOTD_CONFIG"
  echo "MOTD_CONFIG_TXT: \"$MOTD_CONFIG_TXT\""
  echo "LOCAL_LOGIN_BANNER_CONFIG: $LOCAL_LOGIN_BANNER_CONFIG"
  echo "LOCAL_LOGIN_BANNER_TXT: \"$LOCAL_LOGIN_BANNER_TXT\""
  echo "REMOTE_LOGIN_BANNER_CONFIG: $REMOTE_LOGIN_BANNER_CONFIG"
  echo "REMOTE_LOGIN_BANNER_TXT: \"$REMOTE_LOGIN_BANNER_TXT\""
  echo "MOTD_PERM: $MOTD_PERM"
  echo "LOCAL_LOGIN_BANNER_PERM: $LOCAL_LOGIN_BANNER_PERM"
  echo "REMOTE_LOGIN_BANNER_PERM: $REMOTE_LOGIN_BANNER_PERM"
  echo "GDM_LOGIN_BANNER_PERM: $GDM_LOGIN_BANNER_PERM"
  echo "HOSTS_ALLOW_PERM: $HOSTS_ALLOW_PERM"
  echo "HOSTS_DENY_CONFIG: $HOSTS_DENY_CONFIG"
  echo "HOSTS_DENY_PERM: $HOSTS_DENY_PERM"
  echo "GSHADOW_DASH_FILE_PERM: $GSHADOW_DASH_FILE_PERM"
  echo "GROUP_DASH_FILE_PERM: $GROUP_DASH_FILE_PERM"
  echo "SHADOW_DASH_FILE_PERM: $SHADOW_DASH_FILE_PERM"
  echo "PSSWD_DASH_FILE_PERM: $PSSWD_DASH_FILE_PERM"
  echo "GSHADOW_FILE_PERM: $GSHADOW_FILE_PERM"
  echo "GROUP_FILE_PERM: $GROUP_FILE_PERM"
  echo "SHADOW_FILE_PERM: $SHADOW_FILE_PERM"
  echo "PSSWD_FILE_PERM: $PSSWD_FILE_PERM"
  echo "SSH_PUBLIC_HOST_PERM: $SSH_PUBLIC_HOST_PERM"
  echo "SSH_PRIVATE_HOST_PERM: $SSH_PRIVATE_HOST_PERM"
  echo "SSHD_CONFIG_PERM: $SSHD_CONFIG_PERM"
  echo "AT_CRON_PERM: $AT_CRON_PERM"
  echo "CRON_D_PERM: $CRON_D_PERM"
  echo "CRON_MONTHLY_PERM: $CRON_MONTHLY_PERM"
  echo "CRON_WEEKLY_PERM: $CRON_WEEKLY_PERM"
  echo "CRON_DAILY_PERM: $CRON_DAILY_PERM"
  echo "CRON_HOURLY_PERM: $CRON_HOURLY_PERM"
  echo "CRONTAB_PERM: $CRONTAB_PERM"
}

print_settings

# bootloader root only
if [ "$BOOTLOADER_PERM" -eq 1 ]; then