require 'thread'
threads = []
push = !ENV['PUSH'].nil?
use_threads = !ENV['THREADED'].nil?
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
    if push
      cmd = "docker push #{image_name}"
      puts "CMD: #{cmd}"
      system(cmd)
    end
  end
  threads.last.join unless use_threads
  threads
end
threads.map(&:join)
