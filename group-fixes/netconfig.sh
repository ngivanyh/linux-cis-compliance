# LOG var used for logging
LOG="LOG:\n"

# sysctl.conf network confs
IP_FORWARD_DISABLE=1
PACKET_REDIRECT_DISABLE=1
REJECT_SOURCE_ROUTE_PCKTS=1
REJECT_ICMP_REDIRECTS=1
REJECT_SECURE_ICMP_REDIRECTS=1
LOG_SUSPICIOUS_PCKTS=1
REJECT_BROADCAST_ICMP_REQ=1
IGNORE_BOGUS_ICMP_RESPONSE=1
ENABLE_REVERSE_PATH_FILTERING=1
ENABLE_TCP_SYN_COOKIES=1
REJECT_IPV6_ROUTER_ADVERTISEMENTS=1

# iptables conf
INSTALL_IPTABLES=1
IPV6_DISABLE_DEFAULT_DENY_POLICY=1
IPV6_CONFIGURE_LO_TRAFFIC=1
IPV4_DISABLE_DEFAULT_DENY_POLICY=1
IPV4_CONFIGURE_LO_TRAFFIC=1

# misc
DISABLE_WIRELESS_INTERFACE=1

if [ "$EUID" -ne 0 ]; then
    echo "run this script as root"
    exit 1
fi

print_settings() {
    echo "IP_FORWARD_DISABLE: "$IP_FORWARD_DISABLE""
    echo "PACKET_REDIRECT_DISABLE: "$PACKET_REDIRECT_DISABLE""
    echo "REJECT_SOURCE_ROUTE_PCKTS: "$REJECT_SOURCE_ROUTE_PCKTS""
    echo "REJECT_ICMP_REDIRECTS: "$REJECT_ICMP_REDIRECTS""
    echo "REJECT_SECURE_ICMP_REDIRECTS: "$REJECT_SECURE_ICMP_REDIRECTS""
    echo "LOG_SUSPICIOUS_PCKTS: "$LOG_SUSPICIOUS_PCKTS""
    echo "REJECT_BROADCAST_ICMP_REQ: "$REJECT_BROADCAST_ICMP_REQ""
    echo "IGNORE_BOGUS_ICMP_RESPONSE: "$IGNORE_BOGUS_ICMP_RESPONSE""
    echo "ENABLE_REVERSE_PATH_FILTERING: "$ENABLE_REVERSE_PATH_FILTERING""
    echo "ENABLE_TCP_SYN_COOKIES: "$ENABLE_TCP_SYN_COOKIES""
    echo "REJECT_IPV6_ROUTER_ADVERTISEMENTS: "$REJECT_IPV6_ROUTER_ADVERTISEMENTS""
    echo "INSTALL_IPTABLES: "$INSTALL_IPTABLES""
    echo "IPV6_DISABLE_DEFAULT_DENY_POLICY: "$IPV6_DISABLE_DEFAULT_DENY_POLICY""
    echo "IPV6_CONFIGURE_LO_TRAFFIC: "$IPV6_CONFIGURE_LO_TRAFFIC""
    echo "IPV4_DISABLE_DEFAULT_DENY_POLICY: "$IPV4_DISABLE_DEFAULT_DENY_POLICY""
    echo "IPV4_CONFIGURE_LO_TRAFFIC: "$IPV4_CONFIGURE_LO_TRAFFIC""
    echo "DISABLE_WIRELESS_INTERFACE: "$DISABLE_WIRELESS_INTERFACE""
}

sysctl_conf() {
    local settings="$1" # either one setting, or settings separated by spaces (e.g. net.setting=1)
    local flush="$2" # either just "ipv4" or "ipv6", if both "ipvALL"
    local opt_filename="$3" # for when using sysctl.d

    local conf_path="" # either sysctl.conf or sysctl.d

    if [ -f /etc/sysctl.conf ] && [ -d /etc/sysctl.d/ ]; then
        echo "both /etc/sysctl.conf and /etc/sysctl.d exist. will use /etc/sysctl.d to configure networking settings, each call to the function will create a separate file"
        conf_path="sysctl.d"
    elif [ ! -f /etc/sysctl.conf ] && [ -d /etc/sysctl.d/ ]; then
        echo "only /etc/sysctl.d exists. will use that directory to configure networking settings"
        conf_path="sysctl.d"
    elif [ -f /etc/sysctl.conf ] && [ ! -d /etc/sysctl.d/ ]; then
        echo "only /etc/sysctl.conf exists. will use that file to configure networking settings"
        conf_path="sysctl.conf"
    else
        echo -e "no /etc/sysctl.conf OR /etc/sysctl.d/ cannot continue\n"
        return 1
    fi

    if [ "$conf_path" = "sysctl.d" ] && [ -z "$opt_filename" ]; then
        echo "set a opt_filename because you're adding a new file to /etc/sysctl.d/"
        return 2
    fi

    local applied=""
    local setting_name=""
    local setting_value=""

    # local applied_setting_names=""
    # local applied_setting_values=""

    for setting in $settings; do
        setting_name="$(echo $setting | cut -d'=' -f1)"
        setting_value="$(echo $setting | cut -d'=' -f2)"
        if [ "$(sysctl -n "$setting_name")" = "$setting_value" ];
            echo "$setting is already applied, skipping"
        else
            echo "applying $setting"
            applied+="$setting "
            if [ $conf_path = "sysctl.conf" ]; then
                echo "appending $setting to sysctl.conf"
                if grep -qE "^$setting_name" /etc/sysctl.conf; then
                    sed -i "s/^$setting_name.*/$setting/" /etc/sysctl.conf
                else
                    echo "$setting" >> /etc/sysctl.conf
                fi
                LOG+="ADDED $setting to /etc/sysctl.conf"
                sysctl -w "$setting"
            else
                echo "appending $setting to /etc/sysctl.d/$opt_filename"
                local replaced="no"
                for f in /etc/sysctl.d/*; do
                    if grep -qE "^$setting_name" "$f"; then
                        sed -i "s/^$setting_name.*/$setting/" "$f"
                        echo "replaced setting in existing file $f"
                        LOG+="replaced existing setting $setting_name in $f"
                        replaced="yes"
                    fi
                done

                if [ "$replaced" = "no" ]; then
                    echo "$setting" >> /etc/sysctl.d/$opt_filename
                    LOG+="ADDED $setting to /etc/sysctl.d/$opt_filename"
                fi
                sysctl -w "$setting"
            fi

            if [ "$(sysctl -n "$setting_name")" = "$setting_value" ]; then
                echo "successfully set $setting"
                LOG+="set $setting SUCCESS"
            fi
        fi
    done

    if [ -z "$applied" ]; then
        echo "no settings applied"
        return 3
    fi

    if [ "$flush" = "ipvALL" ]; then
        sysctl -w net.ipv4.route.flush=1 
        sysctl -w net.ipv6.route.flush=1
    else
        sysctl -w "net.$flush.route.flush=1"
    fi
    return 0
}