#!/usr/bin/env ruby
require 'cgi'
require 'json'

json_text = File.read(ARGV[0])
data = JSON.parse(json_text)

htmls = ['<table>', '<tr>', '<th>no</th>', '<th>タイトル</th>', '<th>開始日時</th>', '<th>閲覧数</th>', '<th>コメント数</th>', '</tr>']
data.each {|record|
  htmls << '<tr>'
  htmls << "<td>#{record['no']}</td>"
  htmls << "<td>#{CGI.escapeHTML(record['title'])}</td>"
  htmls << "<td>#{record['start_time']}</td>"
  htmls << "<td>#{record['view_counter']}</td>"
  htmls << "<td>#{record['comment_count']}</td>"
  htmls << '</tr>'
}
htmls << '</table>'

puts htmls.join("\n")
