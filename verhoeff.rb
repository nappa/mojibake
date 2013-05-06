#
# Verhoeff Algorithm sample implementation
#
module Verhoeff
  D = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    [1, 2, 3, 4, 0, 6, 7, 8, 9, 5],
    [2, 3, 4, 0, 1, 7, 8, 9, 5, 6],
    [3, 4, 0, 1, 2, 8, 9, 5, 6, 7],
    [4, 0, 1, 2, 3, 9, 5, 6, 7, 8],
    [5, 9, 8, 7, 6, 0, 4, 3, 2, 1],
    [6, 5, 9, 8, 7, 1, 0, 4, 3, 2],
    [7, 6, 5, 9, 8, 2, 1, 0, 4, 3],
    [8, 7, 6, 5, 9, 3, 2, 1, 0, 4],
    [9, 8, 7, 6, 5, 4, 3, 2, 1, 0],
  ]

  P = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    [1, 5, 7, 6, 2, 8, 3, 0, 9, 4],
    [5, 8, 0, 3, 7, 9, 6, 1, 4, 2],
    [8, 9, 1, 6, 0, 4, 3, 5, 2, 7],
    [9, 4, 5, 3, 1, 2, 6, 8, 7, 0],
    [4, 2, 8, 6, 5, 7, 3, 9, 0, 1],
    [2, 7, 9, 3, 8, 0, 6, 4, 1, 5],
    [7, 0, 4, 6, 9, 1, 3, 2, 5, 8],
  ]

  J = [0, 4, 3, 2, 1, 5, 6, 7, 8, 9]

  def generate(code)
    normalized = normalize(code)

    normalized + sum(normalized).to_s
  end

  def check(code)
    sum(normalize(code)[0..-2]) == code.to_i % 10
  end

  private

  def normalize(code)
    code.to_s.gsub(/[^0-9]/, "")
  end

  def sum(code)
    J[normalize(code).split(//).map { |i|
      i.to_i
    }.reverse.each_with_index.inject(0) { |c, (v, i)|
      D[c][P[(i+1) % 8][v]]
    }]
  end
end


if $0 == __FILE__
  include Verhoeff
  p generate("123456789")
  p check("1234567890")
end
