#!/usr/bin/env ruby

require 'rubygems'
require 'net/http'
require 'feedjira'
require     'json'
require      'uri'
require 'colorize'

def open_remote_json(url)
  url = URI.parse url
  content = Net::HTTP.get url
  JSON.parse content
end

def color_timestamp(time)
  now_i = Time.now.strftime("%Y%m%d%H%M%S").to_i
  time_i = time
  time = time.to_s
  if time_i + 1000000 > now_i
    time.light_green
  elsif time_i + 2000000 > now_i
    time.light_yellow
  elsif time_i + 3000000 > now_i
    time.light_red
  else
    time.light_black
  end
end

def string_includes(string, pattern)
  if string.include? pattern.upcase
    true
  elsif string.include? pattern.downcase
    true
  elsif string.include? pattern.swapcase
    true
  elsif string.include? pattern.capitalize
    true
  else
    false
  end
end

urls_stackexchange = [
  'https://ethereum.stackexchange.com/feeds/tag'                               \
    + '?tagnames=parity+or+ethcore+or+kovan+or+parity-wallet&sort=newest',
  'https://ethereum.stackexchange.com/feeds/newest',
  'https://ethereum.stackexchange.com/feeds/hot'
]
url_github = 'https://github.com/5chdn.private.atom'                           \
  + '?token=APAEhSKlnFBqp8GIet-qkeXlnfX5TrOjks621k6QwA=='
urls_reddit = [
  'https://www.reddit.com/r/ethereum/new/.rss',
  'https://www.reddit.com/r/ethtrader/new/.rss',
  'https://www.reddit.com/r/ether/new/.rss',
  'https://www.reddit.com/r/eth/new/.rss',
  'https://www.reddit.com/r/ethdev/new/.rss',
  'https://www.reddit.com/r/cryptocurrency/new/.rss',
  'https://www.reddit.com/r/dapps/new/.rss',
  'https://www.reddit.com/r/btc/new/.rss',
  'https://www.reddit.com/r/bitcoin/new/.rss',
  'https://www.reddit.com/r/smartcontracts/new/.rss',
  'https://www.reddit.com/r/ethermining/new/.rss',
  'https://www.reddit.com/r/ethereumclassic/new/.rss'
]
urls_twitter = [
  'https://twitrss.me/twitter_user_to_rss/?user=paritytech&replies=on',
  'https://twitrss.me/twitter_search_to_rss/?term=ethereum',
  'https://twitrss.me/twitter_search_to_rss/?term=#parity'
]
urls_gitter = Hash.new
urls_gitter['ethcore/parity']                                                  \
  = 'https://api.gitter.im/v1/rooms/56b496a4e610378809c004a3/chatMessages'     \
  + '?access_token=f259569a935c9c76a0371858eda208846225e639&limit=10'
urls_gitter['ethcore/parity/miners']                                           \
  = 'https://api.gitter.im/v1/rooms/57737b32c2f0db084a208140/chatMessages'     \
  + '?access_token=f259569a935c9c76a0371858eda208846225e639&limit=10'
urls_gitter['ethcore/parity-poa']                                              \
  = 'https://api.gitter.im/v1/rooms/583c2f8ad73408ce4f392d9a/chatMessages'     \
  + '?access_token=f259569a935c9c76a0371858eda208846225e639&limit=10'
urls_gitter['kovan-testnet/Lobby']                                             \
  = 'https://api.gitter.im/v1/rooms/58b576c6d73408ce4f4d70d6/chatMessages'     \
  + '?access_token=f259569a935c9c76a0371858eda208846225e639&limit=10'
urls_gitter['ethcore/parity.js']                                               \
  = 'https://api.gitter.im/v1/rooms/5819ca18d73408ce4f3306c8/chatMessages'     \
  + '?access_token=f259569a935c9c76a0371858eda208846225e639&limit=10'
urls_gitter['polkadot-io/Lobby']                                               \
  = 'https://api.gitter.im/v1/rooms/582987a3d73408ce4f35b8c7/chatMessages'     \
  + '?access_token=f259569a935c9c76a0371858eda208846225e639&limit=10'
items = Hash.new

begin
  counted = 0
  urls_gitter.each do |room, url|
    feed_gitter = open_remote_json url
    feed_gitter.each do |message|
      sent = Time.parse(message['sent'])
      link = "https://gitter.im/" + room + "?at=" + message['id']
      items[sent.strftime("%Y%m%d%H%M%S").to_i] = "  0 GI  ".light_magenta     \
        + '%-64.64s' % message['text'][0..63] + " " + link.light_magenta
      counted += 1
    end
  end
  urls_stackexchange.each do |url|
    feed_stackexchange = Feedjira::Feed.fetch_and_parse url
    feed_stackexchange.entries.each do | question |
      if (                                                                     \
        string_includes(question.title, 'parity')                              \
        or string_includes(question.title, 'ethcore')                          \
        or string_includes(question.summary, 'parity')                         \
        or string_includes(question.summary, 'ethcore')                        \
        or question.categories.include? 'parity'                               \
        or question.categories.include? 'ethcore'                              \
        or question.categories.include? 'kovan'                                \
        or question.categories.include? 'parity-wallet'                        \
      )
        items[question.updated.strftime("%Y%m%d%H%M%S").to_i]                  \
          = "  1 SE  ".light_cyan + '%-64.64s' % question.title[0..63] + " "   \
          + question.entry_id.light_cyan
        counted += 1
      end
    end
  end
  feed_github = Feedjira::Feed.fetch_and_parse url_github
  feed_github.entries.each do | item |
    if ((                                                                      \
      string_includes(item.url, "parity")                                      \
      or string_includes(item.url, "ethcore")                                  \
    ) and (                                                                    \
      string_includes(item.url, "issue")                                       \
      or string_includes(item.url, "pull")                                     \
    ))
      items[item.updated.strftime("%Y%m%d%H%M%S").to_i] = "  2 GH  ".light_red \
        + '%-64.64s' % item.title[0..63] + " " + item.url.light_red
      counted += 1
    end
  end
  feed_github                                                                  \
    = Feedjira::Feed.fetch_and_parse 'https://github.com/paritytech.atom'
  feed_github.entries.each do | item |
      items[item.updated.strftime("%Y%m%d%H%M%S").to_i] = "  2 GH  ".light_red \
        + '%-64.64s' % item.title[0..63] + " " + item.url.light_red
      counted += 1
  end
  urls_reddit.each do |url|
    feed_reddit = Feedjira::Feed.fetch_and_parse url
    feed_reddit.entries.each do | post |
      if (                                                                     \
        string_includes(post.title, "parity")                                  \
        or string_includes(post.title, "ethcore")                              \
        or string_includes(post.content, "parity")                             \
        or string_includes(post.content, "ethcore")                            \
      )
        items[post.updated.strftime("%Y%m%d%H%M%S").to_i]                      \
          = "  3 RD  ".light_green + '%-64.64s' % post.title[0..63] + " "      \
          + post.links.first.light_green
        counted += 1
      end
    end
  end
  urls_twitter.each do |url|
    feed_twitter = Feedjira::Feed.fetch_and_parse url
    feed_twitter.entries.each do | tweet |
      if (                                                                     \
        string_includes(tweet.title, "parity")                                 \
        or string_includes(tweet.title, "ethcore")                             \
        or string_includes(tweet.author, "parity")                             \
        or string_includes(tweet.author, "ethcore")                            \
      )
        items[tweet.published.strftime("%Y%m%d%H%M%S").to_i]                   \
          = "  4 TW  ".light_blue + '%-64.64s' % tweet.title[0..63] + " "      \
          + tweet.url.light_blue
        counted += 1
      end
    end
  end
  items = items.sort.to_h
  system 'clear'
  items.each do |k, i|
    printf color_timestamp(k) + " " + i.gsub(/\n/, " ") + "\n"
  end
  printf color_timestamp(Time.now.strftime("%Y%m%d%H%M%S").to_i)               \
    + "         LAST UPDATE " + counted.to_s + " ITEMS\n"
  sleep 900
end while true
