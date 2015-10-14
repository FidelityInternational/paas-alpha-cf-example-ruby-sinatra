#!/usr/bin/env ruby

require 'sinatra/base'

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

  get '/cpuload' do
    child_pid = Process.fork do
      genload
    end

    Process.detach child_pid

    "Generating CPU load in the background. Hit refresh to generate more load"
  end

end
