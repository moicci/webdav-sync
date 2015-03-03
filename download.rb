#!/usr/bin/env ruby

require File.expand_path('../command.rb', __FILE__)

module WebdavSync
  class Download

    include Command

    # DAVへのファイルアップロード
    def copy_file(node)
      message = "  #{node.name}..."
      #if (Options[:newer] && node.dav_mtime < Options[:newer]) ||
      if node.local_size == node.dav_size
        verbose(message, color:'green')
      else
        if execute(message, :force_verbose){ node.make_local_file }
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

    # DAV側のフォルダ作成
    def mkdir(node)
      message = "#{node.path}..."
      unless node.on_local?
        execute(message, :force_verbose){ node.make_local_dir; 0 }
      else
        verbose(message)
      end
    end

    # DAV側の読み込み
    # @param [Node] parent
    def scan_dav(parent = nil)
      return unless target?(parent)

      has_file = false
      parent.children_by_dav do |node|
        if node.directory?
          if target?(node)
            mkdir(node)
            scan_dav(node)
          end
        elsif node.file?
          has_file = true
          copy_file(node)
        end
      end

      # ファイルのあるディレクトリのみ excludes する
      # 例えば下記のような構成のとき b, c のアルバムフォルダは次回から excludes して欲しいが
      # a のアーティストフォルダに、いつかアルバムフォルダが追加されたときにも scan 対象と
      # して欲しいので a は含まない
      #
      # a) Miles Davis
      # b) Miles Davis/Kind of Blue
      # c) Miles Davis/In a Silent Way
      # 
      add_exclude(parent) if has_file
    end
  end
end

download = WebdavSync::Download.new
download.parse!
node = WebdavSync::Node.new('')
download.scan_dav(node)
