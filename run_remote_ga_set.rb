puts "building"
system('docker build -t war_of_game_ga .')
[ 5, 10, 30, 50, 75, 100, 500 ].permutation(2) do |pop, gens|
  container_name = "wog_ga_#{pop}x#{gens}_inproc"
  puts "rm old container"
  cmd = "docker rm #{container_name}"
  system(cmd)
  cmd = "docker run -d --name #{container_name} war_of_game_ga #{pop} #{gens}"
  puts "starting container"
  system(cmd)
end

