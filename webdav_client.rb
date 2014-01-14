# このソースは下記のURLにあるものに ls を追加した。
# http://d.hatena.ne.jp/alunko/20071028/1193523622
#
# WebDAV の仕様は http://webdav.todo.gr.jp/download/rfc2518j.txt
require 'uri'
require 'net/http'
require 'rexml/document'
require 'rexml/formatters/pretty'
require 'date'
require 'pp'
#
# webdav-client
#
class WebdavClient

  class Item

    attr_reader :path
    attr_reader :type
    attr_reader :last_modified
    attr_reader :size

    def initialize(elem, basic_path)
      #@path = elem.elements.first('D:href').text
      @path = URI.decode(REXML::XPath.first(elem, 'D:href').text)[basic_path.length..-1]
      props = REXML::XPath.first(elem, 'D:propstat/D:prop')
      @type = REXML::XPath.first(props, 'lp1:resourcetype/D:collection') ? :directory : :file
      if @type == :file
        @size = REXML::XPath.first(props, 'lp1:getcontentlength').text.to_i
        @last_modified = DateTime.parse(REXML::XPath.first(props, 'lp1:getlastmodified').text)
      end
    end

    def to_s
      s = directory? ? 'D' : 'F'
      s += ") #{@path}"
      s += ", #{@size} bytes, #{@last_modified}" if file?
      s
    end

    def basename
      File.basename(@path)
    end

    def directory?
      @type == :directory
    end

    def file?
      @type == :file
    end

  end

  #
  # webdav_url: host url (ex http://hostname:port/path/to/ )
  # proxy_addr(option) : proxy_addr (ex proxy.host.com )
  # proxy_port(option) : proxy_port (ex 3128)
  def initialize(webdav_url, proxy_addr = nil, proxy_port = nil)
    unless /([a-z]+):\/\/([a-zA-Z0-9\.]+)(:[0-9]+){0,1}(.*)/ =~ webdav_url
      raise ArgumentError.new("Invalid URL #{webdav_url}")
    end
    address = $2
    port = $3 || 80
    port.delete(':') if port.is_a?(String)
    basic_path = $4 || '/'
    basic_path = basic_path + '/' unless basic_path[basic_path.length - 1].chr() == '/'
    @basic_path = basic_path
    @http = Net::HTTP.new(address, port, proxy_addr, proxy_port)
  end

  # =put=
  # put file
  #
  # src_path: local file path
  # dest_path: remote-server destination path
  def put(src_path, dest_path = nil)
    dest_path = File.basename(src_path) if dest_path.nil?()
    req = Net::HTTP::Put.new(@basic_path + dest_path)
    req.content_length = File.size(src_path)
    File.open(src_path, 'rb'){ |io|
      req.body_stream = io
      res = @http.request(req)
      raise "Invalid HttpResponse Code: #{res.code} #{res.message}" unless res.code == '201'
    }
  end

  # =mkdir=
  # make directory
  #
  # path: remote-server path
  def mkdir(path)
    req = Net::HTTP::Mkcol.new(@basic_path + path)
    res = @http.request(req)
    raise "Invalid HttpResponse Code: #{res.code} #{res.message}" unless res.code == '201'
  end

  # =delete=
  # delete file, delete directory
  #
  # path: remote-server path
  def delete(path)
    req = Net::HTTP::Delete.new(@basic_path + path)
    res = @http.request(req)
    raise "Invalid HttpResponse Code: #{res.code} #{res.message}" unless res.code == '204'
  end

  # =get=
  # get file
  #
  # src_path: remote-server path
  # dest_path: local file path
  def get(src_path, dest_path = nil)
    dest_path = File.basename(src_path) if dest_path.nil?()
    req = Net::HTTP::Get.new(@basic_path + src_path)
    res = @http.request(req)
    raise "Invalid HttpResponse Code: #{res.code} #{res.message}" unless res.code == '200'
    File.open(dest_path, "wb"){|io|
      io.write(res.body)
    }
  end

  # =copy=
  # copy file to file on webdav-server
  #
  # src_path: remote-server source file path
  # dest_path: remote-server destination file path
  def copy(src_path, dest_path)
    req = Net::HTTP::Copy.new(@basic_path + src_path)
    req['Destination'] = @basic_path + dest_path
    res = @http.request(req)
    raise "Invalid HttpResponse Code: #{res.code} #{res.message}" unless res.code == '204'
  end

  # =move=
  # rename file
  #
  # src_path: remote-server source file path
  # dest_path: remote-server destination file path
  def move(src_path, dest_path)
    req = Net::HTTP::Move.new(@basic_path + src_path)
    req['Destination'] = @basic_path + dest_path
    res = @http.request(req)
    raise "Invalid HttpResponse Code: #{res.code} #{res.message}" unless res.code == '204'
  end

  def ls(path)
    prop =<<EOP
<?xml version="1.0" encoding="utf-8" ?>
<D:propfind xmlns:D="DAV:">
  <D:allprop/>
</D:propfind>
EOP
    unless path.empty?
      path += '/' unless path.end_with?('/')
    end

    res = @http.propfind(@basic_path + path, prop, { 'Depth' => '1' })
    raise "Invalid HttpResponse Code: #{res.code} #{res.message}" unless res.code == '207'
    doc = REXML::Document.new res.body
    items = []
    first = true
    doc.elements.each('D:multistatus/D:response') do |elem|
      # 最初のアイテムはリクエストしたディレクトリそのもの
      if first
        first = false
      else
        item = WebdavClient::Item.new(elem, @basic_path)
        unless item.path.empty?
          items << item
        end
      end
    end
    items.sort {|x,y| x.path <=> y.path }
  end
end

if $0 == __FILE__
  w = WebdavClient.new('http://cohi/dav/tmp')
  w.ls('eval/').each do |item|
    puts item
  end
end
