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
    echo "running this script with root is recommended\n"
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
        echo "$sshd_conf_path nonexistent or cannot be written to\n"
        return 1
    fi

    echo "$sshd_conf_path exists and is writable\n"
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

check_ssh_install
ssh_installed=$?
check_sshd_conf
sshd_conf_exists=$?

if [ "$ssh_installed" -ne 0 ] || [ "$sshd_conf_exists" -ne 0 ]; then    
    echo "checks unsuccessful"
    exit 1
fi

echo "checks are successful, proceeding with patching\n"
print_settings

# set log level
if [ "$SSH_LOG_LEVEL_VERBOSE" -eq 1 ]; then
    sed -i -E "s/^[#]*[[:space:]]*loglevel.*$/LogLevel VERBOSE/I" /etc/ssh/sshd_config
fi

# disable x11 forward
if [ "$SSH_DISABLE_X11_FORWARD" -eq 1 ]; then
    sed -i -E "s/^[#]*[[:space:]]*x11forwarding.*$/X11Forwarding no/I" /etc/ssh/sshd_config
fi

# set max auth tries
if [ "$SSH_MAX_AUTH_TRIES" -gt 0 ] && [ "$SSH_MAX_AUTH_TRIES" -le 3 ]; then
    sed -i -E "s/^[#]*[[:space:]]*maxauthtries.*$/MaxAuthTries $SSH_MAX_AUTH_TRIES/I" /etc/ssh/sshd_config
fi

# set ignore rhosts to true
if [ "$SSH_IGNORE_RHOSTS" -eq 1 ]; then
    sed -i -E "s/^[#]*[[:space:]]*ignorerhosts.*$/IgnoreRhosts yes/I" /etc/ssh/sshd_config
fi

# disable host based auth
if [ "$SSH_DISABLE_HOST_BASED_AUTH" -eq 1 ]; then
    sed -i -E "s/^[#]*[[:space:]]*hostbasedauthentication.*$/HostbasedAuthentication no/I" /etc/ssh/sshd_config
fi

# disable root login
if [ "$SSH_DISABLE_ROOT_LOGIN" -eq 1 ]; then
    sed -i -E "s/^[#]*[[:space:]]*permitrootlogin.*$/PermitRootLogin no/I" /etc/ssh/sshd_config
fi

# disable empty psswd
if [ "$SSH_DISABLE_EMPTY_PSSWD" -eq 1 ]; then
    sed -i -E "s/^[#]*[[:space:]]*permitemptypasswords.*$/PermitEmptyPasswords no/I" /etc/ssh/sshd_config
fi

# disable usr env
if [ "$SSH_DISABLE_USER_ENV" -eq 1 ]; then
    sed -i -E "s/^[#]*[[:space:]]*permituserenvironment.*$/PermitUserEnvironment no/I" /etc/ssh/sshd_config
fi

# set ssh to only use provided ciphers
if [ "$SSH_SET_STRONG_CIPHERS" -eq 1 ] && [ -n "$SSH_STRONG_CIPHER_LIST" ]; then
    sed -i -E "s/^[#]*[[:space:]]*ciphers.*$/Ciphers $SSH_STRONG_CIPHER_LIST/I" /etc/ssh/sshd_config
fi

# set ssh to only use provided mac algs
if [ "$SSH_SET_STRONG_MAC_ALG" -eq 1 ] && [ -n "$SSH_STRONG_MAC_ALGS" ]; then
    sed -i -E "s/^[#]*[[:space:]]*macs.*$/MACs $SSH_STRONG_MAC_ALGS/I" /etc/ssh/sshd_config
fi

# set ssh to only use provided key exchange algs
if [ "$SSH_STRONG_KEY_EX" -eq 1 ] && [ -n "$SSH_STRONG_KEY_EX_ALGS" ]; then
    sed -i -E "s/^[#]*[[:space:]]*keyalgorithms.*$/KexAlgorithms $SSH_STRONG_KEY_EX_ALGS/I" /etc/ssh/sshd_config
fi

# set timeout (must be less than 300s)
if [ "$SSH_SET_IDLE_TIMEOUT" -eq 1 ] && [ "$SSH_KICK_TIME" -le 300 ] && [ "$SSH_KICK_TIME" -gt 0 ]; then
    sed -i -E "s/^[#]*[[:space:]]*clientaliveinterval.*$/ClientAliveInterval $SSH_KICK_TIME/I" /etc/ssh/sshd_config
    sed -i -E "s/^[#]*[[:space:]]*clientalivecountmax.*$/ClientAliveCountMax $SSH_SEND_ALIVE_CHECK/I" /etc/ssh/sshd_config
fi

# set login grace time
if [ "$SSH_SET_LOGIN_GRACE" -eq 1 ] && [ "$SSH_LOGIN_GRACE_TIME" -gt 0 ]; then
    sed -i -E "s/^[#]*[[:space:]]*logingracetime.*$/LoginGraceTime $SSH_LOGIN_GRACE_TIME/I" /etc/ssh/sshd_config
fi

# limit ssh access
if [ "$SSH_LIMIT_ACCESS" -eq 1 ] && { [ -n "$SSH_ALLOW_USERS" ] || [ -n "$SSH_ALLOW_GROUPS" ] || [ -n "$SSH_DENY_USERS" ] || [ -n "$SSH_DENY_GROUPS" ]; }; then
    sed -i -E "s/^[#]*[[:space:]]*allowusers.*$/AllowUsers $SSH_ALLOW_USERS/I" /etc/ssh/sshd_config    
    sed -i -E "s/^[#]*[[:space:]]*allowgroups.*$/AllowGroups $SSH_ALLOW_GROUPS/I" /etc/ssh/sshd_config
    sed -i -E "s/^[#]*[[:space:]]*denyusers.*$/DenyUsers $SSH_DENY_USERS/I" /etc/ssh/sshd_config    
    sed -i -E "s/^[#]*[[:space:]]*denygroups.*$/DenyGroups $SSH_DENY_GROUPS/I" /etc/ssh/sshd_config
fi

# set banner
if [ "$SSH_SET_BANNER" -eq 1 ]; then
    sed -i -E "s|^[#]*[[:space:]]*banner.*$|Banner /etc/issue.net|I" /etc/ssh/sshd_config
fi

# enable pam
if [ "$SSH_ENABLE_PAM" -eq 1 ]; then
    sed -i -E "s/^[#]*[[:space:]]*usepam.*$/UsePAM yes/I" /etc/ssh/sshd_config
fi

# disable tcp forward
if [ "$SSH_DISABLE_TCP_FORWARD" -eq 1 ]; then
    sed -i -E "s/^[#]*[[:space:]]*allowtcpforwarding.*$/AllowTcpForwarding no/I" /etc/ssh/sshd_config
fi

# set max startups
if [ "$SSH_SET_MAX_STARTUPS" -eq 1 ] && [ -n "$SSH_MAX_STARTUP_VALUE" ]; then
    sed -i -E "s/^[#]*[[:space:]]*maxstartups.*$/MaxStartups $SSH_MAX_STARTUP_VALUE/I" /etc/ssh/sshd_config
fi

# set max sessions
if [ "$SSH_MAX_SESSIONS" -gt 0 ] && [ "$SSH_MAX_SESSIONS" -le 4 ]; then
    sed -i -E "s/^[#]*[[:space:]]*maxsessions.*$/MaxSessions $SSH_MAX_SESSIONS/I" /etc/ssh/sshd_config
fi