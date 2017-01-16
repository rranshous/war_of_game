#!/usr/bin/env ruby

set_name = ARGV.shift || 'default'
puts "building test set #{set_name}"
system('docker build -t war_of_game_ga .')
[ [48, 50], [48, 100], [100, 20], [100, 40], [100, 200] ].each do |pop, gens|
  epoch = Time.now.to_f.to_s
  container_name = "wog_ga_#{pop}x#{gens}_#{set_name}_#{epoch}"
  puts "rm old container"
  cmd = "docker rm #{container_name}"
  system(cmd)
  cmd = "docker run -m 64g -d --name #{container_name} rranshous/wog_ga #{pop} #{gens} &"
  puts "starting container"
  system(cmd)
end

