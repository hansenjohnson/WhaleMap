# Syntax examples
***

## chmod
Make a shell script executable

```
# add the following to the first line of the file
#!/bin/bash

# run this line to make executable
chmod u+x scriptname.sh
```

***

## rsync
File sync / transfer

```
# transfer to WhaleMap
rsync -rtv file.txt hansen@whalemap:/srv/shiny-server/WhaleMap/
```
***

## crontab
Automate tasks

```
# open crontab
crontab -e

# enable edits to crontab
a # this means 'append' in vim

# run every hour
0 * * * * sh /home/hansen/shiny-server/WhaleMap/get_live_dcs.sh

# run every 5 min (usually just for testing)
*/5 * * * * sh /home/hansen/shiny-server/WhaleMap/get_live_dcs.sh

# server side example
0 * * * * /srv/shiny-server/WhaleMap/get_remote_data.sh

# quit and save crontab
:x
```
***
## Shiny server

```
# reload the shiny server
sudo systemctl reload shiny-server
# restart the shiny server
sudo systemctl restart shiny-server
```

***

## Cron mail

```
# Delete
cat /dev/null >/var/mail/hansenjohnson # local
cat /dev/null >/var/mail/hansen # server
```
***

## Git

### Delete local commits
```
git reset --hard
```

### Apply patch commit
```
git am filename
```

#### Merge branches (dev into master)
https://git-scm.com/book/en/v2/Git-Branching-Basic-Branching-and-Merging
```
git checkout master
git merge dev
```
