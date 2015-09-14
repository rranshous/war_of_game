set_name = ARGV.shift || 'default'
puts "building test set #{set_name}"
system('docker build -t war_of_game_ga .')
[ [100, 100], [100, 50] ].each do |pop, gens|
  container_name = "wog_ga_#{pop}x#{gens}_#{set_name}"
  puts "rm old container"
  cmd = "docker rm #{container_name}"
  system(cmd)
  cmd = "docker run -d --name #{container_name} rranshous/wog_ga #{pop} #{gens}"
  puts "starting container"
  system(cmd)
end

