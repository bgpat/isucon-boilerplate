#!/bin/sh

set -ue
cd /

mkdir -p /root/.ssh
chmod 700 /root/.ssh
for user in $*; do
	wget -q -O- https://github.com/$user.keys | sed "s/^/environment=\"GIT_AUTHOR_NAME=$user\",environment=\"GIT_AUTHOR_EMAIL=$user@users.noreply.github.com\" /" >> /root/.ssh/authorized_keys
done
chmod 600 /root/.ssh/authorized_keys

git config --global user.email "you@example.com"
git config --global user.name "Your Name"

cp -f /files/gitignore /.gitignore
cp -f /files/vimrc /root/.vimrc
cp -f /files/vimrc /home/isucon/.vimrc

cat << EOF >> /etc/sudoers

Defaults	env_keep+="GIT_AUTHOR_NAME"
Defaults	env_keep+="GIT_AUTHOR_EMAIL"
EOF

echo 'PermitUserEnvironment yes' >> /etc/ssh/sshd_config
sshd -t && systemctl restart sshd

echo -en "Please type github repository (e.g. \e[4mgit@github.com:bgpat/isucon.git\e[0m):\n> "
read repo
git remote set-url origin $repo

yes | ssh-keygen -f /root/.ssh/id_rsa -t rsa -N "" > /dev/null
repo=${repo##*:}
echo -e "Open \e[4mhttps://github.com/${repo%.git}/settings/keys/new\e[0m and paste pubkey:\n"
cat /root/.ssh/id_rsa.pub
