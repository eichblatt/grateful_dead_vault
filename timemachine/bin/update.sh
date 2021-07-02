#!/bin/bash

echo "home is $HOME"
echo "Updating "
date

git_branch=main    # Make this a command-line option!

system () {
   command=$1
   echo "$command"
   $command
}

restore_services () {
   # put the old services back in place.
   echo "services.sh"
   services.sh
   # Restart the services (Can i get the timemachine service to launch the serve_options?)
   echo "sudo service timemachine restart"
   sudo service timemachine restart
   echo "sudo service serve_options restart"
   sudo service serve_options restart
}

cleanup_old_envs () {
   echo "Cleaning up old envs ... "
   echo "ls -1trd $HOME/env_* | head -n -8"
   ls -1trd $HOME/env_* | head -n -8
   echo "ls -1trd $HOME/env* | head -n -8 | xargs -d '\n' rm -f --"
   ls -1trd $HOME/env_* | head -n -8 | xargs -d '\n' rm -f --
   echo "Done cleaning up old envs"
}

system "cd $HOME"
env_name=env_`date +%Y%m%d`.`cat /dev/random | tr -cd 'a-f0-9' | head -c 8`
system "python3 -m venv $env_name"
system "source $env_name/bin/activate"
system "pip3 install wheel"
system "pip3 install git+https://github.com/eichblatt/deadstream.git@$git_branch"

current_metadata_path=$HOME/timemachine/lib/python3.7/site-packages/timemachine/metadata
new_metadata_path=$HOME/$env_name/lib/python3.7/site-packages/timemachine/metadata
update_archive=`find $current_metadata_path/GratefulDead_ids.json -mtime +40 | wc -l`
if [ $update_archive == 0 ]; then
   echo "cp -pR $current_metadata_path/*.json $new_metadata_path/."
   cp -pR $current_metadata_path/*.json $new_metadata_path/.
fi

# Stop the running services
system "sudo service timemachine stop"
system "sudo service serve_options stop"

system "timemachine_test_update"
stat=$?
echo "status of test command: $stat"

system "cd $HOME" # NOTE: we should already be here.
if [ $stat == 0 ]; then
   system "ln -sfn $env_name timemachine"
else
   system "rm -rf $env_name"
fi

restore_services
cleanup_old_envs

exit $stat