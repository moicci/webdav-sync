#!/usr/bin/env ruby

require File.expand_path('../command.rb', __FILE__)

module WebdavSync
  class Cleanup

    include Command

    # DAVのファイルが必要か？
    def validate_file(node)
      message = "  #{node.name}..."
      #if (Options[:newer] && node.dav_mtime < Options[:newer]) ||
      if node.local_size == node.dav_size
        #verbose(message, color:'green')
      else
        if execute(message, :force_verbose){ node.delete_dav_file }
          @script ||= Options[:script]
          if @script
            # バックスラを二つ続けないと sh のエラーになる
            local_path = node.local_path.gsub('"', '\\"')
            script = "#{@script} \"#{local_path}\""
            verbose("running script: #{script}")
            `#{script}`
          end
        end
      end
    end

    # DAV側の読み込み
    # @param [Node] parent
    def scan_dav(parent = nil)
      parent.children_by_dav do |node|
        if node.directory?
          message = "#{node.name}..."
          if node.local_exists?
            verbose(message)
            scan_dav(node)
          else
            execute(message, :force_verbose){ node.delete_dav_file }
          end
        elsif node.file?
          validate_file(node)
        end
      end
    end
  end
end

cleanup = WebdavSync::Cleanup.new
cleanup.parse!
node = WebdavSync::Node.new('')
cleanup.scan_dav(node)
