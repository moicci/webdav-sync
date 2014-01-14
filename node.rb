require File.expand_path('../options.rb', __FILE__)
require File.expand_path('../monkeys.rb', __FILE__)
require File.expand_path('../utils.rb', __FILE__)
require 'pp'

module WebdavSync
  class Node

    class << self

      include WebdavSync::Utils

      # @return [String] ローカル側のトップディレクトリ
      def local_prefix
        @local_prefix ||= (Options[:local] || '')
      end

      # @return [String] DAV側のトップディレクトリ
      def dav_prefix
        unless @dav_prefix
          url = URI.parse(Options.end_point + '/')
          prefix = url.path
          @dav_prefix = prefix.gsub(%r{//+}, '/')
        end
        @dav_prefix
      end

      # コピー元の :from 配下のパスにする
      def to_local_path(name)
        "#{local_prefix}/#{name.purify}"
      end

      def strip_dav_path(full_path)
        return full_path[dav_prefix.length..-1] if full_path.start_with?(dav_prefix)
        ''
      end

      # DAV上の path 配下のアイテムのリストを返す
      def dav_items_of(path)
        items = {}
        Options.retries.times do
          begin
            Options.client.ls(path).each do |item|
              items[item.basename] = item
            end
            return items
          rescue => e
            error(e)
          end
        end
        items
      end
    end

    # @return [String] 入出力ともに使う相対パス
    attr_reader :path
    
    # @return [String] DAV用にURLエンコードしたパス
    attr_reader :encoded
    
    # @return [String] 上位のフォルダ名を含まないファイル名
    attr_reader :name

    def initialize(path, parent = nil)
      @path = path.purify
      @encoded = URI.encode(@path)
      @encoded = @encoded.gsub('[', '%5B')
      @encoded = @encoded.gsub(']', '%5D')
      @name = File.basename(@path)
      @parent = parent
      if parent
        @dav_item = parent.dav_item_of(@name)
      else
        #@dav_item = nil
        begin
          make_dav_dir
        rescue
        end
      end
    end

    def children_by_dav(&block)
      nodes = []
      dav_items.each_value do |item|
        node = Node.new(item.path, self)
        if block
          block.call(node)
        else
          nodes << node
        end
      end
      nodes
    end

    # name の名前を持つ子供の Node を返す
    # @return [Node]
    def child(name)
      self.class.new("#{@path}/#{name.purify}", self)
    end

    # DAV側のフォルダを作る
    def make_dav_dir
      @dav_item = Options.client.mkdir(@encoded)
    end

    # ローカル側のフォルダを作る
    def make_local_dir
      FileUtils.mkdir_p(local_path)
    end

    # DAV側にファイルをアップロードする
    def make_dav_file
      length = File.size(local_path)
      @dav_item = Options.client.put(local_path, @encoded)
      length
    end

    # ローカル側にファイルをダウンロードする
    def make_local_file
      Options.client.get(@encoded, local_path)
    end

    # DAV側にそのファイルがある？
    def on_dav?
      return true if @dav_item
      false
    end
    
    def on_local?
      File.exists?(local_path)
    end

    # DAV側のファイルのサイズ
    def dav_size
      return @dav_item.size if @dav_item
      nil
    end

    def local_size
      return File.size(local_path) if File.file?(local_path)
      0
    end

    # ローカルの File
    def local_file
      @local_file ||= File.new(local_path)
    end

    # ローカルのパス名
    def local_path
      @local_path ||= self.class.to_local_path(@path)
    end

    # DAV側の子供のアイテム
    def dav_item_of(name)
      dav_items[name]
    end

    def directory?
      return @dav_item.directory? if @dav_item
      File.directory?(local_path)
    end

    def file?
      return @dav_item.file? if @dav_item
      File.file?(local_path)
    end

    private
    
    def dav_items
      @dav_items ||= self.class.dav_items_of(@encoded)
    end
  end
end
