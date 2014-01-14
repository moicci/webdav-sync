# webdav-sync

このツールは WebDAV サーバ上のファイルと、ローカルマシンのファイルとを同期するもので、プライベートDropbox的な使い方ができます。

元々このツールは私が音楽ファイルを自宅とオフィスとで共有するために作ったものです。  
自宅PC -- upload --> 会社WebDAVサーバ -- download --> 会社PC という構成で同期しています。

## 準備

まずは WebDAV サーバを用意しましょう。Apache であればよほど古いバージョンのものでない限り標準で WebDAV 機能を持っています。httpd.conf にこんな設定を加えれば OK です。

```
DavLockDB "/usr/local/apache2/logs/DavLock"

Alias "/dav" "/storage/dav"
<Directory "/storage/dav">
    Dav On
    Order Allow,Deny
    Allow from all
</Directory>
```

このホストを仮に webdav.com とすると http://webdav.com/dav で WebDAV にアクセスできます。


## 使い方

clone したディレクトリにある upload.rb/download.rb がそれぞれアップロード、ダウンロードを実行するスクリプトです。

```
Usage: upload [options]
    -v, --verbose                    verbose
    -n, --noexec                     ディレクトリ作成、ファイルアップロード、ダウンロードの実行はしない
    -l, --local dir                  ローカルのトップディレクトリ
    -i, --includes file              対象とする入力元ディレクトリを書いたファイル
    -e, --excludes file              除外する入力元ディレクトリを書いたファイル
    -E, --excludes-to file           成功したディレクトリを出力するファイル
    -r, --retries retries            コピー等のエラー時のリトライ回数
    -d, --newer datetime             指定された日時より新しい物だけを対象とする。
    -s, --script script              ダウンロードされたファイル名を渡すスクリプト
    -u, --url url                    DAVサーバのエンドポイント
```

下記のような構成を考えてみます。

ノード|同期ディレクトリ
---|---
PC-A|/Users/xx/A/
PC-B|/Users/yy/B/

WebDAVサーバのエンドポイント http://webdav.com/dav/

### PC-A -> WebDAV

PC-A からアップロードするときはこれで。

```
ruby upload.rb \
--url=http://webdav.com/dav/ \
--local=/Users/xx/A
```

### WebDAV -> PC-B

PC-B にダウンロードするときはこれで。

```
ruby download.rb \
--url=http://webdav.com/dav/ \
--local=/Users/yy/B
```

PC-A, PC-B はそれぞれアップロード、ダウンロード専用というわけではないので
どちらがアップロードするか分からないけど、常時最新にしたい場合は、それぞれで
upload.rb, download.rb の両方を実行します。

### 同期の対象ファイル

以下のファイルだけがアップロード、ダウンロードの対象となり、他は無視されます。

- アップロードの場合
  - ローカルファイルがDAVサーバに無いとき
  - ローカルファイルとDAVサーバ上のファイルサイズが違うとき

- ダウンロードの場合
  - DAVサーバにあって、ローカルにファイルがないとき
  - DAVサーバ上のファイルとローカルのファイルサイズが違うとき

- 強制的に除外

  - `--excludes` オプションで指定するテキストファイルに、除外するディレクトリ名を列挙できます。

私の場合、このようにして一度アップロードしたディレクトリは二度とチェックしないようにしています。

```
ruby upload.rb --verbose \
--url=http://webdav.com/dav/music/ \
--local=/Users/xxx/Music \
--excludes=excludes.txt \
--excludes-to=excludes.txt
```

### ダウンロード後の処理

私の場合、音楽ファイルの同期に使っているので、ダウンロードしたファイルは iTunes に勝手に登録されて欲しいです。
というわけで、clone したディレクトリにある AppleScript itunes_add.scpt で iTunes に登録しています。  
`--script` で実行スクリプトを指定しており `itunes_add.scpt ファイル名` のように第二引数でファイル名のフルパスがわたされます。

```
ruby download.rb --verbose \
--url=http://webdav.com/dav/music/ \
--local=/Users/xxx/Music \
--script=./itunes_add.script
```

では、お楽しみを。
