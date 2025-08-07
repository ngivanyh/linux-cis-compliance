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
WIRELESS_INTERFACES=""

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
    local flush="$2" # either just "ipv4" or "ipv6", if both "ipv4 ipv6"
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

    for flush_protocol in $flush; do
        sysctl -w "net.$flush_protocol.route.flush=1"
    done
    return 0
}

cp /etc/sysctl.conf ./sysctl.conf.bak
echo -e "copied original sysctl.conf file to $(pwd) under the name of sysctl.conf.bak\n"

# disable ip forward
if [ "$IP_FORWARD_DISABLE" -eq 1 ]; then
    sysctl_conf "net.ipv4.ip_forward=0 net.ipv6.conf.all.forwarding=0 " "ipv4 ipv6" "disable_ip_forward"
fi

# packet redirect disable
if [ "$PACKET_REDIRECT_DISABLE" -eq 1 ]; then
    sysctl_conf "net.ipv4.conf.all.send_redirects=0 net.ipv4.conf.default.send_redirects=0" "ipv4" "disable_packet_redirect"
fi

# reject source route packets
if [ "$REJECT_SOURCE_ROUTE_PCKTS" -eq 1 ]; then
    sysctl_conf "net.ipv4.conf.all.accept_source_route=0 net.ipv4.conf.default.accept_source_route=0 net.ipv6.conf.all.accept_source_route=0 net.ipv6.conf.default.accept_source_route=0" "ipv4 ipv6" "reject_source_route_pckts"
fi

# reject icmp redirects
if [ "$REJECT_ICMP_REDIRECTS" -eq 1 ]; then
    sysctl_conf "net.ipv4.conf.all.accept_redirects=0 net.ipv4.conf.default.accept_redirects=0 net.ipv6.conf.all.accept_redirects=0 net.ipv6.conf.default.accept_redirects=0" "ipv4 ipv6" "reject_icmp_redirects"
fi

# reject secure icmp redirects
if [ "$REJECT_SECURE_ICMP_REDIRECTS" -eq 1 ]; then
    sysctl_conf "net.ipv4.conf.all.secure_redirects=0 net.ipv4.conf.default.secure_redirects=0" "ipv4" "reject_secure_icmp_redirects"
fi

# log sus pckts
if [ "$LOG_SUSPICIOUS_PCKTS" -eq 1 ]; then
    sysctl_conf "net.ipv4.conf.all.log_martians=1 net.ipv4.conf.default.log_martians=1" "ipv4" "log_suspicious_pckts"
fi

# reject icmp broadcast req
if [ "$REJECT_BROADCAST_ICMP_REQ" -eq 1 ]; then
    sysctl_conf "net.ipv4.icmp_echo_ignore_broadcasts=1" "ipv4" "reject_broadcast_icmp_req"
fi

# ignore bogus icmp
if [ "$IGNORE_BOGUS_ICMP_RESPONSE" -eq 1 ]; then
    sysctl_conf "net.ipv4.icmp_ignore_bogus_error_responses=1" "ipv4" "ignore_bogus_icmp"
fi

# enbale reverse path filtering
if [ "$ENABLE_REVERSE_PATH_FILTERING" -eq 1 ]; then
    sysctl_conf "net.ipv4.conf.all.rp_filter=1 net.ipv4.conf.default.rp_filter=1" "ipv4" "enable_reverse_path_filtering"
fi

# enable tcp syn cookies
if [ "$ENABLE_TCP_SYN_COOKIES" -eq 1 ]; then
    sysctl_conf "net.ipv4.tcp_syncookies = 1" "ipv4" "enable_tcp_syn_cookies"
fi

# reject router ad (ipv6)
if [ "$REJECT_IPV6_ROUTER_ADVERTISEMENTS" -eq 1 ]; then
    sysctl_conf "net.ipv6.conf.all.accept_ra = 0 net.ipv6.conf.default.accept_ra = 0" "ipv6" "reject_ipv6_ra"
fi

# install (and check) iptables
iptables_installed=0
if [ "$INSTALL_IPTABLES" -eq 1 ]; then
    if command -v iptables &> /dev/null; then
        echo "iptables already installed"
        iptables_installed=1
    else
        if command -v yum &> /dev/null; then
            echo "installing iptables with yum"
            yum install iptables
        elif command -v dnf &> /dev/null; then
            echo "installing iptables with dnf"
            dnf install iptables
        elif command -v zypper &> /dev/null; then
            echo "installing iptables with zypper"
            zypper install iptables
        elif command -v apt &> /dev/null; then
            echo "installing iptables with apt"
            apt install iptables
        elif command -v apt-get &> /dev/null; then
            echo "installing iptables with apt-get"
            apt-get install iptables
        else
            echo "package manger not found, install iptables yourself"
            LOG+="install iptables FAILED"
            iptables_installed=2
        fi

        if [ "$iptables_installed" -eq 0 ]; then
            if command -v iptables &> /dev/null; then
                echo "iptables installed now!"
                LOG+="iptables install SUCCESS"
                iptables_installed=1
            fi
        fi
    fi
fi

if [ "$iptables_installed" -eq 1 ] && { [ "$IPV6_DISABLE_DEFAULT_DENY_POLICY" -eq 1 ] || [ "$IPV6_CONFIGURE_LO_TRAFFIC" -eq 1 ] || [ "$IPV4_DISABLE_DEFAULT_DENY_POLICY" -eq 1 ] || [ "$IPV4_CONFIGURE_LO_TRAFFIC" -eq 1 ]; }; then
    echo "the fixes for IPV6_DISABLE_DEFAULT_DENY_POLICY, IPV6_DISABLE_DEFAULT_DENY_POLICY, IPV4_DISABLE_DEFAULT_DENY_POLICY, and IPV4_DISABLE_DEFAULT_DENY_POLICY are all TEMPORARY"
    echo "these fixes MAY CAUSE YOU TO GET LOCKED OUT OF THE SYSTEM, if you don't want to continue type one of the words that fit in this regex /n[oa]*[yh]*/gmi"
    read continue

    if [[ $continue =~ "[nN][oaOA]*[YHyh]*" ]]; then
        echo "will not continue fixes"
    fi

    if [ "$IPV6_DISABLE_DEFAULT_DENY_POLICY" -eq 1 ] && [[ ! $continue =~ "[nN][oaOA]*[YHyh]*" ]]; then
        iptables_out="$(ip6tables -L)"
        if [[ $iptables_out =~ "^Chain FORWARD" && $iptables =~ "policy DROP" ]] && [[ $iptables_out =~ "^Chain INPUT" && $iptables =~ "policy DROP" ]] && [[ $iptables_out =~ "^Chain OUTPUT" && $iptables =~ "policy DROP" ]]; then
            echo "ipv6 disable default deny policy is enabled"
        else
            ip6tables -P INPUT DROP
            ip6tables -P OUTPUT DROP
            ip6tables -P FORWARD DROP
            if [[ $iptables_out =~ "^Chain FORWARD" && $iptables =~ "policy DROP" ]] && [[ $iptables_out =~ "^Chain INPUT" && $iptables =~ "policy DROP" ]] && [[ $iptables_out =~ "^Chain OUTPUT" && $iptables =~ "policy DROP" ]]; then
                echo "ipv6 disable default deny policy is now enabled"
                LOG+="ipv6 disable default deny policy SUCCESS"
            else
                echo "failed to disable ipv6 default deny policy"
                LOG+="ipv6 disable default deny policy FAILED"
            fi
        fi
    fi

    if [ "$IPV6_CONFIGURE_LO_TRAFFIC" -eq 1 ] && [[ ! $continue =~ "[nN][oaOA]*[YHyh]*" ]]; then
        iptables_out_input="$(ip6tables -L INPUT -v -n)"
        iptables_out_output="$(ip6tables -L OUTPUT -v -n)"
        if [[ $iptables_out_input =~ "\.*ACCEPT\.*all\.*lo\.*\p\.*::/0\.*::/0" ]] && [[ $iptables_out_input =~ "\.*DROP\.*all\.*lo\.*\p\.*::/0\.*::/0" ]] && [[ $iptables_out_output =~ "\.*ACCEPT\.*all\.*lo\.*\p\.*::/0\.*::/0" ]]; then
            echo "ipv6 disable default deny policy is enabled"
        else
            ip6tables -A INPUT -i lo -j ACCEPT
            ip6tables -A OUTPUT -o lo -j ACCEPT
            ip6tables -A INPUT -s ::1 -j DROP
            if [[ $iptables_out_input =~ "\.*ACCEPT\.*all\.*lo\.*\p\.*::/0\.*::/0" ]] && [[ $iptables_out_input =~ "\.*DROP\.*all\.*lo\.*\p\.*::/0\.*::/0" ]] && [[ $iptables_out_output =~ "\.*ACCEPT\.*all\.*lo\.*\p\.*::/0\.*::/0" ]]; then
                echo "configured ipv6 loopback traffic"
                LOG+="ipv6 loopback traffic config SUCCESS"
            else
                echo "failed to configured ipv6 loopback traffic"
                LOG+="ipv6 loopback traffic config FAILED"
            fi
        fi  
    fi

    if [ "$IPV4_CONFIGURE_LO_TRAFFIC" -eq 1 ] && [[ ! $continue =~ "[nN][oaOA]*[YHyh]*" ]]; then
        iptables_out_input="$(iptables -L INPUT -v -n)"
        iptables_out_output="$(iptables -L OUTPUT -v -n)"
        if [[ $iptables_out_input =~ "\.*ACCEPT\.*all\.*lo\.*\p\.*::/0\.*::/0" ]] && [[ $iptables_out_input =~ "\.*DROP\.*all\.*lo\.*\p\.*::/0\.*::/0" ]] && [[ $iptables_out_output =~ "\.*ACCEPT\.*all\.*lo\.*\p\.*::/0\.*::/0" ]]; then
            echo "ipv4 disable default deny policy is enabled"
        else
            iptables -A INPUT -i lo -j ACCEPT 
            iptables -A OUTPUT -o lo -j ACCEPT 
            iptables -A INPUT -s 127.0.0.0/8 -j DROP
            if [[ $iptables_out_input =~ "\.*ACCEPT\.*all\.*lo\.*\p\.*::/0\.*::/0" ]] && [[ $iptables_out_input =~ "\.*DROP\.*all\.*lo\.*\p\.*::/0\.*::/0" ]] && [[ $iptables_out_output =~ "\.*ACCEPT\.*all\.*lo\.*\p\.*::/0\.*::/0" ]]; then
                echo "configured ipv4 loopback traffic"
                LOG+="ipv4 loopback traffic config SUCCESS"
            else
                echo "failed to configured ipv4 loopback traffic"
                LOG+="ipv4 loopback traffic config FAILED"
            fi
        fi  
    fi

    if [ "$IPV4_DISABLE_DEFAULT_DENY_POLICY" -eq 1 ] && [[ ! $continue =~ "[nN][oaOA]*[YHyh]*" ]]; then
        iptables_out="$(iptables -L)"
        if [[ $iptables_out =~ "^Chain FORWARD" && $iptables_out =~ "policy DROP" ]] && [[ $iptables_out =~ "^Chain INPUT" && $iptables_out =~ "policy DROP" ]] && [[ $iptables_out =~ "^Chain OUTPUT" && $iptables_out =~ "policy DROP" ]]; then
            echo "ipv4 disable default deny policy is enabled"
        else
            iptables -P INPUT DROP
            iptables -P OUTPUT DROP
            iptables -P FORWARD DROP
            if [[ $iptables_out =~ "^Chain FORWARD" && $iptables_out =~ "policy DROP" ]] && [[ $iptables_out =~ "^Chain INPUT" && $iptables_out =~ "policy DROP" ]] && [[ $iptables_out =~ "^Chain OUTPUT" && $iptables_out =~ "policy DROP" ]]; then
                echo "ipv4 disable default deny policy is now enabled"
                LOG+="ipv4 disable default deny policy SUCCESS"
            else
                echo "failed to disable ipv4 default deny policy"
                LOG+="ipv4 disable default deny policy FAILED"
            fi
        fi
    fi

fi

if [ "$DISABLE_WIRELESS_INTERFACE" -eq 1 ] && [ -z "$WIRELESS_INTERFACES" ]; then
    if [ "$(nmcli radio wwan)" = "disabled" ] && [ "$(nmcli radio wifi)" = "disabled" ]; then
        echo "wireless interfaces already disabled"
    else
        ip link set "$WIRELESS_INTERFACES"
        if [ "$(nmcli radio wwan)" = "disabled" ] && [ "$(nmcli radio wifi)" = "disabled" ]; then
            echo "wirelss interfaces now disabled"
            LOG+="wireless interface disabling SUCCESS"
        else
            echo "wirelss interface disabling failed"
            LOG+="wireless interface disabling FAILED"
        fi
    fi
fi

echo -e "finsished\n$LOG"