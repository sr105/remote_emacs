#!/bin/bash

#######
## Description
#
# This script contains instructions for telling a local
# Emacs to edit a remote file over an ssh connection from
# the remote host. It requires iTerm2.
#
#
## Future improvements:
#
# If we could figure out how to auto-add the `e` function to the
# current environment after sshing anywhere, the it would
# be automatic.
#
# Integrate this into a script that starts emacs if not already running.
#
# Handle line numbers like `+10 file` which tells emacsclient to open file
# at line 10.
#
# Can we make this work for multi-hop connections? (use tunneling?)
#
#######

## Instructions:

## Put this function on the remote host
#
e() {
    printf 'EMACS_EDIT r_user="%s" ssh_conn="%s" pwd="%s" ARGS ' $(id -un) "$SSH_CONNECTION" "$(pwd)"
    echo "$@" EDIT_EMACS
}

## Add a trigger to iTerm2 (Profiles -> Advanced -> Edit Triggers):
#
#     regex: ^EMACS_EDIT (.*) ARGS (.*) EDIT_EMACS$
#     action: Run Command
#     parameters: \1 /path/to/__this_script__.sh \2

## Example output for `e file` on remote host (split over two lines for readability)
#
# EMACS_EDIT r_user="hchapman" ssh_conn="192.168.56.1 65406 192.168.56.101 22" \
# pwd="/home/hchapman" ARGS file EDIT_EMACS

## Algorithm:
#
# Parse the remote ssh host and port
# For each filename (assuming each argument is a separate file):
#     open it using tramp-mode in an already running emacs
#     URL pattern /ssh:user@host#port:/path/to/file

read my_ip my_port their_ip their_port <<< "${ssh_conn}"
for filename in "$@"; do
    /usr/local/bin/emacsclient -n "/ssh:${r_user}@${their_ip}#${their_port}:${pwd}/${filename}"
done
