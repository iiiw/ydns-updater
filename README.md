# YDNS Updater Script

The bash updater script can be used on *nix environments to update dynamic hosts managed by the hosting service [YDNS](https://ydns.io/).

It is based on the [original updater script](https://github.com/ydns/bash-updater), but does not use the YDNS API v1. Instead, it uses a hashed update URL which is provided for every host.

## Installation

Make sure the dependency [curl](http://curl.haxx.se) is installed.

```bash
git clone https://github.com/iiiw/ydns-updater.git
# Or download the file:
# curl -LO https://raw.githubusercontent.com/iiiw/ydns-updater/master/updater.sh
sudo cp updater.sh /usr/local/bin/ydns-updater.sh # or any preferred location in PATH
sudo chmod +x /usr/local/bin/ydns-updater.sh # make the script executable
/usr/local/bin/ydns-updater.sh -h # run help to see options and usage
```

The script looks for update URLs

1. on the command line, if option `-u URL [-u …]` is present
2. in the file `$XDG_CONFIG_HOME/ydns/update_urls` (`$XDG_CONFIG_HOME` falling back to `$HOME/.config`), expecting to find one URL per line

## Crontab Setup

To run the script every 15 minutes set up a cronjob executing `crontab -e` (for system cronjob, prefix with `sudo`):

```bash
*/15 * * * * /path/to/script/updater.sh > /dev/null
```

For portability this could be written:

```bash
0,15,30,45 * * * * /path/to/script/updater.sh > /dev/null
```

## License

The code is licensed under the GNU Public License, version 3.
