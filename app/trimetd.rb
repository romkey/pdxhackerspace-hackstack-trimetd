#!/usr/bin/env ruby

require 'dotenv/load'
require 'json'
require 'time'
require 'uri'
require 'net/http'
require 'mqtt'

def fetch_trimet
  url = "https://developer.trimet.org/ws/V1/arrivals/?locIDs=#{ENV['LOCS']}&json=true&appID=#{ENV['TRIMET_APPID']}"
  uri = URI(url)
  results = Net::HTTP.get(uri)

  data = JSON.parse(results, symbolize_names: true)
  puts data

  now = Time.now()

  results = Array.new

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
      results.push({ due: due_in_minutes, msg: arrival[:shortSign] })
    end
  end

  results
end

mqtt_url = ENV['MQTT_URL']

client = MQTT::Client.connect(mqtt_url)
client.set_will('trimetd/availability', 'offline')

while true do
  while !client.connected? do
    sleep(10)
    client = MQTT.connect(mqtt_url)
  end

  results = fetch_trimet
  results = results[0..3]
  results.sort! { |a, b| a[:due] <=> b[:due] }

  client.publish('trimetd/arrivals', JSON.generate(results))
  client.publish('trimetd/availability', 'online')
  sleep(30)
end

  
