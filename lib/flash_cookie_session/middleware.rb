module FlashCookieSession
  class Middleware
    USER_AGENT_MATCHER = /^(Adobe|Shockwave) Flash/.freeze
    HTTP_REFERER_MATCHER = /\.swf$/.freeze
    SWFUPLOAD_MATCHER = /swfupload$/

    def initialize(app, session_key = Rails.application.config.session_options[:key])
      @app = app
      @session_key = session_key
    end

    def call(env)
      referrer = env['HTTP_REFERER'].to_s.split('?').first

      # if the agent matches, it's a .swf referer or the target path contains swfupload
      if env['HTTP_USER_AGENT'] =~ USER_AGENT_MATCHER || referrer =~ HTTP_REFERER_MATCHER || env['PATH_INFO'] =~ SWFUPLOAD_MATCHER
        req = Rack::Request.new(env)
        # if session key doesn't exist in cookie, but is included in the request array
        if (not env['HTTP_COOKIE'].to_s.include?(@session_key)) and req.params[@session_key]
          the_session_key = [ @session_key, req.params[@session_key] ].join('=').freeze 
          if req.params['remember_token'] && req.params['remember_token'] != 'null'
            the_remember_token = [ 'remember_token', req.params['remember_token'] ].join('=').freeze
          else
            the_remember_token = nil
          end
          cookie_with_remember_token_and_session_key = [ the_remember_token, the_session_key ].compact.join('\;').freeze
          env['HTTP_COOKIE'] = cookie_with_remember_token_and_session_key 
          puts "Applied cookie: #{env['HTTP_COOKIE']}"
          puts "Applying session key: #{the_session_key.inspect}"
        end
        env['HTTP_ACCEPT'] = "#{req.params['_http_accept']}".freeze if req.params['_http_accept']
      end

      @app.call(env)
    end
  end
end
