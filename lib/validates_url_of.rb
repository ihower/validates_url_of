module Handlino
  module ValidatesUrlOf
  
    def self.included(base)
      base.send(:extend, ClassMethods)
    end
    
    module ClassMethods
    
      def validates_url_of( attr_name, options = {} )
        options[:enable_http_check] ||= false
        
        unless options[:message]
          options[:message] = 'is not valid'
          options[:message] += ' or not responding' if options[:enable_http_check]
        end
        
        define_method( "try_fixing_#{attr_name}_url") do
          value = read_attribute(attr_name)
          return if value.blank?
          write_attribute( attr_name, "http://#{value}" ) unless ( value.include?('http://') || value.include?('https://') )
        end
        
        before_validation "try_fixing_#{attr_name}_url".to_sym
        
        # modify from http://www.igvita.com/2006/09/07/validating-url-in-ruby-on-rails/ and Validates_URL plugin
        validates_each attr_name, :allow_blank => true do |r, a, v|
          if v.to_s =~  /(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix
            if options[:enable_http_check] && RAILS_ENV == 'production'
              require 'net/http'
              begin
                uri = URI.parse(v)
                if uri.kind_of? URI::HTTP then
                  r.errors.add(a, options[:message]) unless Net::HTTP.get_response(uri).kind_of? Net::HTTPSuccess
                else
                  r.errors.add(a, options[:message])
                end
              rescue URI::InvalidURIError
                r.errors.add(a, options[:message])
              rescue SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EHOSTUNREACH
                r.errors.add(a, options[:message])
              rescue Timeout::Error
                r.errors.add(a, options[:message])
              end
            end
          else
            r.errors.add(a, options[:message])
          end
        end
        
      end
    end

  end
end