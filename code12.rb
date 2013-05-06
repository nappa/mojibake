# -*- coding: utf-8 -*-

# ヤマト運輸、佐川急便、ゆうパックののコードチェック
module Code12
  def generate(code)
    mod = code.to_i % 7
    return code.to_s + mod.to_s
  end

  def check(code_with_check_digit)
    code = code_with_check_digit[0..-2]
    check_digit = code_with_check_digit[-1..-1]

    mod = code.to_i % 7
    return mod == check_digit.to_i
  end
end

if $0 == __FILE__
  include Code12

  %w(
   12345678901
   11111111111
  ).each do |code|
    puts "code: #{code} => check digit: #{generate(code)}"
  end

  %w(
   123456789013
   111111111111
  ).each do |code|
    valid_check_digit = generate(code[0..-2])[-1..-1]

    if check(code)
      puts "OK: #{code}"
    else
      puts "NG: #{code} (check digit should be #{valid_check_digit})"
    end
  end
end
