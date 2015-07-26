#!/usr/bin/env ruby
# encoding: utf-8
# require 'logger'
require 'json'
require 'mechanize'

def normalize_time_str(time_str)
  return nil if time_str.nil?
  m = time_str.match(%r|\A(\d{4}/\d{2}/\d{2}).+(\d{2}:\d{2})\z|)
  [m[1], m[2]].join(' ')
end

def get_nicovideo_logined_mechanize(email, password)
  m = Mechanize.new
  # m.log = Logger.new "debug.log"
  m.user_agent_alias = 'Windows Chrome'
  page = m.post('https://secure.nicovideo.jp/secure/login?site=nicolive',
    {
      'mail_tel' => email,
      'password' => password
    },
    {
      'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8'
    }
  )
  m
end

def get_all_my_live_urls(m)
  page = m.get('http://live.nicovideo.jp/my', [], m.page.uri, {
    'Accept-Language' => 'ja' # if accept-language doesn't contain 'ja', mypage doesn't contain 月別リンク
  })
  mypage_urls = page.search('//div[@id="e_m"]//a[starts-with(@href, "http://live.nicovideo.jp/my?")]/@href').map{|attr| attr.value}

  mypage_urls.map {|url|
    page_no = 0
    monthly_live_urls = []
    loop {
      $stderr.puts "Fetch live urls from url: #{url} page: #{page_no}"
      page = m.get("#{url}&page=#{page_no}")
      live_urls = page.search('//div[@class="liveListInner4"]//a[starts-with(@href, "http://live.nicovideo.jp/editstream/")][not(.//*)]/@href').map{|attr| attr.value}
      if live_urls.length == 0
        break
      end
      monthly_live_urls += live_urls
      page_no += 1
    }

    sleep 2.525

    monthly_live_urls
  }.flatten.sort{|a, b| a[2..-1].to_i <=> b[2..-1].to_i}
end

def get_information_from_live_urls(m, live_urls)
  sequence_number = 1
  live_urls.map {|live_url|
    live_id = live_url.match(/lv\d+/)[0]
    $stderr.puts "Fetch live information for #{live_id}"
    live_watch_url = "http://live.nicovideo.jp/watch/#{live_id}"
    page = m.get(live_watch_url, [], m.page.uri, {
      'Accept-Language' => 'ja' # if accept-language doesn't contain 'ja', date formats are changed
    })

    title_node = page.at('//span[@class="program-title"]')
    if title_node.nil?
      # Real watch page, so fetch information from CE APIs.
      response = JSON.parse(m.get("http://api.ce.nicovideo.jp/liveapi/v1/video.info?__format=json&v=#{live_id}").body)
      video_info_response = response['nicolive_video_response']['video_info']
      video_response = video_info_response['video']

      video_info = {
        :no => sequence_number,
        :id => video_response['id'],
        :community => video_response['provider_channel'] == 'community' ? video_info_response['community']['global_id'] : nil,
        :channel => video_response['provider_channel'] == 'channel' ? video_info_response['community']['global_id'] : nil,
        :title => video_response['title'],
        :open_time => video_response['open_time'],
        :start_time => video_response['start_time'],
        :end_time => video_response['end_time'],
        :view_counter => video_response['view_counter'],
        :comment_count => video_response['comment_count'],
      }
    else
      # Closed page
      title = title_node.text

      start_times = page.search('//div[@class="kaijo"]/strong')
      if start_times.length == 2
        open_time = nil
        start_time = start_times.map{|node| node.text}.join(' ')
      elsif start_times.length == 3
        open_time = [start_times[0].text, start_times[1].text].join(' ')
        # NOTE: if the day is changed between opening and starting, this might be wrong.
        start_time = [start_times[0].text, start_times[2].text].join(' ')
      else
        raise 'Weird!'
      end

      community_url_attr = page.at('//div[@class="com"]//a/@href')
      community_id = community_url_attr.nil? ? nil : community_url_attr.value.match(/co\d+\z/)[0]
      channel_url_attr = page.at('//div[@class="chan"]//a/@href')
      channel_id = channel_url_attr.nil? ? nil : channel_url_attr.value.match(/ch\d+\z/)[0]

      comment_area_texts = page.search("//div[@id='comment_area#{live_id}']/text()").map{|text_node| text_node.text.strip}.select{|text| text.length > 0}
      end_time = comment_area_texts[0].match(%r|\d{4}/\d{2}/\d{2}\([日月火水木金土]\) \d{2}:\d{2}|)[0]
      view_counter = comment_area_texts[1].match(/\A(\d+)人\z/)[1].to_i
      comment_count = comment_area_texts[2].to_i

      video_info = {
        :no => sequence_number,
        :id => live_id,
        :community => community_id,
        :channel => channel_id,
        :title => title,
        :open_time => normalize_time_str(open_time),
        :start_time => normalize_time_str(start_time),
        :end_time => normalize_time_str(end_time),
        :view_counter => view_counter,
        :comment_count => comment_count,
      }
    end

    sequence_number += 1

    sleep 2.525

    video_info
  }
end

def output_json(live_information)
  puts JSON.pretty_generate(live_information)
end

def main
  if ARGV.length != 2
    $stderr.puts "#{$PROGRAM_NAME} email password"
    exit(1)
  end

  m = get_nicovideo_logined_mechanize(*ARGV)
  live_urls = get_all_my_live_urls(m)
  live_information = get_information_from_live_urls(m, live_urls)
  output_json(live_information)
end

main
