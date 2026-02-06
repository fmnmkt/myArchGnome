#!/usr/bin/env bash

sudo pacman -S fish --noconfirm
chsh -s /usr/bin/fish
set -U fish_greeting
