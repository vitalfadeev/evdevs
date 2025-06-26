#!/bin/sh
git init
git add -A .
git commit -m "init"
git remote add origin git@github.com:vitalfadeev/evdevs.git
git push
