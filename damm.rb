#
# Damm Algorithm
#  by H. Michael Damm
#  for detail: http://en.wikipedia.org/wiki/Damm_algorithm
#

module Damm
  D = [
    0, 3, 1, 7, 5, 9, 8, 6, 4, 2,
    7, 0, 9, 2, 1, 5, 4, 8, 6, 3,
    4, 2, 0, 6, 8, 7, 1, 3, 5, 9,
    1, 7, 5, 0, 9, 8, 3, 4, 2, 6,
    6, 1, 2, 3, 0, 4, 5, 9, 7, 8,
    3, 6, 7, 4, 2, 0, 9, 5, 8, 1,
    5, 8, 6, 9, 7, 2, 0, 1, 3, 4,
    8, 9, 4, 5, 3, 6, 2, 0, 1, 7,
    9, 4, 3, 8, 6, 1, 7, 2, 0, 5,
    2, 5, 8, 1, 4, 3, 6, 7, 9, 0,
  ]

  def check(code)
    calc(normalize(code)) == 0
  end

  def generate(code)
    calc(normalize(code))
  end

  private

  def calc(code)
    interim = 0
    code.split(//).map { |i| i.to_i }.each do |i|
      interim = D[i + (interim * 10)];
    end
    interim
  end

  def normalize(code)
    code.to_s.gsub(/[^0-9]/, "")
  end
end

if $0 == __FILE__
  include Damm

  p generate "0123456789"
  p check "01234567894"
  p check "01234567893"
end
