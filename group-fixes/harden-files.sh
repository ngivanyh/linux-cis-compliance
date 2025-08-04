# hardens files of important purpose to make sure whoever's doing things to it is legit

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
    echo "running this script with root is recommended\n"
fi

file_exists() {
    if [ -f $1 ]; then
        echo "$1 exists"
        return 0
    fi

    return 1
}

file_writabe() {
    if [ -w $1 ]; then
        echo "$1 writable"
        return 0
    fi

    return 1
}

