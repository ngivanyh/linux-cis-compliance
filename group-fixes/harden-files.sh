# hardens files of important purpose to make sure whoever's doing things to it is legit, mostly changing file perms to only root

# LOG variable, for the log
LOG=""

# config 1 = yes (to changes soon applied) 0 = no
BOOTLOADER_PERM=1
BOOTLOADER_PSSWD=1

MOTD_CONFIG=1
MOTD_CONFIG_TXT="" # no \m \r \s \v, will OVERWRITE existing configuration

LOCAL_LOGIN_BANNER_CONFIG=1
LOCAL_LOGIN_BANNER_TXT="" # no \m \r \s \v

REMOTE_LOGIN_BANNER_CONFIG=1
REMOTE_LOGIN_BANNER_TXT="" # no \m \r \s \v

MOTD_PERM=1

LOCAL_LOGIN_BANNER_PERM=1

REMOTE_LOGIN_BANNER_PERM=1

GDM_LOGIN_BANNER_CONFIG=1
GDM_LOGIN_BANNER_TXT=""

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

isHardened() {
    local target_perm="$1"
    local file="$2"
    local target_own="$3"
    local cur_filestat=$(stat -Lc "%a %A %u %U %g %G" "$file")
    
    if [[ $cur_filestat =~ $target_perm ]] && [[ $cur_filestat =~ $target_own ]]; then
        return 1
    fi

    return 0
}

harden() {
    local harden_file="$1"
    local chown_opt="$2"
    local chmod_opt="$3"
    local target_perm_code="$4"
    local target_owner="$5"

    if [ ! -e "$harden_file" ]; then
        echo "$harden_file does not exist, will be skipped"
        return 1
    fi

    isHardened "$target_perm_code" "$harden_file" "$target_owner"
    local cur_file_perm=$?

    if [ $cur_file_perm -eq 1 ]; then
        echo "$harden_file already hardened"
        return 1
    fi

    echo "changing perms of $harden_file"
    chown "$chown_opt" "$harden_file"
    chmod "$chmod_opt" "$harden_file"

    isHardened "$target_perm_code" "$harden_file" "$target_owner"
    local cur_file_perm=$?

    if [ $cur_file_perm -eq 1 ]; then
        echo "$harden_file file permissions changed successfully"
        LOG+="HARDENED $harden_file"
        return 0
    fi

    echo "$harden_file file permissions change failed to change to $filestat"
    LOG+="FAILED to harden $harden_file with file permissions $filestat"
    return 2
}


harden_config() {
    check_config_str() {
        local conf="$1"

        if echo "$conf" | grep -qE "\\\\[mrsv]"; then
            return 1
        fi

        return 0
    }

    local config_str="$1"
    local config_filepath="$2"
    local config_name="$3"

    echo "checking new config string of $config_str"
    check_config_str "$config_str"
    isSafeConfig=$?

    if [ $isSafeConfig -eq 0 ]; then
        echo "this operation will overwrite exisitng $config_name"
        echo "$config_str" > "$config_filepath"
    fi

    check_config_str "$(cat "$config_filepath")"
    isSafeConfig=$?

    if [ $isSafeConfig -eq 0 ]; then
        echo "$config_name configuration hardened"
        LOG+="$config_name configuration hardening SUCCESSFUL"
    else
        echo "$config_name configuration is NOT hardened"
        LOG+="$config_name configuration hardening FAILED"
    fi
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
    harden /boot/grub2/grub2.cfg "root:root" "og-rwx" 400 "0 root 0 root"
    harden /boot/grub/grub.cfg "root:root" "og-rwx" 400 "0 root 0 root"
fi

# motd harden
if [ "$MOTD_CONFIG" -eq 1 ] && [ -f /etc/motd ]; then
    harden_config "$MOTD_CONFIG_TXT" /etc/motd "motd (/etc/motd)"
elif [ "$MOTD_CONFIG" -eq 1 ] && [ ! -f /etc/motd ]; then
    echo "/etc/motd nonexistent"
fi

# /etc/issue (local login banner) harden
if [ "$LOCAL_LOGIN_BANNER_CONFIG" -eq 1 ] && [ -f /etc/issue ]; then
    harden_config "$LOCAL_LOGIN_BANNER_TXT" /etc/issue "local login banner (/etc/issue)"
elif [ "$LOCAL_LOGIN_BANNER_CONFIG" -eq 1 ] && [ ! -f /etc/issue ]; then
    echo "/etc/issue nonexistent"
fi

# /etc/issue.net (local login banner) harden
if [ "$REMOTE_LOGIN_BANNER_CONFIG" -eq 1 ] && [ -f /etc/issue.net ]; then
    harden_config "$REMOTE_LOGIN_BANNER_TXT" /etc/issue.net "remote login banner (/etc/issue.net)"
elif [ "$LOCAL_LOGIN_BANNER_CONFIG" -eq 1 ] && [ ! -f /etc/issue ]; then
    echo "/etc/issue.net nonexistent"
fi

# motd perm
if [ "$MOTD_PERM" -eq 1 ]; then
    harden /etc/motd "root:root" 644 644 "0 root 0 root"
fi

# local login banner perm
if [ "$LOCAL_LOGIN_BANNER_PERM" -eq 1 ]; then
    harden /etc/issue "root:root" 644 644 "0 root 0 root"
fi

# motd perm
if [ "$REMOTE_LOGIN_BANNER_PERM" -eq 1 ]; then
    harden /etc/issue.net "root:root" 644 644 "0 root 0 root"
fi

# not done gdm banner
# gdm banner

# hosts.allow perm
if [ "$HOSTS_ALLOW_PERM" -eq 1 ]; then
    harden /etc/hosts.allow "root:root" 644 644 "0 root 0 root"
fi

# hosts.deny conf
if [ "$HOSTS_DENY_CONFIG" -eq 1 ]; then
    if [ ! -f /etc/hosts.deny ]; then
        echo "this operation will create a /etc/hosts.deny file"
        LOG+="CREATED /etc/hosts.deny"
    fi

    if cat /etc/hosts.deny | grep -qE "^ALL:ALL$"; then
        echo "/etc/hosts.deny already configured"
    else
        echo "configuring /etc/hosts.deny"
        echo "ALL:ALL" >> /etc/hosts.deny

        if cat /etc/hosts.deny | grep -qE "^ALL:ALL$"; then
            echo "successfully configured /etc/hosts.deny"
            LOG+="/etc/hosts.deny configuration SUCCESS"
        else
            echo "failed to configure /etc/hosts.deny"
            LOG+="/etc/hosts.deny configuration FAILED"
        fi
    fi
fi

# hosts.deny perm
if [ "$HOSTS_DENY_PERM" -eq 1 ]; then
    harden /etc/hosts.deny "root:root" 644 644 "0 root 0 root"
fi

# gshadow- file perm
if [ "$GSHADOW_DASH_FILE_PERM" -eq 1 ]; then
    harden /etc/gshadow- "root:root" "o-rwx,g-rw" "640|600|500|400|0" "0 root 0 root"
fi

# group- file perm
if [ "$GROUP_DASH_FILE_PERM" -eq 1 ]; then
    harden /etc/group- "root:root" "u-x,go-wx" 644 "0 root 0 root"
fi

# shadow- file perm
if [ "$SHADOW_DASH_FILE_PERM" -eq 1 ]; then
    harden /etc/shadow- "root:root" "o-rwx,g-rw" "640|600|500|400|0" "0 root 0 root"
fi

# passwd- file perm
if [ "$PSSWD_DASH_FILE_PERM" -eq 1 ]; then
    harden /etc/passwd- "root:root" "u-x,go-rwx" "600|500|400|0 " "0 root 0 root"
fi

# gshadow file perm
if [ "$GSHADOW_FILE_PERM" -eq 1 ]; then
    harden /etc/gshadow "root:root" "o-rwx,g-rw" "640|600|500|400|0" "0 root 0 root"
fi

# group perm
if [ "$GROUP_FILE_PERM" -eq 1 ]; then
    harden /etc/group "root:root" 644 644 "0 root 0 root"
fi

# shadow file perm
if [ "$SHADOW_FILE_PERM" -eq 1 ]; then
    harden /etc/shadow "root:root" "o-rwx,g-rw" "640|600|500|400|0" "0 root 0 root"
fi

# passwd perm
if [ "$PSSWD_FILE_PERM" -eq 1 ]; then
    harden /etc/passwd "root:root" 644 644 "0 root 0 root"
fi

# ssh public host keys perm
if [ "$SSH_PUBLIC_HOST_PERM" -eq 1 ]; then
    for f in /etc/ssh/ssh_host_*_key.pub; do
        harden "$f" "root:root" 644 644 "0 root 0 root"
    done
fi

# ssh private key perm
if [ "$SSH_PRIVATE_HOST_PERM" -eq 1 ]; then
    for f in /etc/ssh/ssh_host_*_key; do
        harden "$f" "root:root" 600 600 "0 root 0 root"
    done
fi

# sshd config perm
if [ "$SSHD_CONFIG_PERM" -eq 1 ]; then
    harden /etc/ssh/sshd_config "root:root" "og-rwx" 600 "0 root 0 root"
fi

# creation of cron.allow and at.allow, removal of cron.deny and at.deny
if [ "$AT_CRON_PERM" -eq 1 ]; then
    # to be finished
fi

# cron.d directory perm
if [ "$CRON_D_PERM" -eq 1 ]; then
    harden /etc/cron.d "root:root" "og-rwx" 700 "0 root 0 root"
fi

# cron monthly perm
if [ "$CRON_MONTHLY_PERM" -eq 1 ]; then
    harden /etc/cron.monthly "root:root" "og-rwx" 700 "0 root 0 root"
fi

# cron weekly perm
if [ "$CRON_WEEKLY_PERM" -eq 1 ]; then
    harden /etc/cron.weekly "root:root" "og-rwx" 700 "0 root 0 root"
fi

# cron daily perm
if [ "$CRON_DAILY_PERM" -eq 1 ]; then
    harden /etc/cron.daily "root:root" "og-rwx" 700 "0 root 0 root"
fi

# cron hourly perm
if [ "$CRON_HOURLY_PERM" -eq 1 ]; then
    harden /etc/cron.hourly "root:root" "og-rwx" 700 "0 root 0 root"
fi

# crontab perm
if [ "$CRONTAB_PERM" -eq 1 ]; then
    harden /etc/crontab "root:root" "og-rwx" 600 "0 root 0 root"
fi