#!/usr/bin/env ruby
require 'cgi'
require 'json'
require './dateutil'
require 'pp'

json_text = File.read(ARGV[0])
data = JSON.parse(json_text)

live_count = data.length
all_duration_seconds = 0
max_comments = 0
max_listeners = 0
data.each {|record|
  end_time = DateUtil::parse_date(record['end_time'])
  start_time = DateUtil::parse_date(record['start_time'])

  duration_seconds = (end_time - start_time).to_i
  all_duration_seconds += duration_seconds

  max_comments = [record['comment_count'], max_comments].max
  max_listeners = [record['view_counter'], max_listeners].max
}

info = {
  :live_count => live_count,
  :all_duration_seconds => all_duration_seconds,
  :max_comments => max_comments,
  :max_listeners => max_listeners,
}

puts JSON.pretty_generate(info)
