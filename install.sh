#!/usr/bin/env bash

cd "$(realpath "$(dirname "$0")")" || exit
echo "Myaoogle - amateur search engine"
sudo apt update -y
mkdir -p apps temp data/share/log
echo PATH="$PATH:/home/$USER/.local/bin:$PWD/bin:/usr/local/go/bin" | sudo tee /etc/environment
echo MYAOOGLE="$PWD" | sudo tee -a /etc/environment
echo IPFS_PATH="$PWD/data/.ipfs" | sudo tee -a /etc/environment
export PATH="$PATH:/home/$USER/.local/bin:$PWD/bin:/usr/local/go/bin"
export MYAOOGLE="$(pwd)"
export IPFS_PATH=$PWD/data/.ipfs
(echo -e "$(date -u) Myaoogle installation started.") >> $PWD/data/log.txt
echo "Myaoogle dirname : [$(realpath "$(dirname "$0")")]"
read -p "Enter IPFS port(default 4003): " IPFSPORT
if [ -z "$IPFSPORT" ]; then
    IPFSPORT=4003
fi

sudo DEBIAN_FRONTEND=noninteractive apt full-upgrade -yq
sudo DEBIAN_FRONTEND=noninteractive apt install -y git docker.io docker-compose-v2 build-essential python3-dev python3-pip python3-venv tmux cron iputils-ping net-tools unzip btop
sudo usermod -aG docker $USER
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install --upgrade pip
pip install reader -q

sudo mkdir /ipfs /ipns
sudo chmod 777 /ipfs
sudo chmod 777 /ipns
wget -O temp/kubo.tar.gz https://github.com/ipfs/kubo/releases/download/v0.33.2/kubo_v0.33.2_linux-amd64.tar.gz
tar xvzf temp/kubo.tar.gz -C temp
sudo mv temp/kubo/ipfs /usr/local/bin/ipfs
ipfs init --profile server
ipfs config --json Experimental.FilestoreEnabled true
ipfs config --json Pubsub.Enabled true
ipfs config --json Ipns.UsePubsub true
ipfs config profile apply lowpower
ipfs config Addresses.Gateway /ip4/127.0.0.1/tcp/8082
ipfs config Addresses.API /ip4/127.0.0.1/tcp/5002
sed -i "s/4001/$IPFSPORT/g" $PWD/data/.ipfs/config
sed -i "s/104.131.131.82\/tcp\/$IPFSPORT/104.131.131.82\/tcp\/4001/g" $PWD/data/.ipfs/config
sed -i "s/104.131.131.82\/udp\/$IPFSPORT/104.131.131.82\/udp\/4001/g" $PWD/data/.ipfs/config
ipfs config --json Swarm.EnableAutoNATService true
ipfs config --json Swarm.EnableAutoRelay true
echo -e "\
[Unit]\n\
Description=InterPlanetary File System (IPFS) daemon\n\
Documentation=https://docs.ipfs.tech/\n\
After=network.target\n\
\n\
[Service]\n\
MemorySwapMax=0\n\
TimeoutStartSec=infinity\n\
Type=notify\n\
User=$USER\n\
Group=$USER\n\
Environment=IPFS_PATH=$PWD/data/.ipfs\n\
ExecStart=/usr/local/bin/ipfs daemon --enable-gc --mount --mount-ipfs=/ipfs --mount-ipns=/ipns --migrate=true\n\
Restart=on-failure\n\
KillSignal=SIGINT\n\
\n\
[Install]\n\
WantedBy=default.target\n\
" | sudo tee /etc/systemd/system/ipfs.service
sudo systemctl daemon-reload
sudo systemctl enable ipfs
sudo systemctl restart ipfs
cat <<EOF >>$PWD/bin/ipfssub.sh
#!/usr/bin/env bash
/usr/local/bin/ipfs pubsub sub myaoogle >> $PWD/data/sub.txt
EOF
chmod +x $PWD/bin/ipfssub.sh
echo -e "\
[Unit]\n\
Description=InterPlanetary File System (IPFS) subscription\n\
After=network.target\n\
\n\
[Service]\n\
Type=simple\n\
User=$USER\n\
Group=$USER\n\
Environment=IPFS_PATH=$PWD/data/.ipfs\n\
ExecStartPre=/usr/bin/sleep 5\n\
ExecStart=$PWD/bin/ipfssub.sh\n\
Restart=on-failure\n\
KillSignal=SIGINT\n\
\n\
[Install]\n\
WantedBy=default.target\n\
" | sudo tee /etc/systemd/system/ipfssub.service
sudo systemctl daemon-reload
sudo systemctl enable ipfssub
sudo systemctl restart ipfssub
sleep 9

cd $MYAOOGLE
sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt install -y ca-certificates curl gnupg
sudo rm /etc/apt/keyrings/nodesource.gpg
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
NODE_MAJOR=22
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt-get update && sudo apt-get install nodejs -y
node -v
npm -v

wget -O temp/ygg.deb https://github.com/yggdrasil-network/yggdrasil-go/releases/download/v0.5.12/yggdrasil-0.5.12-amd64.deb
sudo dpkg -i temp/ygg.deb
sudo yggdrasil -genconf | tee /etc/yggdrasil/yggdrasil.conf
sudo sed -i "s/Peers\: \[\]/Peers\: \[\n    tls\:\/\/185.103.109.63\:65534\n    tcp\:\/\/193.107.20.230\:7743\n    quic\:\/\/vpn.itrus.su\:7993\n  ]/g" /etc/yggdrasil/yggdrasil.conf
sudo sed -i "s/NodeInfo\: {}/NodeInfo\: {\n  name: myaoogle$(date -u +%Y%m%d%H%M%S)$HOSTNAME\n  }/g" /etc/yggdrasil/yggdrasil.conf
sudo systemctl daemon-reload
sudo systemctl enable yggdrasil
sudo systemctl restart yggdrasil
sleep 5
ping -6 -c 6 21e:a51c:885b:7db0:166e:927:98cd:d186 #Yggdrasil Web directory
yggbootstrap.sh

export YGGIP=$(ip -6 addr show tun0 | grep 'inet6' | grep 'scope global' | awk '{print $2}' | cut -d'/' -f1)
echo YGGIP="$YGGIP" | sudo tee -a /etc/environment
sudo apt install -y nginx software-properties-common
sudo add-apt-repository -y ppa:ondrej/php
sudo apt update
sudo systemctl start nginx
sudo systemctl enable nginx
sudo chmod 777 /var/www/html
echo 'server {
    listen 127.0.0.1:80;' | sudo tee /etc/nginx/sites-available/default
echo "    listen [$YGGIP]:80;" | sudo tee -a /etc/nginx/sites-available/default
echo '    root /var/www/html;
    index index.php index.html index.htm;

    server_name _;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}' | sudo tee -a /etc/nginx/sites-available/default > /dev/null
sudo apt install -y php8.4 php8.4-fpm php8.4-mysql php8.4-curl php8.4-gd php8.4-mbstring php8.4-xml php8.4-zip php8.4-soap php8.4-intl
sudo systemctl restart php8.4-fpm
sudo systemctl enable php8.4-fpm
sudo rm -rf /var/www/html/*
echo 'OK!' | tee /var/www/html/index.html
sudo systemctl restart nginx

mkdir ~/go ~/go/bin ~/go/src ~/go/pkg
wget -O temp/go.tar.gz https://go.dev/dl/go1.24.0.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf temp/go.tar.gz

echo -e "$(sudo crontab -l)\nPATH=$PATH\nMYAOOGLE=$PWD\nIPFS_PATH=$IPFS_PATH\n\
@reboot echo \"\$(date -u) System is rebooted\" >> $PWD/data/log.txt\n\
@reboot sleep 9; systemctl restart yggdrasil; systemctl restart nginx\n\
* * * * * su $USER -c \"bash $PWD/bin/cron.sh\"\n\
0 0 * * * su $USER -c \"cd $PWD && git pull --rebase\"\n\
" | sudo crontab -
echo -n "IPFS status:"
ipfs cat QmYwoMEk7EvxXi6LcS2QE6GqaEYQGzfGaTJ9oe1m2RBgfs/test.txt
echo -n "IPFSmount status:"
cat /ipfs/QmYwoMEk7EvxXi6LcS2QE6GqaEYQGzfGaTJ9oe1m2RBgfs/test.txt
cd $MYAOOGLE
rm -rf temp
mkdir temp
str=$(ipfs id) && echo $str | cut -c10-61 > $PWD/data/id.txt
(echo -n "$(date -u) Myaoogle system is installed. ID=" && cat $PWD/data/id.txt) >> $PWD/data/log.txt
ipfspub 'Initial message'
ipfs pubsub pub myaoogle $PWD/data/log.txt
echo "hash time log" > data/share/list.txt
sudo reboot
