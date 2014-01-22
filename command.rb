require File.expand_path('../node.rb', __FILE__)
require File.expand_path('../options.rb', __FILE__)
require 'fileutils'
require 'date'
require 'termcolor'
require 'pp'

module WebdavSync
  module Command

    include Utils

    def target?(node)
      return false if @excludes && @excludes.include?(node.path)
      return false if @excluding_regexes && @excluding_regexes.find {|regex| regex.match(node.path) }

      unless node.path.empty?
        target_path = node.path + "/"
        if @includes
          return false unless @includes.find {|path| target_path.start_with?(path) }
        end
        if @including_regex
          return false unless @including_regex.find {|regex| regex.match(target_path) }
        end
      end

      true
    end

    def add_exclude(node)
      if @excludes_to
        @excludes_to.puts(node.path)
        @excludes_to.flush
      end
    end

    def parse!
      opt = OptionParser.new do |opt|
        opt.on('-v', '--verbose', 'verbose') {|value| Options[:verbose] = true }
        opt.on('-n', '--noexec', 'ディレクトリ作成、ファイルアップロード、ダウンロードの実行はしない') {|value| Options[:noexec] = true }
        opt.on('-l dir', '--local dir', 'ローカルのトップディレクトリまたは唯一のアップロードファイル') {|value| Options[:local] = value }
        opt.on('-i file', '--includes file', '対象とする入力元ディレクトリを書いたファイル') {|value| Options[:includes] = value }
        opt.on('-e file', '--excludes file', '除外する入力元ディレクトリを書いたファイル') {|value| Options[:excludes] = value }
        opt.on('-E file', '--excludes-to file', '成功したディレクトリを出力するファイル') {|value| Options[:excludes_to] = value }
        opt.on('-r retries', '--retries retries', 'コピー等のエラー時のリトライ回数') {|value| Options[:retries] = value }
        opt.on('-d datetime', '--newer datetime', '指定された日時より新しい物だけを対象とする。') {|value| Options[:newer] = DateTime.parse(value) }
        opt.on('-s script', '--script script', 'ダウンロードされたファイル名を渡すスクリプト') {|value| Options[:script] = value }
        opt.on('-u url', '--url url', 'DAVサーバのエンドポイント') {|value| Options[:end_point] = value }
        opt.parse!(ARGV)
      end

      @excludes, @excluding_regexes = read_patterns(Options[:excludes])

      if Options[:includes]
        @includes, @including_regexes = read_patterns(Options[:includes], '/')
      else
        @includes = ARGV unless ARGV.empty?
        @including_regexes = nil
      end

      @excludes_to = open(Options[:excludes_to], 'a') if Options[:excludes_to]
    end

  end
end
