module Camptweet
  class Bot
    
    attr_accessor :twitter_users
    attr_accessor :twitter_search_terms
    attr_accessor :feed_urls
    attr_accessor :campfire_subdomain
    attr_accessor :campfire_use_ssl    
    attr_accessor :campfire_room
    attr_accessor :campfire_email
    attr_accessor :campfire_password
    attr_accessor :verbose
    attr_accessor :logfile
    attr_reader   :twitter, :campfire, :room, :log
  
    def initialize(&block)
      yield self if block_given?
      init_log
      add_twitter_search_urls_to_feed_urls
      connect_to_twitter
      connect_to_campfire
      login_to_campfire
      connect_to_campfire_room
    end
  
    def run
      last_statuses = {}
      last_feed_items = {}
      
      loop do
        begin
          new_statuses = []
          new_feed_items = []
          
          # check for updated tweets
          checking_twitter_timelines do |user, status|
            if last_statuses[user].nil?
              last_statuses[user] = status
            elsif status.created_at > last_statuses[user].created_at
              new_statuses << status
              last_statuses[user] = status
            end
          end
          
          # post any updated tweets to campfire
          new_statuses.sort_by(&:created_at).each do |status|
            begin
              send_message_to_campfire "[#{status.user.name}] #{status.text}"
            rescue Timeout::Error => e
              log.info "Campfire timeout: (#{e.message})"
            ensure
              sleep 2
            end
          end
          
          # check for updated rss feed items and post them to campfire
          checking_feeds do |feed_url, feed, item|
            log.debug "...checking last_feed_item for this feed: #{last_feed_items[feed_url].blank? ? 'no item' : last_feed_items[feed_url].title}"
            if last_feed_items[feed_url].blank?
              last_feed_items[feed_url] = item
            elsif timestamp_for(item) > timestamp_for(last_feed_items[feed_url])
              last_feed_items[feed_url] = item
              send_message_to_campfire feed_item_message_for(feed, item)
            end          
          end
              
        rescue => e
          log.error e.message
          log.error e.backtrace
          # re-establish potentially lost connection to Twitter
          connect_to_twitter
        end
        log.debug "Sleeping (10s)"
        sleep 10
      end
    end
    
    def twitter_users
      @twitter_users ||= []
    end
    
    def twitter_search_terms
      @twitter_search_terms ||= []
    end
    
    def feed_urls
      @feed_urls ||= []
    end
    
    private
    
    def connect_to_twitter
      @twitter = Twitter::Client.new
      unless twitter
        log.info "Unable to establish connection to Twitter.  Exiting."
        exit
      end  
      log.info "Established connection to Twitter."
    end
    
    def connect_to_campfire
      @campfire = Tinder::Campfire.new(campfire_subdomain, :ssl => campfire_use_ssl)
      unless campfire
        log.info "Unable to establish connection to Campfire (#{campfire_subdomain}).  Exiting."
        exit
      end
      log.info "Established connection to Campfire (#{campfire_subdomain})."
    end
    
    def login_to_campfire
      unless campfire.login(campfire_email, campfire_password)
        log.info "Unable to log in to Campfire (#{campfire_subdomain}).  Exiting."
        exit
      end
      log.info "Logged in to Campfire (#{campfire_subdomain})."
      log.debug "Available rooms: #{campfire.rooms.map(&:name).inspect}"
    end
    
    def connect_to_campfire_room
      @room = campfire.find_room_by_name(campfire_room)
      if room
        log.info "Entered Campfire room '#{room.name}'."
      else
        log.info "No room '#{campfire_room}' found.  Exiting."
        exit
      end      
    end
    
    def init_log
      @log = Logger.new(logfile || 'camptweet.log')
      log.level = verbose? ? Logger::DEBUG : Logger::INFO
    end
    
    def verbose?
      verbose
    end
    
    def checking_twitter_timelines
      twitter_users.each do |user|
        begin
          log.debug "Checking '#{user}' timeline..."
          twitter.timeline_for(:user, :id => user, :count => 1) do |status|
            yield user, status
          end
        rescue Timeout::Error => e
          log.error "Twitter timeout: (#{e.message})"
        rescue Twitter::RESTError => e
          log.error "Twitter REST Error: (#{e.message})"
        rescue => e
          log.error "Twitter error: (#{e.message})"
          connect_to_twitter
        ensure
          log.debug "   ...done."
          sleep 2
        end
      end
    end
    
    def checking_feeds
      feed_urls.each do |feed_url|
        begin
          log.debug "Checking '#{feed_url}'..."
          rss = SimpleRSS.parse(open(feed_url))
          if rss.items.blank?
            log.debug "No items in this RSS feed."
            next
          end
          item = rss.items.first
          log.debug "First item has title #{item.title} with timestamp #{timestamp_for(item)}"
          yield feed_url, rss, item
        rescue => e
          log.error "Error in parsing feed: (#{e.message})"
          log.error e.backtrace
        ensure
          log.debug "   ...done."
          sleep 2
        end
      end
    end
    
    def timestamp_for(feed_item)
      return feed_item.published if feed_item.published
      return feed_item.pubDate if feed_item.pubDate
      return feed_item.updated if feed_item.updated
      return feed_item.dc_date if feed_item.dc_date        
      log.debug "Couldn't find a date for feed item #{feed_item.inspect}"      
    end
    
    def send_message_to_campfire(message)
      begin
        log.info message
        room.speak message
        log.debug "(Campfire updated)"
      rescue Timeout::Error => e
        log.info "Campfire timeout: (#{e.message})"
      end
    end
    
    def feed_item_message_for(feed, item)
      "[#{feed.title}] #{item.title} (#{item.author}): #{item.link}"
    end
      
    def add_twitter_search_urls_to_feed_urls
      twitter_search_terms.each do |search_term|
        feed_urls << "http://summize.com/search.atom?q=#{search_term}"
      end
    end

  end
end