#!/usr/bin/env ruby

require File.expand_path('../command.rb', __FILE__)

module WebdavSync
  class List

    include Command
    
    def ls(path)
      encoded = URI.encode(path)
      Options.client.ls(encoded).each do |item|
        printf("%10d  %19s  %s%s\n",
              item.size || 0,
              item.last_modified ? item.last_modified.strftime("%Y/%m/%d %H:%M:%S") : "",
              item.basename,
              item.directory? ? '/' : '')
      end
    end

  end
end

list = WebdavSync::List.new
list.parse!

abort "Usage: #$0 [options] path" unless (path = ARGV.shift)
list.ls(path)
