#!/usr/bin/env ruby

require 'sinatra/base'
require 'tilt/erb'

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

end
