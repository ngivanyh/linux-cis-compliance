mod=""

sh -c 'sudo echo “install $mod /bin/true” > /etc/modprobe.d/$mod.conf'

rmmod $mod

lsmod | grep "$mod"

# shouldn't output anything
