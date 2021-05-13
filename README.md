# borgAuto
My customisation and automation of the fantastic Borg backup and deduplication system

## Test Files
The files

* pruner.sh
* diff.sh

were created to test and debug the functions. Once they were working I copied them into the main shell script. I could have sourced them I suppose. I've left them as simple ways to test without performing needless backups.

## Automation by systemd timer
This works, but backing up several times a day is overkill for me. I might reset it do do it weekly.
Follow the instructions: (https://wiki.archlinux.org/title/Systemd/Timers)

### But I just use it manually
I practice, I just do manual backups by calling borgAuto.sh, whenever I feel like it. This turns out to be three of four times a month. I try to do one at the end of the month so that the long-term archive for that month is as current as possible.

To run the script from the command line I symlinked it here: `/usr/local/bin/borgAuto.sh`

## Bugs
When I was using the automatic timer, from time to time I would get a corruption. Before I could use or create new backups, I had to do some surgery. Should have recorded what I did here... (TLDR, I RTFMd and prayed a bit)

The corruption problem _may_ have been caused by the backup running straight after boot, but before the hardware clock had been reset by the network time sync service. I dual boot Windows, which resets the hardware clock from time to time.

## TODO

* Shorten the archive listings when I show the prune result

* Add ~/.config files (?)


