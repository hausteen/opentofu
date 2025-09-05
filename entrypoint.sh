#!/bin/sh

# Nothing should not be stored here so we delete everything on startup
delete_everything_in_the_writeback_folder() {
    echo "Deleting everything in the writeback folder."
    cd opentofuWriteback/
    ls -A | grep -vE "^\.gitkeep$" | xargs rm -rf
    cd
}

# Container startup
delete_everything_in_the_writeback_folder
echo "Press ctrl+c to exit container.";

# Infinite loop until container is stopped
while :
do 
    sleep 3600
done
