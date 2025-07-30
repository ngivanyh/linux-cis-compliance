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
    if [ ! -e $sshd_conf_path -o -w $sshd_conf_path ]; then
        echo "$sshd_conf_path nonexistent or cannot be written to"
        return 1
    fi

    echo "$sshd_conf_path exists and is writable"
    return 0
}

check_ssh_install
ssh_installed=$?
check_sshd_conf
sshd_conf_exists=$?

if [ "$ssh_installed" -eq 0 ] && [ "$sshd_conf_exists" -eq 0 ]; then    
    echo "checks successful"
fi
