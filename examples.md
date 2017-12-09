# Syntax examples
***
## rclone
`rsync` for the cloud

### Setup

```
# move to data directory
cd /srv/shiny-server/WhaleMap/data/raw/2017_sightings/

# verify/setup remote
rclone config

```

### List
List all files in given remote directory

```
# list files
rclone ls drive:data/

```

### Copy
Copy only new files

```
# Copy specific file
rclone copy drive:data/ . --drive-formats csv

```

### Sync
Make destination identical to source

```
# sync files
rclone sync drive:data/ . --drive-formats csv

```

***

## ssh
Remote connections

```
# Connect to Samba
ssh hansen@taggart3.ocean.dal.ca

# Connect to Shiny virtual machine
ssh whalemap
```

***

## scp
File transfers

```
# move to data dir
cd ~/Projects/WhaleMap/data/raw/2017_sightings/

## Single file

# transfer to SAMBA
scp 2017_narw_sightings.csv hansen@taggart3.ocean.dal.ca:/home/hansen

# transfer to WhaleMap
scp 2017_narw_sightings.csv whalemap:/srv/shiny-server/WhaleMap/data/raw/22017_sightings

## Directory

# move to data dir
cd ~/Projects/server_index/

# transfer to SAMBA
scp hansen@taggart3.ocean.dal.ca:/home/hansen 2017_narw_sightings.csv

# transfer to WhaleMap
scp whalemap:/srv/shiny-server/WhaleMap/data/raw/22017_sightings 2017_narw_sightings.csv


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


# quit and save crontab
:x
```
