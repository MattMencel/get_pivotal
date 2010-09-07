require 'rubygems'
require 'pivotal-tracker'
require 'net/smtp'
require 'ap'

def send_email(to, body)
  from = 'FROM'
  from_alias = 'FIRST LAST'
  subject = 'Pivotal Tracker Summary'
  msg = <<END_OF_MESSAGE
From: #{from_alias} <#{from}>
To: <#{to}>
MIME-Version: 1.0
Content-type: text/html
Subject: #{subject}

#{body}

END_OF_MESSAGE
  Net::SMTP.start('SMTP HOST') do |smtp|
    smtp.send_message msg, from, to
  end
end

TOKEN = "PIVOTAL API TOKEN"

PivotalTracker::Client.token = TOKEN

@projects = PivotalTracker::Project.all
html_doc = "<HTML><HEAD></HEAD><BODY><H1>Pivotal Tracker Project List Overview</H1>"

@projects.each do |p|
  html_doc << "<H2 style=\"BACKGROUND-COLOR: 66CCFF\">#{p.name}</H2> URL: <a href=\"http://www.pivotaltracker.com/projects/#{p.id}\">http://www.pivotaltracker.com/projects/#{p.id}</a></BR>"
  html_doc << "<H3>Current Stories</H3>"
  puts p.name
  @current_stories = p.iteration(:current).stories
  if @current_stories.size == 0
    html_doc << "<FONT style=\"BACKGROUND-COLOR: yellow\"><b>WARNING:</b></FONT>  No CURRENT stories in this project.  Does it need to be updated or archived?"
  else
    @current_stories.each do |s|
      html_doc << "<ul><li><b>#{s.name}</b> (<a href=\"#{s.url}\">#{s.url})</a></li>"
      if s.owned_by == nil
        html_doc << "<ul><li><FONT style=\"BACKGROUND-COLOR: yellow\"><b>WARNING:</b></FONT>  THIS STORY NEEDS TO BE ASSIGNED TO SOMEBODY OR PUT BACK IN THE ICEBOX</li></ul>"
      else
        html_doc << "<ul><li>OWNER: #{s.owned_by}</li><li>REQUESTOR: #{s.requested_by}</li><li>STATUS: #{s.current_state}</li></ul>"
      end
      html_doc << "</ul>"
    end
  end
end

send_email("EMAIL", html_doc)
File.open("projects.html", 'w') { |f| f.write(html_doc) }

exit

member_hsh = Hash.new()
member_hsh_prepend = "<HTML><HEAD></HEAD><BODY><H1>Pivotal Tracker Stories I Own</H1>"

@projects.each do |p|
  @memberships = p.memberships.all
  @memberships.each do |m|
    if member_hsh[m.name] == nil
      member_hsh[m.name] = "<H2 style=\"BACKGROUND-COLOR: 66CCFF\">#{p.name}</H2> URL: <a href=\"http://www.pivotaltracker.com/projects/#{p.id}\">http://www.pivotaltracker.com/projects/#{p.id}</a></BR><H3>Current Stories</H3>"
    else
      member_hsh[m.name] = member_hsh[m.name] += "<H2 style=\"BACKGROUND-COLOR: 66CCFF\">#{p.name}</H2> URL: <a href=\"http://www.pivotaltracker.com/projects/#{p.id}\">http://www.pivotaltracker.com/projects/#{p.id}</a></BR><H3>Current Stories</H3>"
    end
  end
  
  @current_stories = p.iteration(:current).stories
  @current_stories.each do |s|
    if s.owned_by != nil
      begin
        member_hsh[s.owned_by] = member_hsh[s.owned_by] += "<ul><li><b>#{s.name}</b> (<a href=\"#{s.url}\">#{s.url})</a></li></ul>"
      rescue Exception => e
        ap e
      end
      
    end
  end
end

member_hsh.each_pair do |key,val|
  val = member_hsh_prepend.concat(val)
  File.open("#{key}.html", 'w') { |f| f.write(val) }
end