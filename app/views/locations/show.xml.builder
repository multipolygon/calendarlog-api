xml.instruct! :xml, encoding: "UTF-8"

## http://www.rssboard.org/rss-2-0-11
## https://github.com/simplepie/simplepie-ng/wiki/Spec:-iTunes-Podcast-RSS
## https://validator.w3.org/feed/check.cgi

schema = {
  version: "2.0",
  "xmlns:atom" => "http://www.w3.org/2005/Atom",
}

xml.rss schema do
  xml.channel do
    xml.atom :link, href: request.original_url, rel: :self, type: "application/rss+xml"
    xml.pubDate @location.updated_at.rfc822
    xml.lastBuildDate @location.updated_at.rfc822
    xml.ttl 24.hours.to_i
    xml.title @location.title
    xml.link link = request.original_url
    xml.description @feed ? @feed.description : "Unified and curated feed."
    @location.precipitation.each_pair do |year, months|
      months.each_pair do |month, days|
        days.each_pair do |day, val|
          begin
            xml.item do
              xml.pubDate DateTime.new(year.to_i, month.to_i, day.to_i).rfc822
              xml.description val
            end
          rescue Date::Error
          end
        end
      end
    end
  end
end
