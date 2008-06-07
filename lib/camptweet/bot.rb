module Camptweet
  class Bot
    
    attr_accessor :twitter_users
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
      connect_to_twitter
      connect_to_campfire
      login_to_campfire
      connect_to_campfire_room
    end
  
    def run
      last_statuses = initial_statuses
      
      loop do
        begin
          new_statuses = []
          checking_twitter_timelines do |user, status|
            if last_statuses[user].nil?
              # Only broadcast this tweet if we have an initial status against
              # which we can compare it.
              last_statuses[user] = status
            elsif status.created_at > last_statuses[user].created_at
              # Only consider the most recent tweet.
              new_statuses << status
              last_statuses[user] = status
            end
          end
              
          new_statuses.sort_by(&:created_at).each do |status|
            begin
              message = "[#{status.user.name}] #{status.text}"
              log.info message
              room.speak message
              log.debug "(Campfire updated)"
            rescue Timeout::Error => e
              log.info "Campfire timeout: (#{e.message})"
            ensure
              sleep 2
            end
          end
        rescue => e
          log.error e.message
          log.error e.backtrace
        end
        log.debug "Sleeping (10s)"
        sleep 10
      end
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
    
    def initial_statuses
      returning statuses = {} do
        checking_twitter_timelines do |user, status|
          statuses[user] = status
        end
      end
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
        ensure
          log.debug "   ...done."
          sleep 2
        end
      end
    end

  end
end