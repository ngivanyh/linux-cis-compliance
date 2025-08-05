# configures ssh to be more secure

# log variable, stores changes
LOG="LOG:\n"

# config, 1 = yes (to the security fixes) / 0 = no (keep it the way it was)
SSH_LOG_LEVEL_VERBOSE=1

SSH_DISABLE_X11_FORWARD=1

SSH_MAX_AUTH_TRIES=3 # 0 if you don't want to change it

SSH_IGNORE_RHOSTS=1

SSH_DISABLE_HOST_BASED_AUTH=1

SSH_DISABLE_ROOT_LOGIN=1

SSH_DISABLE_EMPTY_PSSWD=1

SSH_DISABLE_USER_ENV=1

SSH_SET_STRONG_CIPHERS=1
SSH_STRONG_CIPHER_LIST=""

SSH_SET_STRONG_MAC_ALG=1
SSH_STRONG_MAC_ALGS=""

SSH_STRONG_KEY_EX=1
SSH_STRONG_KEY_EX_ALGS=""

SSH_SET_IDLE_TIMEOUT=1
SSH_KICK_TIME=300 # client alive interval (less than 300)
SSH_SEND_ALIVE_CHECK=0 # client alive count max

SSH_SET_LOGIN_GRACE=1
SSH_LOGIN_GRACE_TIME=60

SSH_LIMIT_ACCESS=1
SSH_ALLOW_USERS=""
SSH_ALLOW_GROUPS=""
SSH_DENY_USERS=""
SSH_DENY_GROUPS=""

SSH_SET_BANNER=1

SSH_ENABLE_PAM=1

SSH_DISABLE_TCP_FORWARD=1

SSH_SET_MAX_STARTUPS=1
SSH_MAX_STARTUP_VALUE="10:30:60"

SSH_MAX_SESSIONS=4 # 0 if don't want to enable

if [ "$EUID" -ne 0 ]; then
    echo "run this script with root"
    exit 1
fi

check_ssh_install() {
    # Check for ssh client
    if ! command -v ssh &> /dev/null; then
        echo "err: ssh not found"
        return 1
    fi

    # Check for sshd server
    if ! command -v sshd &> /dev/null; then
        echo "err: sshd not found"
        return 2
    fi

    echo "ssh and sshd are installed."
    return 0
}

check_sshd_conf() {
    sshd_conf_path="/etc/ssh/sshd_config"
    if [ ! -f "$sshd_conf_path" ] || [ ! -w "$sshd_conf_path" ]; then
        echo -e "$sshd_conf_path nonexistent or cannot be written to\n"
        return 1
    fi

    echo -e "$sshd_conf_path exists and is writable\n"
    return 0
}

print_settings() {
    echo "SSH_LOG_LEVEL_VERBOSE: $SSH_LOG_LEVEL_VERBOSE"
    echo "SSH_DISABLE_X11_FORWARD: $SSH_DISABLE_X11_FORWARD"
    echo "SSH_MAX_AUTH_TRIES: $SSH_MAX_AUTH_TRIES"
    echo "SSH_IGNORE_RHOSTS: $SSH_IGNORE_RHOSTS"
    echo "SSH_DISABLE_HOST_BASED_AUTH: $SSH_DISABLE_HOST_BASED_AUTH"
    echo "SSH_DISABLE_ROOT_LOGIN: $SSH_DISABLE_ROOT_LOGIN"
    echo "SSH_DISABLE_EMPTY_PSSWD: $SSH_DISABLE_EMPTY_PSSWD"
    echo "SSH_DISABLE_USER_ENV: $SSH_DISABLE_USER_ENV"
    echo "SSH_SET_STRONG_CIPHERS: $SSH_SET_STRONG_CIPHERS"
    echo "SSH_STRONG_CIPHER_LIST: \"$SSH_STRONG_CIPHER_LIST\""
    echo "SSH_SET_STRONG_MAC_ALG: $SSH_SET_STRONG_MAC_ALG"
    echo "SSH_STRONG_MAC_ALGS: \"$SSH_STRONG_MAC_ALGS\""
    echo "SSH_STRONG_KEY_EX: $SSH_STRONG_KEY_EX"
    echo "SSH_STRONG_KEY_EX_ALGS: \"$SSH_STRONG_KEY_EX_ALGS\""
    echo "SSH_SET_IDLE_TIMEOUT: $SSH_SET_IDLE_TIMEOUT"
    echo "SSH_KICK_TIME: $SSH_KICK_TIME"
    echo "SSH_SEND_ALIVE_CHECK: $SSH_SEND_ALIVE_CHECK"
    echo "SSH_SET_LOGIN_GRACE: $SSH_SET_LOGIN_GRACE"
    echo "SSH_LOGIN_GRACE_TIME: $SSH_LOGIN_GRACE_TIME"
    echo "SSH_LIMIT_ACCESS: $SSH_LIMIT_ACCESS"
    echo "SSH_ALLOW_USERS: \"$SSH_ALLOW_USERS\""
    echo "SSH_ALLOW_GROUPS: \"$SSH_ALLOW_GROUPS\""
    echo "SSH_DENY_USERS: \"$SSH_DENY_USERS\""
    echo "SSH_DENY_GROUPS: \"$SSH_DENY_GROUPS\""
    echo "SSH_SET_BANNER: $SSH_SET_BANNER"
    echo "SSH_ENABLE_PAM: $SSH_ENABLE_PAM"
    echo "SSH_DISABLE_TCP_FORWARD: $SSH_DISABLE_TCP_FORWARD"
    echo "SSH_SET_MAX_STARTUPS: $SSH_SET_MAX_STARTUPS"
    echo "SSH_MAX_STARTUP_VALUE: $SSH_MAX_STARTUP_VALUE"
    echo "SSH_MAX_SESSIONS: $SSH_MAX_SESSIONS"
}

apply() {
    local setting="$1" # setting name
    local config_option="$2" # setting value
    local full_setting="$setting $config_option"

    # remove all comments related to setting
    sed -i -E "/^#+[[:space:]]*$setting.*$/Id" /etc/ssh/sshd_config

    # check if setting already exists
    if cat /etc/ssh/sshd_config | grep -qE "^[[:space:]]*$full_setting$"; then
        echo "\"$full_setting\" fix already applied, unchanged"
        return 1
    fi

    echo "applying $full_setting"
    # add setting
    if cat /etc/ssh/sshd_config | grep -qEi "^[[:space:]]*$setting.*$"; then
        echo "overwriting previous setting"
        sed -i -E "s/^[[:space:]]*$setting.*$/$full_setting/I" /etc/ssh/sshd_config
    else
        echo "adding new setting"
        echo "$full_setting" >> /etc/ssh/sshd_config
    fi

    # check if applied
    if sshd -T | grep -qEi "$full_setting"; then
        echo -e "$full_setting successfully applied\n"
        LOG+="$full_setting SUCCESS\n"
        return 0
    fi

    echo "$full_setting application unsuccessful"
    LOG+="$full_setting FAIL\n"
    return 2
}

check_ssh_install
ssh_installed=$?
check_sshd_conf
sshd_conf_exists=$?

if [ "$ssh_installed" -ne 0 ] || [ "$sshd_conf_exists" -ne 0 ]; then    
    echo "checks unsuccessful"
    exit 2
fi

echo -e "checks are successful, proceeding with patching\n"
print_settings
echo

cp /etc/ssh/sshd_config .
mv ./sshd_config ./sshd_config.bak
echo -e "copied original sshd_config file to $(pwd) under the name of sshd_config.bak\n"

# set log level
if [ "$SSH_LOG_LEVEL_VERBOSE" -eq 1 ]; then
    apply "LogLevel" "VERBOSE"
fi

# disable x11 forward
if [ "$SSH_DISABLE_X11_FORWARD" -eq 1 ]; then
    apply "X11Forwarding" "no"
fi

# set max auth tries
if [ "$SSH_MAX_AUTH_TRIES" -gt 0 ] && [ "$SSH_MAX_AUTH_TRIES" -le 3 ]; then
    apply "MaxAuthTries" "$SSH_MAX_AUTH_TRIES"
fi

# set ignore rhosts to true
if [ "$SSH_IGNORE_RHOSTS" -eq 1 ]; then
    apply "IgnoreRhosts" "yes"
fi

# disable host based auth
if [ "$SSH_DISABLE_HOST_BASED_AUTH" -eq 1 ]; then
    apply "HostbasedAuthentication" "no"
fi

# disable root login
if [ "$SSH_DISABLE_ROOT_LOGIN" -eq 1 ]; then
    apply "PermitRootLogin" "no"
fi

# disable empty psswd
if [ "$SSH_DISABLE_EMPTY_PSSWD" -eq 1 ]; then
    apply "PermitEmptyPasswords" "no"
fi

# disable usr env
if [ "$SSH_DISABLE_USER_ENV" -eq 1 ]; then
    apply "PermitUserEnvironment" "no"
fi

# set ssh to only use provided ciphers
if [ "$SSH_SET_STRONG_CIPHERS" -eq 1 ] && [ -n "$SSH_STRONG_CIPHER_LIST" ]; then
    apply "Ciphers" "$SSH_STRONG_CIPHER_LIST"
fi

# set ssh to only use provided mac algs
if [ "$SSH_SET_STRONG_MAC_ALG" -eq 1 ] && [ -n "$SSH_STRONG_MAC_ALGS" ]; then
    apply "MACs" "$SSH_STRONG_MAC_ALGS"
fi

# set ssh to only use provided key exchange algs
if [ "$SSH_STRONG_KEY_EX" -eq 1 ] && [ -n "$SSH_STRONG_KEY_EX_ALGS" ]; then
    apply "KexAlgorithms" "$SSH_STRONG_KEY_EX_ALGS"
fi

# set timeout (must be less than 300s)
if [ "$SSH_SET_IDLE_TIMEOUT" -eq 1 ] && [ "$SSH_KICK_TIME" -le 300 ] && [ "$SSH_KICK_TIME" -gt 0 ]; then
    apply "ClientAliveInterval" "$SSH_KICK_TIME"
    apply "ClientAliveCountMax" "$SSH_SEND_ALIVE_CHECK"
fi

# set login grace time
if [ "$SSH_SET_LOGIN_GRACE" -eq 1 ] && [ "$SSH_LOGIN_GRACE_TIME" -gt 0 ]; then
    apply "LoginGraceTime" "$SSH_LOGIN_GRACE_TIME"
fi

# limit ssh access
if [ "$SSH_LIMIT_ACCESS" -eq 1 ] && { [ -n "$SSH_ALLOW_USERS" ] || [ -n "$SSH_ALLOW_GROUPS" ] || [ -n "$SSH_DENY_USERS" ] || [ -n "$SSH_DENY_GROUPS" ]; }; then
    apply "AllowUsers" "$SSH_ALLOW_USERS"
    apply "AllowGroups" "$SSH_ALLOW_GROUPS"
    apply "DenyUsers" "$SSH_DENY_USERS"
    apply "DenyGroups" "$SSH_DENY_GROUPS"
fi

# set banner
if [ "$SSH_SET_BANNER" -eq 1 ]; then
    apply "Banner" "/etc/issue.net"
fi

# enable pam
if [ "$SSH_ENABLE_PAM" -eq 1 ]; then
    apply "UsePAM" "yes"
fi

# disable tcp forward
if [ "$SSH_DISABLE_TCP_FORWARD" -eq 1 ]; then
    apply "AllowTcpForwarding" "no"
fi

# set max startups
if [ "$SSH_SET_MAX_STARTUPS" -eq 1 ] && [ -n "$SSH_MAX_STARTUP_VALUE" ]; then
    apply "MaxStartups" "$SSH_MAX_STARTUP_VALUE"
fi

# set max sessions
if [ "$SSH_MAX_SESSIONS" -gt 0 ] && [ "$SSH_MAX_SESSIONS" -le 4 ]; then
    apply "MaxSessions" "$SSH_MAX_SESSIONS"
fi

echo -e "finished applying fixes, restarting ssh daemon\n"

systemctl restart sshd

echo -e "$LOG"