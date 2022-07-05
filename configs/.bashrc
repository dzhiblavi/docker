#!/bin/bash

if [[ -f /user-files/.dots/.bashrc ]]; then
    source /user-files/.dots/.bashrc
fi

if [[ -f /user-files/.dots/.vimrc ]]; then
    cp /user-files/.dots/.vimrc "/home/$(id -un)/.vimrc"
fi
