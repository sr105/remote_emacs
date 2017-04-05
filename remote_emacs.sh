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
e() { printf 'EMACS_EDIT r_user="%s" ssh_conn="%s" pwd="%s" ARGS %s\n' $(id -un) "$SSH_CONNECTION" "$(pwd)" "$@"; }

## Add these triggers to iTerm2 (Profiles -> Advanced -> Edit Triggers):
#
#     regex: ^EMACS_EDIT (.*) ARGS (.*)$
#     action: Run Command
#     parameters: \1 /path/to/__this_script__.sh \2
#
#     regex: ^e: command not found$
#     action: Send Text...
#     parameters:  [Paste everything between the pipes below
#                   especially the leading space and trailing newline! (reasoning below)] 
#     | e() { printf 'EMACS_EDIT r_user="%s" ssh_conn="%s" pwd="%s" ARGS %s\n' $(id -un) "$SSH_CONNECTION" "$(pwd)" "$@"; }
#|
#
# The second trigger detects the missing `e` command and auto-sends it for you. It adds a leading
# space so bash won't add it to the command history. This allows you to hit UP and have the
# `e filename` command back skipping the function definition command.

# Note: the function doesn't work with vagrant VMs because they forward a port on the Host machine
# to the guest. Until we can detect and handle that, replace `$SSH_CONNECTION` above with
# `_ _ localhost 2222`.

## Example output for `e file` on remote host (split over two lines for readability)
#
# EMACS_EDIT r_user="hchapman" ssh_conn="192.168.56.1 65406 192.168.56.101 22" \
# pwd="/home/hchapman" ARGS file

## Algorithm:
#
# Parse the remote ssh host and port
# For each filename (assuming each argument is a separate file):
#     open it using tramp-mode in an already running emacs
#     URL pattern /ssh:user@host#port:/path/to/file

read my_ip my_port their_ip their_port <<< "${ssh_conn}"
for filename in "$@"; do
    if ! [[ "$filename" =~ ^/ ]]; then
        filename="${pwd}/${filename}"
    fi
    /usr/local/bin/emacsclient -n "/ssh:${r_user}@${their_ip}#${their_port}:${filename}"
done
