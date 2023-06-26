#!/bin/bash
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root." 
   exit 1
fi

# Start.
echo "BSC Fullnode Installer - GitHub: @dennohpeter"
echo "Credits - PhatJay and tarik0 for those steps."

# Download NPM and PM2.
echo "Installing NPM and PM2..."
apt update
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 
nvm install node
npm i --location=global pm2

# Download unzip.
echo "Installing unzip..."
apt install unzip

# Create new GETH user.
echo "Creating new GETH user..."
sudo useradd -m geth

# Download the latest geth.
echo "Downloading the latest GETH..."
wget -O /home/geth/geth_linux https://github.com/binance-chain/bsc/releases/latest/download/geth_linux
chmod +x /home/geth/geth_linux

# Create the start.sh.
echo "./geth_linux --config ./config.toml --datadir ./data  --txlookuplimit=0 --syncmode=full --tries-verify-mode=none --pruneancient=true --diffblock=5000" > /home/geth/start.sh
chmod +x /home/geth/start.sh

# Download the latest mainnet config.
echo "Downloading the latest BSC mainnet config..."
wget -O /home/geth/mainnet.zip https://github.com/binance-chain/bsc/releases/latest/download/mainnet.zip

# Unzip mainnet
echo "Unzipping mainnet.zip..."
unzip /home/geth/mainnet.zip -d /home/geth

# Setup snapshot

# Setup systemd
echo "Setting systemd..."
echo "[Unit]" >> /lib/systemd/system/geth.service
echo "Description=BSC Full Node" >> /lib/systemd/system/geth.service
echo "" >> /lib/systemd/system/geth.service
echo "[Service]" >> /lib/systemd/system/geth.service
echo "User=geth" >> /lib/systemd/system/geth.service
echo "Type=simple" >> /lib/systemd/system/geth.service
echo "WorkingDirectory=/home/geth" >> /lib/systemd/system/geth.service
echo "ExecStart=/bin/bash /home/geth/start.sh" >> /lib/systemd/system/geth.service
echo "Restart=on-failure" >> /lib/systemd/system/geth.service
echo "RestartSec=5" >> /lib/systemd/system/geth.service
echo "" >> /lib/systemd/system/geth.service
echo "[Install] " >> /lib/systemd/system/geth.service
echo "WantedBy=default.target" >> /lib/systemd/system/geth.service

chown -R geth.geth /home/geth/*
systemctl enable geth

# Setting the util scripts.
echo "Setting the utility scripts..."
echo "./geth_linux attach http://localhost:8545 --exec eth.syncing" > /home/geth/check_sync.sh
chmod +x /home/geth/check_sync.sh
echo "tail -f /home/geth/node/bsc.log" > /home/geth/show_logs.sh
chmod +x /home/geth/show_logs.sh
echo "systemctl stop geth" >> /home/geth/prune.sh
echo "./geth_linux snapshot prune-state --datadir ./node" >> /home/geth/prune.sh
echo "chown -R geth.geth ./node" >> /home/geth/prune.sh
echo "systemctl start geth" >> /home/geth/prune.sh
chmod +x /home/geth/prune.sh

# Finish.
echo ""
echo "Latest version of the BSC Geth is installed!"
echo "How to start:             'systemctl start geth'"
echo "How to stop:              'systemctl stop geth'"
echo "How to check logs:        '/home/geth/show_logs.sh'"
echo "How to check sync status: '/home/geth/check_sync.sh'"
echo "How to prune:             '/home/geth/prune.sh'"
echo "Pruning takes time so if you are in SSH shell increase your timeout."
echo "(or you can run it with PM2 so you can tail logs etc.)"
