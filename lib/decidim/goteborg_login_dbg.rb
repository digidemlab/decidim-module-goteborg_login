
module Decidim
  module GoteborgLogin
    module Dbg 
      def dev_log(text) 
        if Rails.env.development?
          puts " D: #{text}"
        else
          if Rails.logger
            Rails.logger.warn "PL: #{text}"
          else
            puts "PP: #{text}"
          end
        end
      end
      
       module_function :dev_log
    end
  end
end