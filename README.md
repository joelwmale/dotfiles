# 🚀 Dotfiles

This is a collection of my personal dotfiles and a few scripts to quickly configure a mac the way i like it.

## ✨ Running

```bash
$ git clone git@github.com:joelwmale/dotfiles.git
$ ./bootstrap
```

## 🛠 Tools / Programs Installed

It contains installation of the following tools:

| Tool                                                                     | Description                                                                      |
| ------------------------------------------------------------------------ | -------------------------------------------------------------------------------- |
| Host file from [someonewhocares.org](https://someonewhocares.org/hosts/) | prevent your computer from connecting to many types of spyware, advertising, etc |
| [brew](https://brew.sh)                                                  | package management for macos                                                     |
| git                                                                      | vcs system                                                                       |
| [node](https://nodejs.org)                                               | javascript runtime                                                               |
| pkg-config                                                               | helper when compiling applications                                               |
| [wget](https://formulae.brew.sh/formula/wget)                            | wget for macos                                                                   |
| [httpie](https://httpie.org/)                                            | cleaner cURL                                                                     |
| [ncdu](https://github.com/rofl0r/ncdu)                                   | disk analyzer                                                                    |
| [hub](https://hub.github.com/)                                           | better git cli                                                                   |
| [ack](https://beyondgrep.com/)                                           | better grep                                                                      |
| [bat](https://github.com/sharkdp/bat)                                    | better cat                                                                       |
| [doctl](https://github.com/digitalocean/doctl)                           | digital ocean cli                                                                |
| [yarn](https://github.com/yarnpkg/yarn)                                  | npm package management                                                           |
| [php@7.3](https://php.net/)                                              | php                                                                              |
| [mariadb](https://mariadb.org/)                                          | database                                                                         |
| [redis](https://redis.io/)                                               | cache                                                                            |

The following applications:

| Application                                     | Description                         |
| ----------------------------------------------- | ----------------------------------- |
| [vscode](https://code.visualstudio.com/)        | text editor                         |
| [fork](https://git-fork.com/)                   | git gui                             |
| [transmit](https://panic.com/transmit/)         | ftp tool                            |
| [sequel-pro](https://www.sequelpro.com/)        | database management                 |
| [hyper](https://hyper.is/)                      | better terminal built in electron   |
| [spotify](https://www.spotify.com/au/)          | music                               |
| [insomnia](https://insomnia.rest/)              | REST client                         |
| [google-chrome](https://www.google.com/chrome/) | internet browser                    |
| [alfred](https://www.alfredapp.com/)            | productivity app & better spotlight |
| [spectacle](https://www.spectacleapp.com/)      | window management                   |

The following composer packages:

| Package                                                             | Description                                                  |
| ------------------------------------------------------------------- | ------------------------------------------------------------ |
| [laravel/valet](https://laravel.com/docs/5.8/valet)                 | configuration free local hosting                             |
| [hirak/prestissimo](https://github.com/hirak/prestissimo)           | composer parallel install plugin                             |
| [spatie/phpunit-watcher](https://github.com/spatie/phpunit-watcher) | automatically re-runs phpunit tests when source code changes |

## 📚 Aliases

It also contains the following aliases:

| Alias    | Command                                                                                                   |
| -------- | --------------------------------------------------------------------------------------------------------- |
| pa       | php artisan                                                                                               |
| dbfresh  | pa migrate:fresh --seed                                                                                   |
| codecept | ./vendor/bin/codecept                                                                                     |
| phpunit  | ./vendor/bin/phpunit                                                                                      |
| tplan    | terragrunt plan-all                                                                                       |
| tapply   | terragrunt apply-all                                                                                      |
| minio    | minio server ~/data                                                                                       |
| repush   | git pull --rebase && git push                                                                             |
| gitclean | `git checkout master && git fetch -p && git branch -vv | awk '/: gone]/{print $1}' | xargs git branch -d` |
| gl       | git log --pretty=format:"%C(yellow)%h %ad%Cred%d %Creset%s%Cblue [%cn]" --decorate --date=short           |
| gr       | git pull --rebase && git push                                                                             |
| ga       | git add -p                                                                                                |
| gaa      | git add .                                                                                                 |
| gc       | git commit --verbose                                                                                      |
| gcm      | git commit -m                                                                                             |
| gcom     | git checkout master                                                                                       |
| gcod     | git checkout develop                                                                                      |
| gca      | git commit -a --verbose                                                                                   |
| gcam     | git commit --amend --verbose                                                                              |
| grh      | git reset --hard                                                                                          |
| gd       | git diff                                                                                                  |
| gds      | git diff --stat                                                                                           |
| gs       | git status -s                                                                                             |
| gc       | git checkout                                                                                              |
| gcb      | git checkout -b                                                                                           |
| weather  | curl wttr.in/brisbane                                                                                     |