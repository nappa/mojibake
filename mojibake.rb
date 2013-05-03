#!/usr/bin/env ruby
# -*- coding: utf-8 -*0

require 'uri'
require 'resolv'

require 'rubygems'
require 'bundler'

Bundler.require

=begin
エンコーディングと文字化けに関するメモ。

■基本
 Shift_JIS   : Windows, Mac
 EUC-JP      : Unix
 ISO-2022-JP : 電子メール
 UTF-8       : いろいろ

■ISO-2022-JP のバリエーション
 ISO-2022-JP-2 : Mac の Mail.app が使用。

■Shift_JIS のバリエーション
 Windows-31J : Windows, NEC 拡張。例: 「①」
 macJapanese : Mac OS 向け拡張。例: 「♡」

■UTF-8のバリエーション
 UTF8-MAC    : Mac OS X のファイルシステム
 http://macwiki.sourceforge.jp/wiki/index.php/UTF-8-MAC

■各携帯キャリアの絵文字拡張
 UTF8-KDDI
 SJIS-KDDI
 UTF8-SoftBank
 SJIS-SoftBank
 UTF8-DoCoMo
 SJIS-DoCoMo
=end

#
# UTF-8 で表現された文字列を任意のエンコードに変換して
# 再度 UTF-8 に書き戻し、比較する。
#
def test_encode(string, encoding)
  before_string = string

  begin
    encoded_string = before_string.encode(encoding)
  rescue Encoding::UndefinedConversionError, Encoding::ConverterNotFoundError => e
    puts "NG: '#{string}' => '#{encoding}' (#{e.message})"
    return
  end

  begin
    after_string = encoded_string.encode('UTF-8')
  rescue Encoding::UndefinedConversionError, Encoding::ConverterNotFoundError => e
    puts "NG: '#{string}'(in #{encoding}) => UTF-8 (#{e.message})"
    return
  end

  if before_string == after_string
    puts "#{before_string} == #{after_string} (#{encoding})"
  else
    puts "#{before_string} != #{after_string} (#{encoding})"
  end
end

def test_encode_all(string)
  ['ISO-2022-JP', 'EUC-JP', 'Shift_JIS', 'Windows-31J', 'UTF-8'].each do |code|
    test_encode(string, code)
  end
end

# (1) NEC 特殊文字, IBM 拡張文字, NEC選定IBM拡張文字 の記号類 (Windows-31J 以外 x)
#  - 入力禁止にすべき
test_encode_all("①")
test_encode_all("㍻")
test_encode_all("㈱")
test_encode_all("ⅰ")
test_encode_all("髙")
test_encode_all("﨑")

# (2) ハート (MacJapanese 以外 x)
#  - 入力禁止にすべき
test_encode_all("♡")

# (3) 半角記号・カナ (ISO-2022-JP で x)
#  - 入力禁止にすべき
%w(･ ? ! \\ ｡ ｢ ｣ ､ ﾗ ﾟ).each do |char|
  test_encode_all(char)
end

# (4) WAVE DASH (波ダッシュ) (Windows-31J で x)
#  - 入力禁止にすると、よく使う文字なので困る。
#    export 時に export 先に応じて \uff5e に変換してあげる
test_encode_all("\u301c")

# (5) FULL WIDTh TILDE (全角チルダ) (ISO-2022-JP, EUC-JP, Shift_JIS で x)
#  - (4) と同じ。
test_encode_all("\uff5e")

# (6) 草なぎ剛 (Shift_JIS にない)
test_encode_all("彅")

# (7) 左右反転
test_encode_all("abc\u202eabc")

##
## これらに対してどうするか?
##

# 対処(1) 入力禁止にしても差し支えない文字は拒否する
# ※このままだと波ダッシュ(後述)が入力できなくなるので変更が必要
def mojibake_safe?(string)
  begin
    string.encode("ISO-2022-JP")
    string.encode("Shift_JIS")
    string.encode("EUC-JP")
  rescue => e
    return false
  end

  return true
end

# 対処(2) 正規化。
#
# 半角カタカナを全角へ。
# 全角英語字・記号を半角へ。
# 全角・半角の区別はユーザに極力させずに済むにようにしてあげると、使いやすいサイトになる。
#
# moji というツールが便利。http://gimite.net/gimite/rubymess/moji.html
puts Moji.zen_to_han("ＡＢＣＤＥ")       #=> "ABCDE"
puts Moji.zen_to_han("１２３ー４５６７") #=> "123-4567"
puts Moji.han_to_zen("ｷﾚｲﾀﾞﾖ ｷﾓﾁｲｲﾖ").tr("　", " ") #=> "キレイダヨ キモチイイヨ"
puts Moji.normalize_zen_han("ﾐｸｻｰﾝ")

# 対処(2) 強制変換。波ダッシュ・全角チルダ問題。
#
#
# 「～」U+301C = U+FF5E
# 「∥」U+2016 = U+2225
# 「－」U+2212 = U+FF0D
# 「￠」U+00A2 = U+FFE0
# 「￡」U+00A3 = U+FFE1
# 「￢」U+00AC = U+FFE2
#
# 入力段・出力段で変換する。
def normalize_windows_31j_specialchar(string)
  string.tr("\uff5e", "\u301c",)
        .tr("\u2225", "\u2016",)
        .tr("\uff0d", "\u2212",)
        .tr("\uffe0", "\u00a2",)
        .tr("\uffe1", "\u00a3",)
        .tr("\uffe2", "\u00ac",)
end
puts normalize_windows_31j_specialchar("\uff5e") #=> 〜 (波ダッシュ)

def denormalize_windows_31j_specialchar(string)
  string.tr("\u301c", "\uff5e")
        .tr("\u2016", "^u2225")
        .tr("\u2212", "\uff0d")
        .tr("\u00a2", "\uffe0")
        .tr("\u00a3", "\uffe1")
        .tr("\u00ac", "\uffe2")
end
puts denormalize_windows_31j_specialchar("〜") #=> \uff5e (全角チルダ)

=begin

ここからは文字化けと関係ない(少しあるけど)、趣味的な話。

年配の方のPCの使い方を観察する機会があったので
小一時間観察していたことがある。

そこからわかったこと。

1. 全角/半角の概念がわからない
   (ワープロの経験がある人でないとつらい)

2. IME が ON か OFF かを意識することができない。
   どれだけ熟達しても、何度も間違える。

3. 入力エラーが出たら、とにかく当てずっぽうに試し始める。
   全角で入力してみたり、半角で入力してみたり。

4. 今入力した文字が、半角文字か全角文字かが目で見てもわからない。
   眼鏡をはずして、ぐっとディスプレイに目を近づけて、やっと区別できる。

5. 4. のとき、往々にしてスペースバーや変換・無変換キーに触れてしまう。

6. 文字化けを起こしやすい文字、というのがわからない。
   丸付き文字や、はしご高などが危険だという認識がない。

7. しょうもない入力ミスでも気づかない。"http" を "htp" にしてしまっても
   どこがおかしいのかまったく分からないし、間違っている箇所をみつけられない。

……とにかく若い人が想像しているよりもずっと難しいことがわかった。
PC に限らずタブレット端末でも状況は変わらないらしい。

というわけで、こんなふうに設計するのがやさしいと思った。

1. 全角半角、どちらでも極力受け付ける。
   郵便番号・電話番号など、どちらでも差し支えない場合はどちらでも
   受け付けたあとどちらか一方に寄せる。

2. 誤入力されたスペースは取り除いてあげる

3. 文字化けを起こす可能性のある文字は、必要に応じて
   警告する。または入力を受け付けないようにする。

4. 極力賢くバリデーションする。間違いの検出率をできるだけ高くする。
   メールアドレスであれば
     * DNSレコード (MX, A) の存在の確認
     * メールサーバに実際に接続できることの確認。
     * 可能であればVRFYやEXPNコマンドを使ってユーザの存在を確認
       (※実装によってはVRFYを数回叩くだけで Reject するようなハリネズミ的なものがありそうなので注意)
   WebサイトのURLであれば
     * プロトコル部が http か https であることの確認
     * DNSレコード (MX, A) の存在の確認
     * Webサーバに実際に接続できることの確認
     * コンテンツが存在することの確認 (404, 403 などが返ってこないことの確認)

   郵便番号であれば、実際に存在する番号であることの確認。
   都道府県・市区町村・町域など、郵便番号から入力できる部分は
   入力させない(郵便番号からの補完を必須にする)といいと思う。

   電話番号であれば総務省の資料と照合して、
     * 先頭が 00 でないことの確認
     * 先頭が 1 でないことの確認
     * 先頭が 070, 080, 090 のとき、次の4桁が割当済であるとの確認
     * 先頭が特殊な番号 (0120, 0570, 0990, など) でないことの確認
     * 固定電話の番号のとき、住所と、総務省の資料とを照らし合わせて
       実際に存在する市内局番・市外局番であることを確認
     * Twilio で実際にコールして、通信可能な番号であることの確認
   まで……誰かやってみてほしい。正直めんどくさい。
=end

module JapaneseCharNormalizer
  def normalize_phone_number(string)
    Moji.zen_to_han(string.strip).gsub(/[\W\-\_]/, "")
  end

  def normalize_fax_number(string)
    normalize_phone_number(string)
  end

  def normalize_postcode(string)
    Moji.zen_to_han(string.strip).gsub(/[\W\-\_]/, "")
  end

  def normalize_name(string)
    Moji.normalize_zen_han(string.strip)
  end

  def normalize_prefecture(string)
    string.strip
  end

  def normalize_address(string)
    Moji.normalize_zen_han(string.strip)
  end

  def normalize_email_address(string)
    Moji.normalize_zen_han(string.strip)
  end

  def normalize_website_url(string)
    string.strip
  end

  def normalize_windows_31j_specialchar(string)
    string.tr("\uff5e", "\u301c",)
          .tr("\u2225", "\u2016",)
          .tr("\uff0d", "\u2212",)
          .tr("\uffe0", "\u00a2",)
          .tr("\uffe1", "\u00a3",)
          .tr("\uffe2", "\u00ac",)
  end

  def denormalize_windows_31j_specialchar(string)
    string.tr("\u301c", "\uff5e")
          .tr("\u2016", "^u2225")
          .tr("\u2212", "\uff0d")
          .tr("\u00a2", "\uffe0")
          .tr("\u00a3", "\uffe1")
          .tr("\u00ac", "\uffe2")
  end
end


# 実装のサンプル。
module JapaneseCharValidator
  include JapaneseCharNormalizer

  # 名前の入力チェック
  def valid_name?(string)
    normalized = normalize_name(string)
    return mojibake_safe?(normalized)
  end

  # 電話番号の入力チェック
  def valid_phone_number?(string)
    normalized = normalize_phone_number(string)

    return normalized =~ /\A0[1-9][0-9]{8,9}\z/
  end

  # FAX番号の入力チェック
  def valid_fax_number?(string)
    valid_phone_number?(string)
  end

  # 郵便番号の入力チェック
  def valid_postcode?(string)
    normalized = normalize_postcode(string)

    return normalized =~ /\A[0-9]{7}\z/
  end

  Prefectures = %w(北海道 青森県 岩手県 宮城県 秋田県 山形県 福島県 茨城県 栃木県 群馬県 埼玉県 千葉県 東京都 神奈川県 新潟県 富山県 石川県 福井県 山梨県 長野県 岐阜県 静岡県 愛知県 三重県 滋賀県 京都府 大阪府 兵庫県 奈良県 和歌山県 鳥取県 島根県 岡山県 広島県 山口県 徳島県 香川県 愛媛県 高知県 福岡県 佐賀県 長崎県 熊本県 大分県 宮崎県 鹿児島県 沖縄県)
  # 都道府県の入力チェック
  def valid_prefecture?(string)
    Prefectures.include?(normalize_prefecture(string))
  end

  # 住所の入力チェック
  def valid_address?(string)
    # 住所にキリル文字は出てこないでしょ、普通(ギリシャ文字はあり得るけど)
    self.mojibake_safe?(normalize_address(string)) &&
      Moji::ZEN_CYRILLIC !~ /string/
  end

  # メールアドレスの入力チェック
  # BUG: 日本語ドメインが true にならない
  # BUG: hoge..hoge@example.com が true になってしまう
  # BUG: hoge.@example.com が true になってしまう
  def valid_email_address?(string, exist_check=false)
    normalized = normalize_email_address(string)

    # "hogehoge@example.com (名前)" 形式を排除する
    if normalized.include?(" ")
      return false
    end

    if normalized =~ /@docomo.ne.jp\z/ ||
        normalized =~ /@ezweb.ne.jp\z/
      # ドコモは連続するドット、先頭・末尾のドットも許されてしまう。
      # 特例でドットを "x" で置換して以降のチェックを通過できるようにする
      addr, domain = normalized.split("@")[0..1]
      normalized = addr.tr(".", "x") + "@" + domain
    end

    begin
      addr = Mail::Address.new(normalized)

      # mail gem のチェックでは、TLD ("com" など)
      # も正しいドメインになってしまうので別途チェック
      if addr.domain.split(".").length < 2
        return false
      end
    rescue Mail::Field::ParseError => e
      return false
    end

    if exist_check
      # MXレコードの存在チェック
      mx = Resolv::DNS.new.getresources(addr.domain, Resolv::DNS::Resource::IN::MX)
      return false if mx.empty?
      # 続いてAレコードの存在チェック
      a = Resolv::DNS.new.getresources(mx[0].exchange.to_s, Resolv::DNS::Resource::IN::A)
      return false if a.empty?

      # TODO: VRFY や EXPN してアドレスの存在を確認してみる。サーバ側から拒否されたらあきらめる
    end

    true
  end

  # WebサイトURLの入力チェック
  # BUG: 日本語ドメイン名が通らない
  def valid_website_url?(string, exist_check=false)
    normalized = normalize_website_url(string)

    uri = nil
    begin
      uri = URI.parse(normalized)
    rescue URI::InvalidURIError
      return false
    end

    if uri.host.blank? || uri.host.split(".").length < 2
      return false
    end

    unless %w(http https).include?(uri.scheme)
      return false
    end

    # ポート番号を変えてWebサーバをさらしてる人は
    # 見てもらう気がないんだと思う。
    if uri.scheme == "http" && uri.port != 80
      return false
    end
    if uri.scheme == "https" && uri.port != 443
      return false
    end

    # ウイルスかもしれないので却下
    if uri =~ /\.(com|bat|exe|js|vbs|cmd|jse|wsf|wsh)\z/
      return false
    end

    # 実在性チェック (ホスト名のみ)
    if exist_check
      ipv4 = Resolv::DNS.new.getresources(uri.host, Resolv::DNS::Resource::IN::A)
      ipv6 = Resolv::DNS.new.getresources(uri.host, Resolv::DNS::Resource::IN::AAAA)
      if (ipv4 + ipv6).empty?
        return false
      end
    end

    true
  end

  # Twitter ID の入力チェック
  def valid_twitter_id?(string)
    return string =~ /\A[a-zA-Z0-9_]+\z/
  end

  def mojibake_safe?(string)
    shift_jis_safe?(string) && windows_31j_safe?(string) &&
      euc_jp_safe?(string) && iso_2022_jp_safe?(string)
  end

  def shift_jis_safe?(string)
    string = normalize_windows_31j_specialchar(string)
    begin
      string.encode("Shift_JIS")
    rescue
      return false
    end

    true
  end

  def windows_31j_safe?(string)
    string = denormalize_windows_31j_specialchar(string)
    begin
      string.encode("Windows-31J")
    rescue
      return false
    end

    true
  end

  def euc_jp_safe?(string)
    string = normalize_windows_31j_specialchar(string)
    begin
      string.encode("EUC-JP")
    rescue
      return false
    end

    true
  end

  def iso_2022_jp_safe?(string)
    string = normalize_windows_31j_specialchar(string)
    begin
      string.encode("ISO-2022-JP")
    rescue
      return false
    end

    true
  end
end

class JapaneseCharValidatorTest < Test::Unit::TestCase
  include JapaneseCharValidator
  def test_ok_name
    assert(valid_name?(""))
    assert(valid_name?(" 佐藤 "))
    assert(valid_name?("Charles"))
    assert(valid_name?("ベートーヴェン〜"))
    assert(valid_name?("ﾍﾞｰﾄｰｳﾞｪﾝ"))
  end

  def test_bad_name
    assert(! valid_name?("①"))
    assert(! valid_name?("草彅"))
  end

  def test_ok_email_address
    assert(valid_email_address?("a@example.com"))
    assert(valid_email_address?(" a@example.com "))
    assert(valid_email_address?(".damedame@docomo.ne.jp"))
    assert(valid_email_address?("dame..dame@docomo.ne.jp"))
    assert(valid_email_address?("damedame.@docomo.ne.jp"))
    assert(valid_email_address?(" a＠ＥＸample.com "))
    assert(valid_email_address?("a@nic.ad.jp", true))
    #assert(valid_email_address?("a@日本語ドメイン.com"))
  end

  def test_bad_email_address
    assert(! valid_email_address?("a@.com"))
    assert(! valid_email_address?("a@example.jp", true))
    #assert(! valid_email_address?("damedame.@example.com"))
    #assert(! valid_email_address?("dame..dame@example.com"))
  end

  def test_ok_prefecture
    assert(valid_prefecture?("東京都"))
  end

  def test_bad_prefecture
    assert(! valid_prefecture?(""))
    assert(! valid_prefecture?("グンマー県"))
  end

  def test_ok_postcode
    assert(valid_postcode?("111-1111"))
    assert(valid_postcode?(" 1111111"))
    assert(valid_postcode?("1111111 "))
    assert(valid_postcode?("１１１ー１１１１ "))
  end

  def test_bad_postcode
    assert(! valid_postcode?(""))
    assert(! valid_postcode?("abc"))
  end

  def test_ok_phone_number
    assert(valid_phone_number?("03-0000-0000"))
    assert(valid_phone_number?("0300000000"))
    assert(valid_phone_number?("0300000000 "))
    assert(valid_phone_number?(" 0300000000"))
    assert(valid_phone_number?("030000 0000"))
    assert(valid_phone_number?("０３−００００００００"))
    assert(valid_phone_number?("09000000000"))
  end

  def test_bad_phone_number
    assert(! valid_phone_number?(""))
    assert(! valid_phone_number?("abc"))
    assert(! valid_phone_number?("001-81-03-0000"))
    assert(! valid_phone_number?("119"))
  end

  def test_ok_fax_number
    assert(valid_fax_number?("03-0000-0000"))
  end

  def test_bad_fax_number
    assert(! valid_fax_number?("abc"))
  end

  def test_ok_website_address
    assert(valid_website_url?("https://example.com/"))
    assert(valid_website_url?("http://example.com/"))
    assert(valid_website_url?("http://example.com/hogehogehoge/guhaguha/abeshi"))
    assert(valid_website_url?("https://example.com:443/"))
    assert(valid_website_url?("http://example.com:80/"))
    assert(valid_website_url?("http://www.nic.ad.jp/", true))

    # BUG
    #assert(valid_website_url?("https://日本語ドメイン/"))
  end

  def test_bad_website_address
    assert(! valid_website_url?("ftp://example.com/"))
    assert(! valid_website_url?("//example.com/"))
    assert(! valid_website_url?("example.com"))
    assert(! valid_website_url?("http://com/"))
    assert(! valid_website_url?("http://example.com:81/"))
    assert(! valid_website_url?("https://example.com:80/"))
    assert(! valid_website_url?("http://example.jp/", true))
  end

  def test_ok_twitter_id
    assert(valid_twitter_id?("hogehoge"))
    assert(valid_twitter_id?("a123"))
    assert(valid_twitter_id?("_a123"))
    assert(valid_twitter_id?("a123_"))
    assert(valid_twitter_id?("123"))
  end

  def test_bad_twitter_id
    assert(! valid_twitter_id?(""))
    assert(! valid_twitter_id?("-hoge"))
    assert(! valid_twitter_id?("あああ"))
  end
end
