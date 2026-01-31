# frozen_string_literal: true

class ArrayUtils
  def self.sum(arr)
    arr.sum
  end

  def self.average(arr)
    return 0 if arr.empty?
    arr.sum.to_f / arr.size
  end
end
