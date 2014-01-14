require File.expand_path('../webdav_client.rb', __FILE__)

module WebdavSync
  class Options

    class << self

      def [](key)
        @options ||= {}
        @options[key]
      end

      def []=(key, value)
        @options ||= {}
        @options[key] = value
      end

      def retries
        @retries ||= (@options[:retries] || '3').to_i
      end

      def end_point
        unless @end_point
          @end_point = self[:end_point] || ENV['WEBDAVSYNC_END_POINT']
          abort "environment variable WEBDAVSYNC_END_POINT must be set!" unless @end_point
          @end_point += '/' unless @end_point.end_with?('/')
        end
        @end_point
      end

      def client
        @client ||= WebdavClient.new(end_point)
      end

    end
  end
end
