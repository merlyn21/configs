#!/bin/bash

#deletes old files if there are more than 10 except for the last 10 

path="/var/opt/gitlab/backups"

count=`ls $path | wc -l`

echo $count

if [ $count -ge 10 ]
then
  echo "need clear"
#  find /home/ubuntu/build -type d -mtime +25 -delete
  `cd $path; ls -tp | tail -n +10 | xargs -I {} rm -r -- {}`
#  list=`ls -tp $path`
#  echo $list
fi
