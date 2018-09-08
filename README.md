# isucon-boilerplate

## example

```
cd /
git init
git remote add origin https://github.com/bgpat/isucon-boilerplate
git fetch origin master
git reset --hard origin/master
/files/bootstrap.sh bgpat owlworks Goryudyuma
systemctl restart sshd
git remote set-url origin $REPO_URL
```
