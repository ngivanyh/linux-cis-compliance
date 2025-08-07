# creates partitions for important directories with nodev nosuid noexec etc

# log variable for logs
LOG="LOG:\n"

# modprobe.d and /etc/fstab
modprobe_d_dir=/etc/modprobe.d/
fstab_dir=/etc/fstab/

# disable w/ modprobe
DISABLE_CRAMFS=1
DISABLE_FREEVXFS=1
DISABLE_JFFS2=1
DISABLE_HFS=1
DISABLE_HFSPLUS=1
DISABLE_SQUASHFS=1
DISABLE_UDF=1
LIMIT_FAT=1

# for /etc/fstab
TMP_PART=1
TMP_MNT_SETTINGS="strictatime nodev nosuid noexec" # set the options with space separated (using systemctl tmpfs), on default, if you want full compliance, keep this unchanged

# VAR_PART=1

# VAR_TMP_PART=1
# NODEV_VAR_TMP=1
# NOSUID_VAR_TMP=1
# NOEXEC_VAR_TMP=1

# VAR_LOG_PART=1

# VAR_LOG_AUDIT_PART=1

# HOME_PART=1
# NODEV_HOME=1

# NODEV_DEV_SHM=1
# NOSUID_DEV_SHM=1
# NOEXEC_DEV_SHM=1

# disable others
DISABLE_AUTOMOUNTING=1
DISABLE_USB_STORAGE=1

# aide
INSTALL_AIDE=1
PERIODICALLY_CHECK_FILESYSTEM=1

if [ "$EUID" -ne 0 ]; then
    echo "run this script as root"
    exit 1
fi

modprobe_disable() {
    local module_name="$1"

    local check_regex="install /bin/false|install /bin/true|Module $module_name not found"

    # check if it's currently used
    if lsmod | grep -q "$module_name"; then
        echo "module is currently used, will skip"
        return 1
    fi

    # check if it's already disabled
    if [[ "$(modprobe -n -v $module_name)" =~ $check_regex ]]; then
        echo "module is already disabled"
        return 1
    fi

    echo "this operation will overwrite any data (or possibly create a) $modprobe_d_dir$module_name.conf"

    echo "install $module_name /bin/true" > $modprobe_d_dir$module_name.conf
    rmmod "$module_name"

    if [[ "$(modprobe -n -v $module_name)" =~ $check_regex ]] && [[ "$(lsmod | grep $module_name)" =~ $module_name ]]; then
        echo "rm mod $module_name successful\n"
        LOG+="rm mod $module_name SUCCESSFUL"
        return 0
    fi

    echo "rm mod $module_name failed\n"
    LOG+="rm mod $module_name FAILED"
    return 2
}

isMounted() {
    local lookup_str="$1"
    local echo_msg_success="$2"
    local echo_msg_fail="$2" # need \n if need newline

    if [[ "$(mount)" =~ $lookup_str ]]; then
        echo -e "$echo_msg_success"
        return 1
    fi

    echo -ne "$echo_msg_fail"
    return 0
}

# disable cramfs
if [ "$DISABLE_CRAMFS" -eq 1 ]; then
    modprobe_disable "cramfs"
fi

# disable freevxfs
if [ "$DISABLE_FREEVXFS" -eq 1 ]; then
    modprobe_disable "freexvfs"
fi

# disable jffs2
if [ "$DISABLE_JFFS2" -eq 1 ]; then
    modprobe_disable "jffs2"
fi

# disable hfs
if [ "$DISABLE_HFS" -eq 1 ]; then
    modprobe_disable "hfs"
fi

# disable hfsplus
if [ "$DISABLE_HFSPLUS" -eq 1 ]; then
    modprobe_disable "hfsplus"
fi

# disable squashfs
if [ "$DISABLE_SQUASHFS" -eq 1 ]; then
    modprobe_disable "squashfs"
fi

# disable udf
if [ "$DISABLE_UDF" -eq 1 ]; then
    modprobe_disable "udf"
fi

# limit fat
if [ "$LIMIT_FAT" -eq 1 ]; then
    modprobe_disable "vfat"
fi

# tmp as partition (by default with nodev nosuid noexec)
if [ "$TMP_PART" -eq 1 ]; then
    isMounted "\s/tmp\s" "/tmp is already mounted\n" ""
    mounted=$?

    if [ "$mounted" -eq 0 ]; then
        echo "unmasking and enabling tmp.mount"
        systemctl unmask tmp.mount
        systemctl enable tmp.mount

        echo "writing settings to /etc/systemd/system/local-fs.target.wants/tmp.mount"

        echo -e "[Mount]\nWhat=tmpfs\nWhere=/tmp\n\nType=tmpfs\nOptions=mode=1777,strictatime,noexec,nodev,nosuid" > /etc/systemd/system/local-fs.target.wants/tmp.mount
    fi

    isMounted "\s/tmp\s" "/tmp has successfully mounted\n" "/tmp mounting failed"
    mounted=$?

    if [ "$mounted" -eq 0 ]; then
        LOG+="/tmp mounting FAILED"
    else
        LOG+="/tmp mounting SUCCESS"
    fi
fi

# disable automounting
if [ "$DISABLE_AUTOMOUNTING" -eq 1 ]; then
    if [[ ! "$(systemctl is-enabled autofs)" =~ "enabled" ]]; then
        echo "autofs is already disabled"
    else
        systemctl disable autofs

        if [[ ! "$(systemctl is-enabled autofs)" =~ "enabled" ]]; then
            echo "autofs is disabled"
            LOG+="auotfs disable SUCCESS"
        fi
    fi
fi

# disable usb-storage
if [ "$DISABLE_USB_STORAGE" -eq 1 ]; then
    modprobe_disable "usb-storage"
fi

# install aide
aide_installed=0
if [ "$INSTALL_AIDE" -eq 1 ]; then
    if command -v aide &> /dev/null; then
        echo "aide already installed"
        aide_installed=1

        if [ ! -f /var/lib/aide/aide.db.new.gz ] || [ ! -f /var/lib/aide/aide.db.gz ]; then
            echo "initializing aide"
            aide --init
        fi
    else
        if command -v yum &> /dev/null; then
            echo "installing aide with yum"
            yum install aide
        elif command -v dnf &> /dev/null; then
            echo "installing aide with dnf"
            dnf install aide
        elif command -v zypper &> /dev/null; then
            echo "installing aide with zypper"
            zypper install aide
        elif command -v apt &> /dev/null; then
            echo "installing aide with apt"
            apt install aide
        elif command -v apt-get &> /dev/null; then
            echo "installing aide with apt-get"
            apt-get install aide
        else
            echo "package manger not found, install aide yourself"
            LOG+="install aide FAILED"
            aide_installed=2
        fi

        if [ "$aide_installed" -eq 0 ]; then
            if command -v aide &> /dev/null; then
                echo "aide installed now!"
                LOG+="aide install SUCCESS"
                echo "initializing aide, may take a while"
                aide --init
                aide_installed=1
            fi
        fi
    fi
fi

if [ "$PERIODICALLY_CHECK_FILESYSTEM" -eq 1 ] && [ "$aide_installed" -eq 1 ]; then
    if [[ "$(cat crontab)" =~ "crontab: 0 5 * * * /usr/sbin/aide --check" ]] || { [[ "$(systemctl is-enabled aidecheck.service)" =~ "enabled" ]] && [[ "$(systemctl is-enabled aidecheck.timer)" =~ "enabled" ]] && [[ "$(systemctl status aidecheck.timer)" =~ "Active: active" ]]; }; then
        echo "aide already is in crontab"
    else
        echo "0 5 * * * /usr/sbin/aide --check" >> /etc/crontab
        echo "added cron job to /etc/crontab"
    fi
fi

echo -e "finished\n$LOG"