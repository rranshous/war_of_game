swarm_name = ARGV.shift
token = `docker run swarm create`.chomp
# put up swarm
cmd = "docker-machine create --driver digitalocean --digitalocean-access-token $DIGITALOCEAN_DOCKERMACHINE_KEY --digitalocean-size=512mb --swarm --swarm-master --swarm-discovery=\"token://#{token}\" #{swarm_name}-master"
puts "creating master: #{cmd}"
system(cmd)
10.times do |i|
  cmd = "docker-machine create --driver digitalocean --digitalocean-access-token $DIGITALOCEAN_DOCKERMACHINE_KEY --digitalocean-size=512mb --swarm --swarm-discovery=\"token://#{token}\" #{swarm_name}-#{i}"
  puts "creaitng worker box #{i} :: #{cmd}"
  system(cmd)
  puts "done creating worker #{i}"
end

