#!/usr/bin/env ruby

require 'sinatra/base'
require 'tilt/erb'
require 'vmstat'
require 'os'

def genload(repetitions)
  repetitions.times do |i|
    10000.downto(1) do |j|
      Math.sqrt(j) * i / 0.2
    end
  end
end

LOREM_IPSUM = """
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed tristique semper purus, non efficitur lacus placerat non. In quis erat eget magna molestie finibus. Quisque non iaculis ligula. Aenean auctor porttitor lacus eu posuere. Duis eleifend feugiat erat vel feugiat. Aliquam volutpat ullamcorper ipsum, eu pulvinar est. Aenean tincidunt id magna eu pulvinar. Nunc scelerisque et felis quis hendrerit.

Quisque rutrum porta est, id porta orci iaculis non. Ut vel enim nibh. Quisque sagittis venenatis diam et luctus. Ut gravida in nisl eu efficitur. Integer mollis velit nisl, et tristique turpis scelerisque ac. Maecenas aliquet mollis leo dictum dapibus. Duis sollicitudin mollis ante, vel sodales quam. Nulla vulputate tempor purus in dignissim. Nunc cursus, lacus a accumsan tristique, metus eros mattis lacus, et pellentesque urna lorem lobortis nisi. Proin auctor diam sed viverra mattis. Suspendisse eu lobortis neque. Suspendisse sapien lectus, pretium vel ex sit amet, finibus volutpat sapien. Donec felis lorem, elementum vel ultrices a, volutpat sed enim. Nulla suscipit ligula vel venenatis placerat. Integer sit amet nibh id metus varius auctor ac in enim. In hac habitasse platea dictumst.

Pellentesque tincidunt porta convallis. Nunc sed mattis ipsum. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. In pretium auctor lobortis. Praesent vestibulum posuere hendrerit. Proin semper est ac nisi maximus aliquam. Integer commodo sollicitudin felis. Quisque aliquam, mi a feugiat facilisis, odio metus aliquet erat, id tincidunt risus nisl et libero. Praesent molestie ornare fermentum. Nunc congue orci justo, sit amet tincidunt leo finibus et. Duis nibh ante, commodo ut mattis non, faucibus non dui. Nam at arcu in felis ullamcorper mattis sit amet a nisl. Vestibulum mollis interdum cursus. Ut nunc libero, maximus in semper eu, facilisis a velit. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Fusce convallis eget felis vitae eleifend.

Sed ut metus id nunc tincidunt condimentum. Nunc lectus lacus, posuere quis nulla vel, viverra euismod nibh. Morbi augue dui, feugiat eu tortor eu, pretium pellentesque purus. Nullam consectetur consequat lorem sit amet dignissim. Vestibulum porttitor orci in ligula tristique sodales. Curabitur at est purus. Sed scelerisque enim purus, non semper lorem efficitur sed. Nullam eu erat non nisl molestie elementum quis sit amet risus. Vivamus pretium augue dolor, at gravida magna hendrerit eget. Donec ultrices iaculis ex at consectetur. Quisque id dolor eu mi lacinia suscipit. Cras vehicula neque lorem, quis ultrices libero ultricies vel. Aenean tempor neque nec leo posuere, in scelerisque quam lacinia. Mauris mauris lacus, rutrum et pharetra eget, cursus et diam.

Aenean fermentum nunc sit amet condimentum accumsan. Proin metus nisi, porttitor ultrices pharetra ac, interdum et velit. Duis at lorem neque. Pellentesque at viverra justo. Vestibulum vulputate elementum felis nec pharetra. Suspendisse potenti. Duis vestibulum arcu quam, dictum tristique nunc consequat et. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Nulla posuere quam eu fermentum placerat. In ullamcorper mauris nec sem dapibus sodales. Nunc vehicula mi leo, id luctus mauris sodales et. Donec quis consectetur est. Vestibulum tempus egestas ante cursus finibus. Nam placerat accumsan pharetra.
"""

class SinatraExample < Sinatra::Base
  get '/' do
    erb :home
  end

  get '/environment' do
    request.env.map { |e| e.to_s + "\n" }
  end

  get '/sleep/:milliseconds' do
    milliseconds = params[:milliseconds].to_i
    sleep(milliseconds/1000)
    "slept for #{milliseconds} milliseconds"
  end

  get '/simplecpuload/?:repetitions?' do
    repetitions = (params[:repetitions] || 10).to_i
    genload repetitions

    "Done computing. The answer is: 42"
  end

  get '/cpuload/:processes' do
    processes = params[:processes].to_i
    processes.times do |p|
      child_pid = Process.fork do
        genload 1000
      end
    end

    Process.wait

    "Finished generating CPU load - #{processes} processes complete"
  end

  get '/mem/alloc/:size_mb/?:leak?/?:once?' do
    if params[:once] and params[:once]=1 and $leak_buffer
      puts "Already has memory allocated, skipping"
      return "Already has memory allocated, skipping"
    end

    size_mb = params[:size_mb].to_i
    total_bytes = size_mb*1024**2
    do_leak = (params[:leak] and params[:leak] == "1")

    # Metrics before allowcate
    rss_bytes_before = OS.rss_bytes
    free_mem_before = (Vmstat.memory.free * Vmstat.memory.pagesize) / 1024

    puts "Allocating: #{size_mb} MB. Leaking memory: #{if do_leak; "Yes" else  "No" end}, system free: #{free_mem_before/1024} MiB, Process rss: #{rss_bytes_before/1024} MiB"

    # Allocate the memory chunk
    chunk_of_mem = 'a'*(total_bytes-1)
    if do_leak
        $leak_buffer = [] unless $leak_buffer
        $leak_buffer << chunk_of_mem
    end

    sleep(1.0/10.0) # To be sure that Vmstat will catch the memory change

    # Metrics after allocate
    rss_bytes_after = OS.rss_bytes
    free_mem_after = (Vmstat.memory.free * Vmstat.memory.pagesize) / 1024

    puts "Allocated: #{size_mb} MB. Leaking memory: #{if do_leak; "Yes" else  "No" end}, system free: #{free_mem_after/1024} MiB, Process rss: #{rss_bytes_after/1024} MiB"

    """Allocated #{size_mb} MB = #{total_bytes} bytes.
Leaking memory: #{if do_leak; "Yes" else  "No" end}
Free system memory before: #{free_mem_before} kiB aka #{free_mem_before/1024} MiB
Free system memory after: #{free_mem_after} kiB aka #{free_mem_after/1024} MiB
Process memory before: #{rss_bytes_before} kiB aka #{rss_bytes_before/1024} MiB
Process memory after: #{rss_bytes_after} kiB aka #{rss_bytes_after/1024} MiB
"""
  end

  get '/mem/status' do
    # Metrics after allocate
    rss_bytes = OS.rss_bytes
    free_mem = (Vmstat.memory.free * Vmstat.memory.pagesize) / 1024


    """Process memory: #{rss_bytes} kiB aka #{rss_bytes/1024} MiB
Process memory: #{rss_bytes} kiB aka #{rss_bytes/1024} MiB
"""
  end

  # Read all the memory allocated by /mem/alloc endpoint, so the system
  # will be forced to page it in from swap if needed.
  get '/mem/touch' do
    return unless $leak_buffer

    $leak_buffer.each_with_index { |m, index|
      puts "Reading memory blocks #{index+1} of #{$leak_buffer.length} to page it in."

      m.index("A very long string to forces load all the string in memory to search for it :)")
    }
    puts "Done reading all memory blocks"
  end

  # Mark all the memory blocks allocated by /mem/alloc as ready to be freed by the GC
  get '/mem/free' do
    $leak_buffer = nil
    GC.start
  end

  get '/bigresponse/:size' do
    size = params[:size].to_i

    stream do |out|
      (size / LOREM_IPSUM.length).times { out << LOREM_IPSUM }
      out << LOREM_IPSUM[0..size%LOREM_IPSUM.length-1]
    end
  end
end
