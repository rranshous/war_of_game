

tournament-server: python bin/docker-hook -t new_tournament_player --port 5001 -c sh bin/tournament_server

scoreboard-viewer: bundle exec ruby scoreboard_viewer/app.rb -s Puma -e "0.0.0.0" -p 5000

web-designer: bundle exec ruby web_designer/app.rb -s Puma -e "0.0.0.0" -p 5002
