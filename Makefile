HOSTNAME := $(shell hostname)

.PHONY: all
all: git ssh commit /home/isucon/.bashrc
	@clear
	@echo "Open \e[4mhttps://github.com/$$(\
		git config --get remote.origin.url | sed -r 's/^.*?:(.*)\.git$$/\1/' \
	)/settings/keys/new\e[0m and paste pubkey:\n"
	@cat /root/.ssh/id_rsa.pub
	@echo

.PHONY: commit
commit:
	git add -A
	git commit -m "Configure $(HOSTNAME)"

.PHONY: git
git: /.gitignore /usr/local/bin/git-preserve-permissions /root/.vimrc /home/isucon/.vimrc
	git config --get remote.origin.url \
	| grep '^https://' \
	&& git config --get remote.origin.url \
	| sed -r 's%^https://github.com/([a-zA-Z0-9_-]*/[a-zA-Z0-9_-]*).*$$%git@github.com:\1.git%' \
	| xargs git remote set-url origin \
	|| true

.PHONY: ssh
ssh: /root/.ssh/authorized_keys /files/hosts/$(HOSTNAME)_pubkey sshd

.PHONY: sshd
sshd: /etc/sudoers /etc/ssh/sshd_config

.PHONY: /etc/sudoers
/etc/sudoers: /etc/sudoers.bak
	echo 'Defaults	env_keep+="GIT_AUTHOR_NAME"' >> $@
	echo 'Defaults	env_keep+="GIT_AUTHOR_EMAIL"' >> $@

/etc/sudoers.bak:
	cp -p /etc/sudoers $@

.PHONY: /etc/ssh/sshd_config
/etc/ssh/sshd_config: /etc/ssh/sshd_config.bak ssh_host_key
	sed -i '/^PermitRootLogin no/d' $@
	echo 'PermitUserEnvironment yes' >> $@
	echo 'PermitRootLogin without-password' >> $@
	sshd -t
	systemctl reload sshd

/etc/ssh/sshd_config.bak:
	cp -p /etc/ssh/sshd_config $@

.PHONY: clean
clean:
	rm -rf /root/.ssh /.gitignore /root/.vimrc /home/isucon/.vimrc /root/.ssh/id_rsa /root/.gitconfig
	test -e /etc/sudoers.bak && cp -fp /etc/sudoers.bak /etc/sudoers
	test -e /etc/ssh/sshd_config.bak && cp -fp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config

/root/.ssh:
	mkdir -p /root/.ssh
	chmod 700 /root/.ssh

/root/.ssh/authorized_keys: /root/.ssh
	touch $@
	chmod 600 $@

/.gitignore: files/gitignore
	cp -n $< $@

/root/.vimrc: files/vimrc
	cp -f $< $@

/home/isucon/.vimrc: files/vimrc
	cp -f $< $@

/root/.ssh/id_rsa: /root/.ssh
	yes | ssh-keygen -f $@ -t rsa -N "" -b 4096 > /dev/null

/root/.ssh/id_rsa.pub: /root/.ssh/id_rsa

/files/hosts/$(HOSTNAME)_pubkey: /root/.ssh/id_rsa.pub
	mkdir -p /files/hosts
	cp -f $< $@
	git add -f $@

/root/.gitconfig:
	git config --global user.email "anonymous@example.com"
	git config --global user.name "anonymous"
	git config --global preserve-permissions.user "true"
	git config --global preserve-permissions.group "true"

.PHONY: ssh_host_key
ssh_host_key:
	ssh-keygen -A

/usr/local/bin/git-preserve-permissions: /git-preserve-permissions /root/.gitconfig
	cp -f $</git-preserve-permissions $@
	cp -f $</post-checkout $</post-merge $</pre-commit /.git/hooks/
	-git preserve-permissions --save

/git-preserve-permissions:
	git clone --depth=1 https://github.com/dr4Ke/git-preserve-permissions.git

/home/isucon:
	mkdir -p $@

/home/isucon/.bashrc: /home/isucon/.bashrc.bakup
ifeq ($(shell git status --ignored --short /home/isucon/.bashrc),!! /home/isucon/.bashrc)
	/files/gitignore.sh $@
	echo 'alias git="sudo git"' >> $@
	git add -f $@
	git commit -m 'Add alias for git'
endif

/home/isucon/.bashrc.bakup: /home/isucon
	cp -f /home/isucon/.bashrc $@
	/files/gitignore.sh $@
