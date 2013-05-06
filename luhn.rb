#
# Luhn algorithm checker example
#
# Luhn algorithm
#   by Hans Peter Luhn (IBM)
#   U.S.Patenet No. 2,950,048 (expired)
#   ISO/IEC 7812-1
#   for detail: http://en.wikipedia.org/wiki/Luhn_algorithm
#
module Luhn
  def generate(code)
    sum = sum_for_generate(normalize(code))
    return (10 - sum % 10)
  end

  def check(code)
    sum = sum_for_check(normalize(code))
    sum % 10 == 0
  end

  private

  def normalize(code)
    code.to_s.gsub(/[^0-9]/, "")
  end

  def sum_for_generate(c)
    sum_code(c, true)
  end

  def sum_for_check(c)
    sum_code(c, false)
  end

  def sum_code(c, even=false)

    c.split(//).reverse.map { |i| i.to_i }.inject(0) do |sum, i|
      i *= 2 if even

      if i >= 10
        i = i.to_s.split(//).inject(0) { |s, i|
                                s += i.to_i
                              }
      end

      even = !even

      sum += i
    end
  end
end

if $0 == __FILE__
  include Luhn

  #
  # generate check digit by luhn algorithm
  #
  %w(
    4111-1111-1111-111
    5500-0000-0000-000
    3088-0000-0000-000
    1111-1111-1111-111
  ).each do |code|
    check_digit = generate(code).to_s
    puts "#{code} : check digit is #{check_digit}"
  end

  #
  # verity by luhn algorithm
  #
  %w(
    4111-1111-1111-1111
    5500-0000-0000-0004
    3088-0000-0000-0009
    1111-1111-1111-1112
    1111-1111-1111-1117
  ).each do |code|
    if check(code)
      puts "OK: #{code}"
    else
      puts "NG: #{code}"
    end
  end

  # luhn algorithm can't detect these wrong number sequence
  [
    # 09 -> 90
    "3088-0000-0000-0009",
    "3088-0000-0000-0090",
    # 22 -> 55
    "3088-0000-0000-0223",
    "3088-0000-0000-0553",
  ].each do |code|
    puts "#{code}: #{check(code)}"
  end  
end
