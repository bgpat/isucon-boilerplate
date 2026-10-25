# isucon-boilerplate

## usage

### initialize

#### from local PC

**create a new repository**

- [ ] Create a new repository from https://github.com/bgpat/isucon-boilerplate/generate.

**add members**

- [ ] Invite your team members from https://github.com/$GITHUB_REPOSITORY/settings/access.
  - Run [Update SSH Keys](https://github.com/$GITHUB_REPOSITORY/actions/workflows/update-sshkeys.yml).

#### in each competition server 

Run following commands by `root` user.

**generate and register ssh deploy key**

```bash
ssh-keygen -t rsa
cat ~/.ssh/id_rsa.pub
```

Copy the result and register as a [deploy key](https://github.com/$GITHUB_REPOSITORY/settings/keys/new).

**install**

```bash
cd /
git init
git remote add origin git@github.com:$GITHUB_REPOSITORY.git
git fetch origin master
git reset --hard FETCH_HEAD
make
```

Add deploy key and run `git push -u origin master`.

### run monitoring servers

```bash
make monitoring
```

Access to 3999 port from your browser.

### edit config file

```bash
vim /etc/nginx/nginx.conf
```

### track source files by git

```bash
cd /home/isucon
git add -f *.go
```

### 共通タスクの自動作成

テンプレートから作成したリポジトリでは、最初の master への push で On Created が
`tasks/*.md` から共通タスクの Issue、label、親子関係、依存関係を作成します。
テンプレートリポジトリ自身では実行しません。Actions と Issues を有効にしてください。

途中で失敗した場合やテンプレートを追加した場合は、Actions の On Created を手動実行できます。
閉じた Issue も含む全件を検索し、既存タスクの本文・状態を保持したまま、不足する Issue と
関連付けだけを追加します。workflow は再実行用に残し、強制 push は行いません。
詳細は [tasks/README.md](tasks/README.md) を参照してください。

元テンプレート: https://github.com/bgpat/isucon11q-20260905/tree/master/tasks
