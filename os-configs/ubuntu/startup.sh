#!/bin/bash

tmux new-session -d -s main
# tmux send-keys -t main "cd $PROJECTS_FOLDER/server/src/Identity ; dotnet run --urls http://*:33656" C-m
tmux send-keys -t main "cd $PROJECTS_FOLDER/server/dev ; docker compose --profile cloud --profile mail up -d" C-m
tmux split-window -h -t main
tmux split-window -v -p 50 -t main
tmux send-keys -t main "cd $PROJECTS_FOLDER/clients/apps/web ; npm run build:bit:watch" C-m
tmux select-pane -t main:0.0
tmux split-window -v -p 50 -t main
# tmux send-keys -t main "cd $PROJECTS_FOLDER/server/src/Api ; dotnet run --urls http://*:4000" C-m
tmux select-pane -t main:0.0
tmux attach-session -d -t main

