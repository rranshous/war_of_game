swarm_name = ARGV.shift
workers = (ARGV.shift || 2).to_i
size = ARGV.shift || "512mb"
token = `docker run swarm create`.chomp
puts "Creating swarm with one master and #{workers} worker nodes of size #{size} using token #{token}"
# put up swarm
cmd = "docker-machine create --driver digitalocean --digitalocean-access-token $DIGITALOCEAN_DOCKERMACHINE_KEY --digitalocean-size=#{size} --swarm --swarm-master --swarm-discovery=\"token://#{token}\" #{swarm_name}-master"
puts "creating master: #{cmd}"
system(cmd)
workers.times do |i|
  cmd = "docker-machine create --driver digitalocean --digitalocean-access-token $DIGITALOCEAN_DOCKERMACHINE_KEY --digitalocean-size=#{size} --swarm --swarm-discovery=\"token://#{token}\" #{swarm_name}-#{i}"
  puts "creaitng worker box #{i} :: #{cmd}"
  system(cmd)
  puts "done creating worker #{i}"
end

