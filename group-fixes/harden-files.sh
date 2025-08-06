# hardens files of important purpose to make sure whoever's doing things to it is legit, mostly changing file perms to only root

# LOG variable, for the log
LOG="LOG:\n"

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

GDM3_LOGIN_BANNER_CONFIG=1
GDM3_LOGIN_BANNER_TXT=""

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
    isHardened() {
        local target_perm="$1"
        local file="$2"
        local target_own="$3"
        local cur_filestat="$(stat -Lc "%a %A %u %U %g %G" "$file")"
        
        if [[ $cur_filestat =~ $target_perm ]] && [[ $cur_filestat =~ $target_own ]]; then
            return 1
        fi

        return 0
    }

    local harden_file="$1"
    local chown_opt="$2"
    local chmod_opt="$3"
    local target_perm_code="$4"
    local target_owner="$5"

    if [ ! -e "$harden_file" ]; then
        echo -e "$harden_file does not exist, will be skipped\n"
        return 1
    fi

    isHardened "$target_perm_code" "$harden_file" "$target_owner"
    local cur_file_perm=$?

    if [ $cur_file_perm -eq 1 ]; then
        echo -e "$harden_file already hardened\n"
        return 2
    fi

    echo "changing perms of $harden_file"
    chown "$chown_opt" "$harden_file"
    chmod "$chmod_opt" "$harden_file"

    isHardened "$target_perm_code" "$harden_file" "$target_owner"
    local cur_file_perm=$?

    if [ $cur_file_perm -eq 1 ]; then
        echo -e "$harden_file file permissions changed successfully\n"
        LOG+="HARDENED $harden_file\n"
        return 0
    fi

    echo -e "$harden_file file permissions change failed\n"
    LOG+="FAILED to harden $harden_file\n"
    return 3
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

    cp "$config_filepath" "$(basename "$config_filepath").bak"
    echo -e "copied original sshd_config file to $(pwd) under the name of $(basename "$config_filepath").bak\n"

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
        echo -e "$config_name configuration hardened\n"
        LOG+="$config_name configuration hardening SUCCESSFUL\n"
    else
        echo -e "$config_name configuration is NOT hardened\n"
        LOG+="$config_name configuration hardening FAILED\n"
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

# bootloader password
if [ "$BOOTLOADER_PSSWD" -eq 1 ]; then
    echo "you must choose a password in this next section, please choose your password wisely"

    if [ -f /boot/grub2/grub2.cfg ]; then
        if command -v grub2-setpassword &> /dev/null; then
            echo "using grub2-setpassword to set password"
            grub2-setpassword
            echo
            LOG+="grub2-setpassword RAN\n"
        else
            echo "grub2-setpassword doesn't exist, you can specify the password in the configuration files\n"
            LOG+="grub2-setpassword FAILED\n"
        fi
    else
        if command -v grub-crypt &> /dev/null; then
            echo "using grub-crypt to set password"
            grub-crypt | psswd_hash="password $(sed -n '3p')" | echo $psswd_hash >> /boot/grub/menu.lst
            echo
            LOG+="grub-crypt RAN\n"
        else
            echo "grub-crypt doesn't exist, you can specify the password in the configuration files\n"
            LOG+="grub-crypt FAILED\n"
        fi
    fi
fi

# motd harden
if [ "$MOTD_CONFIG" -eq 1 ] && [ -f /etc/motd ]; then
    harden_config "$MOTD_CONFIG_TXT" /etc/motd "motd (/etc/motd)"
elif [ "$MOTD_CONFIG" -eq 1 ] && [ ! -f /etc/motd ]; then
    echo "/etc/motd nonexistent\n"
fi

# /etc/issue (local login banner) harden
if [ "$LOCAL_LOGIN_BANNER_CONFIG" -eq 1 ] && [ -f /etc/issue ]; then
    harden_config "$LOCAL_LOGIN_BANNER_TXT" /etc/issue "local login banner (/etc/issue)"
elif [ "$LOCAL_LOGIN_BANNER_CONFIG" -eq 1 ] && [ ! -f /etc/issue ]; then
    echo "/etc/issue nonexistent\n"
fi

# /etc/issue.net (local login banner) harden
if [ "$REMOTE_LOGIN_BANNER_CONFIG" -eq 1 ] && [ -f /etc/issue.net ]; then
    harden_config "$REMOTE_LOGIN_BANNER_TXT" /etc/issue.net "remote login banner (/etc/issue.net)"
elif [ "$LOCAL_LOGIN_BANNER_CONFIG" -eq 1 ] && [ ! -f /etc/issue ]; then
    echo "/etc/issue.net nonexistent\n"
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
if [ "$GDM_LOGIN_BANNER" -eq 1 ]; then
    gdm_banner_configured=$(grep -zo "\[org\/gnome\/login-screen\]\nbanner-message-enable=true\nbanner-message-text='.*'")
    if [ -f /etc/gdm3/greeter.dconf-defaults ] && [ "$gdm_banner_configured" -eq 0 ]; then
        echo "gdm3 configuration already contains banner"
    fi

    if [ ! -f /etc/gdm3/greeter.dconf-defaults ]; then
        echo "creating /etc/gdm3/greeter.dconf-defaults"
        touch /etc/gdm3/greeter.dconf-defaults
        echo -e "[org/gnome/login-screen]\nbanner-message-enable=true\nbanner-message-text='$GDM_LOGIN_BANNER_TXT'" >> /etc/gdm3/greeter.dconf-defaults
        echo "added banner information to /etc/gdm3/greeter.dconf-defaults"
    else
        echo -e "[org/gnome/login-screen]\nbanner-message-enable=true\nbanner-message-text='$GDM_LOGIN_BANNER_TXT'" >> /etc/gdm3/greeter.dconf-defaults
        echo "added banner information to /etc/gdm3/greeter.dconf-defaults"
    fi

    gdm_banner_configured=$(grep -qzo -zo "\[org\/gnome\/login-screen\]\nbanner-message-enable=true\nbanner-message-text='.*'")
    if [ -f /etc/gdm3/greeter.dconf-defaults ] && [ "$gdm_banner_configured" -eq 0 ]; then
        echo "gdm3 configured to have banner\n"
        LOG+="gdm3 configuration SUCCESS\n"
    else
        echo "gdm3 configuration to have banner failed\n"
        LOG+="gdm3 configuration FAILED\n"
    fi
fi
# gdm banner

# hosts.allow perm
if [ "$HOSTS_ALLOW_PERM" -eq 1 ]; then
    harden /etc/hosts.allow "root:root" 644 644 "0 root 0 root"
fi

# hosts.deny conf
if [ "$HOSTS_DENY_CONFIG" -eq 1 ]; then
    if [ ! -f /etc/hosts.deny ]; then
        echo "this operation will create a /etc/hosts.deny file"
        LOG+="CREATED /etc/hosts.deny\n"
    fi

    if cat /etc/hosts.deny | grep -qE "^ALL:ALL$"; then
        echo "/etc/hosts.deny already configured"
    else
        echo "configuring /etc/hosts.deny"
        echo "ALL:ALL" >> /etc/hosts.deny

        if cat /etc/hosts.deny | grep -qE "^ALL:ALL$"; then
            echo -e "successfully configured /etc/hosts.deny\n"
            LOG+="/etc/hosts.deny configuration SUCCESS\n"
        else
            echo -e "failed to configure /etc/hosts.deny\n"
            LOG+="/etc/hosts.deny configuration FAILED\n"
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
    harden /etc/shadow "root:root" "o-rwx,g-wx" "640|600|500|400|0" "0 root 0 root"
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
        harden /etc/at.allow "root:root" "og-rwx" 600 "0 root 0 root"
        at_allow_ret=$?
        harden /etc/cron.allow "root:root" "og-rwx" 600 "0 root 0 root"
        cron_allow_ret=$?

        if [ "$at_allow_ret" -eq 1 ];
            echo "creating /etc/at.allow"
            touch /etc/at.allow
            harden /etc/at.allow "root:root" "og-rwx" 600 "0 root 0 root"
            at_allow_ret=$?
        fi

        if [ "$cron_allow_ret" -eq 1 ];
            echo "creating /etc/cron.allow"
            touch /etc/cron.allow
            harden /etc/cron.allow "root:root" "og-rwx" 600 "0 root 0 root"
            cron_allow_ret=$?
        fi
        
        if [ -f /etc/at.deny ]; then
            echo "removing /etc/at.deny"
            rm -rf /etc/at.deny
        fi
        
        if [ -f /etc/cron.deny ]; then
            echo "removing /etc/cron.deny"
            rm -rf /etc/cron.deny
        fi

        if [ ! -f /etc/at.deny ] && [ ! -f /etc/cron.deny ] && [ "$cron_allow_ret" -eq 0 ] && [ "$at_allow_ret" -eq 0 ]; then
            echo -e "successfully purged /etc/at.deny and /etc/cron.deny, and hardened (maybe created) /etc/cron.allow and /etc/at.allow\n"
            LOG+="rm /etc/at.deny, /etc/cron.deny AND create /etc/at.allow, /etc/cron.allow SUCCESS\n"
        else
            echo -e "failed to either purge /etc/at.deny and /etc/cron.deny, or failed to harden (or created) /etc/cron.allow and /etc/at.allow (or that both operations have failed)\n"
            LOG+="rm /etc/at.deny, /etc/cron.deny AND create /etc/at.allow, /etc/cron.allow FAILED\n"
        fi
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

echo -e "finished applying fixes\n"

echo "$LOG"