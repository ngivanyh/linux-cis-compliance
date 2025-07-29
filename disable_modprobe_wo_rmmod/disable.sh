mod=""

sh -c 'sudo echo “install $mod /bin/true” > /etc/modprobe.d/$mod.conf'

lsmod | grep "$mod"

# shouldn't output anything
