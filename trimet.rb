#!/usr/bin/env ruby

require 'dotenv/load'
require 'uri'
require 'net/http'
require 'json'
require 'time'

url = "https://developer.trimet.org/ws/V1/arrivals/?locIDs=#{ENV['LOCS']}&json=true&appID=#{ENV['TRIMET_APPID']}"
uri = URI(url)
results = Net::HTTP.get(uri)

data = JSON.parse(results, symbolize_names: true)
puts data

now = Time.now()

for_sign = Array.new

data[:resultSet][:arrival].each do |arrival|
  begin
    estimated = Time.parse(arrival[:estimated])
  rescue
    puts "oops ", arrival
    next
  end

  due_in_minutes = ((estimated - now)/60).truncate(1)

  puts "#{due_in_minutes} minutes"
  puts arrival[:shortSign]

  if due_in_minutes <= ENV['TIME_CUTOFF'].to_i
    for_sign.push({ due: due_in_minutes, msg: arrival[:shortSign] })
  end
end

for_sign = for_sign[0..3]
for_sign.sort! { |a, b| a[:due] <=> b[:due] }
puts for_sign

targets = ENV['SIGNS'].split
  
targets.each do |target|
  url = "http://#{target}/trimet"
  puts url
  uri = URI(url)
  req = Net::HTTP::Post.new(uri)
  req.body = JSON.generate(for_sign)
  res = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(req)
    case res
    when Net::HTTPSuccess, Net::HTTPRedirection
      puts "Success"
    else
      res.value
    end
  end
end
