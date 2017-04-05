#!/bin/bash

# Don't forget to read the SECURITY WARNING below, and then don't
# say you didn't know.

#######
## Description
#
# tl;dr -- Type `e filename` on a remote host via ssh and your local
#          emacs will open the remote file. Don't have the `e` alias
#          installed on the remote machine? No problem, it will
#          automatically detect that, install the alias, and then
#          open the file.
#
# This script contains instructions for telling a local
# Emacs to edit a remote file over an ssh connection from
# the remote host. It requires iTerm2. Setup involves creating
# two iTerm2 triggers that execute this script. You may need to
# edit the path to emacsclient here:

EMACSCLIENT=/usr/local/bin/emacsclient

## Example output for `e file` on remote host (split over two lines for readability)
#
# EMACS_EDIT r_user="hchapman" ssh_conn="192.168.56.1 65406 192.168.56.101 22" \
# pwd="/home/hchapman" ARGS file
#
# Format: EMACS_EDIT shell_variables ARGS filename(s)
#

## SECURITY WARNING!!! (and thoughts of a fix)
#
#     Hyperbole aside, I don't even worry about this, but it exists.
#
#     This will pass some text containing shell variables given from a
#     remote machine to your local shell without any safety checks. We
#     should find a way to make this safe. All we really want is to
#     pass some variable data. This was the fastest and easiest method
#     at the time.
#
#     Example of the local command:
#     $ shell_variables this_script.sh filename(s)
#
#     Worst-case(?) scenario: your angry, just-fired co-worker
#     manages to install/change the `e` alias on a remote machine
#     to output this:
#     EDIT_EMACS rm -rf / ; ARGS filename
#
#     note: EMACS_EDIT above is intentionally transposed to prevent
#           an incorrect iTerm2 regex plus catting this script from
#           executing that command.
#
#     The best fix would be to pass the entire remote text as an
#     unevaluated string to the script for safe processing. I
#     don't see an easy way to do this today with iTerm2. Perhaps we
#     could patch iTerm2 to give it the ability to pass text to
#     a command via standard input.

## Future improvements:
#
# If we could figure out how to auto-add the `e` function to the
# current environment after sshing anywhere, then it would
# be automatic and awesome. (UPDATE: it works!)
#
# Integrate this into a script that starts emacs if not already running.
#
# Handle line numbers like `+10 file` which tells emacsclient to open file
# at line 10.
#
# Handle the way grep outputs filename and line numbers, `file:10`. If you
# have iTerm2 set to auto-copy mouse selections, you can double click the
# filename:line_number, then type `e [CMD-V]` to take you right to that
# line.
#
# Can we make this work for multi-hop connections? (use tunneling?)
#
# Use xargs and a function to open files rather than a for which may
# not handle filenames with spaces.
#
#######

## Instructions:

## Put this function on the remote host (no longer strictly required, read on). This alias
#  prints a single easily parseable line to the terminal with all of the information needed
#  to tell Emacs + tramp how to open your remote file.
#
e() { printf 'EMACS_EDIT r_user="%s" ssh_conn="%s" pwd="%s" ARGS %s\n' $(id -un) "$SSH_CONNECTION" "$(pwd)" "$@"; }

## Add these triggers to iTerm2 (Profiles -> Advanced -> Edit Triggers):
#
#     regex: ^EMACS_EDIT (.*) ARGS (.*)$
#     action: Run Command
#     parameters: \1 /path/to/__this_script__.sh \2
#
#     regex: [ ]*e: command not found$
#     action: Send Text...
#     parameters:  [Paste everything between the horizontal lines below
#                   especially the trailing newline! Remove the leading
#                   comments. (explained below)]
#----------------------------------------------------------------
#e() { printf 'EMACS_EDIT r_user="%s" ssh_conn="%s" pwd="%s" ARGS %s\n' $(id -un) "$SSH_CONNECTION" "$(pwd)" "$@"; }
#!-2
#
#----------------------------------------------------------------
#
# The second trigger detects the missing `e` command and auto-sends it for you. It adds `!-2` which makes
# bash re-run the `e filename` command again after setting the alias.

# Note: the function doesn't work with vagrant VMs because they forward a port on the Host machine
# to the guest. Until we can detect and handle that, replace `$SSH_CONNECTION` above with
# `_ _ localhost 2222` or whatever port vagrant used. I usually put this in a .bash_aliases
# file which all new Ubuntu machines seem to automatically load if it exists.

## Algorithm:
#
# Parse the remote ssh host and port
# For each filename (assuming each argument is a separate file):
#     open it using tramp-mode in an already running emacs
#     URL pattern /ssh:user@host#port:/path/to/file

read my_ip my_port their_ip their_port <<< "${ssh_conn}"
for filename in "$@"; do
    # only add pwd to relative filenames
    if ! [[ "$filename" =~ ^/ ]]; then
        filename="${pwd}/${filename}"
    fi
    "$EMACSCLIENT" -n "/ssh:${r_user}@${their_ip}#${their_port}:${filename}"
done
