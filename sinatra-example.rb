#!/usr/bin/env ruby

require 'sinatra/base'

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

end