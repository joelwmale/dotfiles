# 🚀 Dotfiles

This is a collection of my personal dotfiles and a few scripts to quickly configure a mac the way i like it.

## ✨ Running

```bash
$ git clone git@github.com:joelwmale/dotfiles.git
$ ./bootstrap
```

## 🛠 Tools / Programs Installed

It contains the installation of the following tools & programs from brew:

* Host file from [someonewhocares.org](https://someonewhocares.org/hosts/)
* [brew](https://brew.sh)
* git
* [node](https://nodejs.org)
* pkg-config
* [wget](https://formulae.brew.sh/formula/wget)
* [httpie](https://httpie.org/)
* [ncdu](https://github.com/rofl0r/ncdu)
* [hub](https://hub.github.com/)
* [ack](https://beyondgrep.com/)
* [bat](https://github.com/sharkdp/bat)
* [doctl](https://github.com/digitalocean/doctl)
* [yarn](https://github.com/yarnpkg/yarn)
* [php@7.3](https://php.net/)
* [mariadb](https://mariadb.org/)
* [redis](https://redis.io/)
* [vscode](https://code.visualstudio.com/)
* [fork](https://git-fork.com/)
* [transmit](https://panic.com/transmit/)
* [sequel-pro](https://www.sequelpro.com/)
* [hyper](https://hyper.is/)
* [spotify](https://www.spotify.com/au/)
* [insomnia](https://insomnia.rest/)
* [google-chrome](https://www.google.com/chrome/)

The following tools from composer:

* [laravel/valet](https://laravel.com/docs/5.8/valet)
* [hirak/prestissimo](https://github.com/hirak/prestissimo)
* [spatie/phpunit-watcher](https://github.com/spatie/phpunit-watcher)

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