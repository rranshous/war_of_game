require 'thread'
threads = []
filter = ARGV.to_a
Dir["Dockerfile.*"].each do |file|
  threads << Thread.new(file) do |f|
    image_name = "rranshous/wog_#{f.split('.').last}"
    if filter.length > 0 && !filter.include?(image_name)
      next
    end
    #cmd = "docker pull #{image_name}"
    #puts "CMD: #{cmd}"
    #system(cmd)
    cmd = "docker build -f #{f} -t #{image_name} ."
    puts "CMD: #{cmd}"
    system(cmd)
    cmd = "docker push #{image_name}"
    puts "CMD: #{cmd}"
    system(cmd)
  end
  threads
end
threads.map(&:join)
