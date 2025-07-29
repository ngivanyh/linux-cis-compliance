read -p "rm filesystem: " filesystem

sh -c 'sudo echo “install $filesystem /bin/true” > /etc/modprobe.d/$filesystem.conf'

lsmod | grep "$filesystem"

if [$? -eq 1]; then
    ehco "success"
else
    echo "failure"
fi
