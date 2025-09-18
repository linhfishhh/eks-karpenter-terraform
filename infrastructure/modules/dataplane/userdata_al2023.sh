#!/bin/bash
set -o xtrace

sudo swapoff -a
sed -i.bak '/\sswap\s/d' /etc/fstab
if [ -f /swapfile ]; then
    echo "[INFO] deleting swapfile"
    sudo rm -f /swapfile
fi

cat > /tmp/nodeconfig.yaml << 'EOF'
${nodeconfig_content}
EOF

/usr/bin/nodeadm init --config-source file:///tmp/nodeconfig.yaml