#!/usr/bin/env ruby

require File.expand_path('../command.rb', __FILE__)

module WebdavSync
  class Upload

    include Command

    # DAVへのファイルアップロード
    def copy_file(node)
      message = "  #{node.name}..."
      if (Options[:newer] && node.local_file.mtime < Options[:newer]) ||
        node.local_file.size == node.dav_size
        verbose(message, color:'green')
      else
        execute(message){ node.make_dav_file }
      end
    end

    # DAV側のフォルダ作成
    def mkdir(node)
      message = "#{node.path}..."
      unless node.on_dav?
        execute(message){ node.make_dav_dir; 0 }
      else
        verbose(message)
      end
    end

    # ローカルディレクトリの読み込み
    # @param [Node] parent
    def scan_local(parent)
      return unless target?(parent)
      return unless File.directory?(parent.local_path)

      has_file = false
      #Dir.foreach(parent.local_path) do |name|
      dir_entries(parent.local_path) do |name|
        next if name.start_with?('.')
        full = "#{parent.local_path}/#{name}"
        node = parent.child(name)
        if File.directory?(full)
          mkdir(node)
          scan_local(node)
        elsif File.file?(full)
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

upload = WebdavSync::Upload.new
upload.parse!
node = WebdavSync::Node.new('')
upload.scan_local(node)
