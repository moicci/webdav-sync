#!/usr/bin/env ruby

require File.expand_path('../node.rb', __FILE__)
require File.expand_path('../options.rb', __FILE__)
require 'termcolor'
require 'pp'

module WebdavSync
  module Utils

    def verbose(message, color:nil, newline:true, force_verbose:false)
      if Options[:verbose] || force_verbose
        # 参考: http://d.hatena.ne.jp/keyesberry/20101107/p1
        message = TermColor.colorize(message, color) if color
        if newline
          puts message
        else
          print message
        end
      end
    end

    def error(e)
      #verbose("\nexception...\n#{e.backtrace.join('\n')}", 'red')
      color = 'red'
      verbose("\nexception... #{e.inspect}\n", color:color)
      e.backtrace.each do |line|
        verbose(line, color:color)
      end
    end

    # DAVに関する実行
    def execute(message, force_verbose = nil)
      return false if Options[:noexec]

      verbose("=> " + message, color:'yellow', newline:false, force_verbose:force_verbose)

      result = ' '
      try_dav do
        time_from = Time.now
        length = yield
        if length > 0
          seconds = Time.now - time_from
          if seconds > 0
            mb = length / 1024.0 / 1024.0
            mbps = mb * 8.0 / seconds
            result = sprintf(" %d seconds for %.1f MB .. %.1fmbps", seconds, mb, mbps)
          end
        end
        verbose(result, force_verbose:force_verbose)
      end
    end

    # DAVへのアクセス
    def try_dav

      Options.retries.times do
        begin
          yield
          return true
        rescue => e
          error(e)
        end
      end

      abort "retry out!"
      false
    end

    # テキストファイルに書かれたフォルダ名を読み込む
    def read_patterns(file, suffix = '')
      return unless file
      literals = []
      regexes = []
      if File.file?(file)
        open(file) do |io|
          regex_prefix = 'REGEXP:'
          while path = io.gets
            line = path.chop + suffix
            if line.start_with?(regex_prefix)
              regex = line[regex_prefix.length..-1]
              regexes << Regexp.new(regex)
            else
              literals << line
            end
          end
        end
      end
      [literals, regexes]
    end

  end
end
