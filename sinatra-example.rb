#!/usr/bin/env ruby

require 'sinatra/base'
require 'tilt/erb'
require 'vmstat'
require 'os'

def genload
  1000.times do |i|
    100000.downto(1) do |j|
      Math.sqrt(j) * i / 0.2
    end
  end
end

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

  get '/cpuload/:processes' do
    processes = params[:processes].to_i
    processes.times do |p|
      child_pid = Process.fork do
        genload
      end
    end

    Process.wait

    "Finished generating CPU load - #{processes} processes complete"
  end

  get '/mem/alloc/:size_mb/?:leak?' do
    content_type 'application/text'

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
end
