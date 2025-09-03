#!/bin/bash
set -o xtrace

# Write NodeConfig to file
cat > /tmp/nodeconfig.yaml << 'EOF'
${nodeconfig_content}
EOF

# Initialize node with nodeadm
/usr/bin/nodeadm init --config-source file:///tmp/nodeconfig.yaml