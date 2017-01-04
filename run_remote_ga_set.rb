set_name = ARGV.shift || 'default'
puts "building test set #{set_name}"
system('docker build -t war_of_game_ga .')
[ [48, 50], [48, 100], [100, 20], [100, 40] ].each do |pop, gens|
  container_name = "wog_ga_#{pop}x#{gens}_#{set_name}"
  puts "rm old container"
  cmd = "docker rm #{container_name}"
  system(cmd)
  cmd = "(docker run -m 64g -d --name #{container_name} rranshous/wog_ga #{pop} #{gens}) 2>1 > ./game_outputs/#{container_name}.log"
  puts "starting container"
  system(cmd)
end

