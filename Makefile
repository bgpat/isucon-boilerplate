USERS := bgpat fono09 Goryudyuma

define pubkey
	wget -q -O- https://github.com/$(1).keys \
	| sed 's/^/environment="GIT_AUTHOR_NAME=$(1)",environment="GIT_AUTHOR_EMAIL=$(1)@users.noreply.github.com" /' \
	>> /root/.ssh/authorized_keys

endef

.PHONY: all
all: git ssh

.PHONY: git
git: /.gitignore /root/.vimrc /home/isucon/.vimrc /root/.gitconfig

.PHONY: ssh
ssh: /root/.ssh/authorized_keys /root/.ssh/id_rsa sshd

.PHONY: sshd
sshd: /etc/sudoers /etc/ssh/sshd_config

.PHONY: /etc/sudoers
/etc/sudoers: /etc/sudoers.bak
	echo 'Defaults	env_keep+="GIT_AUTHOR_NAME"' >> $@
	echo 'Defaults	env_keep+="GIT_AUTHOR_EMAIL"' >> $@

/etc/sudoers.bak:
	cp -p /etc/sudoers $@

.PHONY: /etc/ssh/sshd_config
/etc/ssh/sshd_config: /etc/ssh/sshd_config.bak
	echo 'PermitUserEnvironment yes' >> /etc/ssh/sshd_config
	sshd -t
	systemctl reload sshd

/etc/ssh/sshd_config.bak:
	cp -p /etc/ssh/sshd_config $@

.PHONY: clean
clean:
	rm -rf /root/.ssh /.git /.gitignore /root/.vimrc /home/isucon/.vimrc /root/.ssh/id_rsa /root/.gitconfig
	test -e /etc/sudoers.bak && cp -fp /etc/sudoers.bak /etc/sudoers
	test -e /etc/ssh/sshd_config.bak && cp -fp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config

/root/.ssh:
	mkdir -p /root/.ssh
	chmod 700 /root/.ssh

/root/.ssh/authorized_keys: /root/.ssh
	$(foreach user,$(USERS),$(call pubkey,$(user)))
	chmod 600 /root/.ssh/authorized_keys

/.gitignore: files/gitignore
	cp -f $< $@

/root/.vimrc: files/vimrc
	cp -f $< $@

/home/isucon/.vimrc: files/vimrc
	cp -f $< $@

/root/.ssh/id_rsa: /root/.ssh
	yes | ssh-keygen -f $@ -t rsa -N "" -b 4096 > /dev/null
	cat $@.pub

/root/.gitconfig:
	git config --global user.email "anonymous@example.com"
	git config --global user.name "anonymous"
