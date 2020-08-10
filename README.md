# isucon-boilerplate

## usage

### initialize

```bash
cd /
git init
git remote add origin https://github.com/$GITHUB_REPOSITORY.git
git fetch origin master
git reset --hard FETCH_HEAD
make USERS="bgpat fono09 Goryudyuma"
```

### edit config file

```bash
vim /etc/nginx/nginx.conf
```

### track source files by git

```bash
git add -f *.go
```
