#!/bin/bash

ETC_DIR="/etc"
echo " Checking 'at' and 'cron' allow files..."
for file in at cron; do
    [[ ! -f $file ]] && touch $ETC_DIR/$file.allow
    chown root:root $ETC_DIR/$file.allow
    chmod 600 $ETC_DIR/$file.allow

    echo " Remove $ETC_DIR/$file.deny file ..."
    rm -f $ETC_DIR/$file.deny

done
