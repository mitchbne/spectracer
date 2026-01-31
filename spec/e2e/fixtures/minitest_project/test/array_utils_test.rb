# frozen_string_literal: true

require "test_helper"
require_relative "../lib/array_utils"

class ArrayUtilsTest < Minitest::Test
  def test_sum
    assert_equal 10, ArrayUtils.sum([1, 2, 3, 4])
  end

  def test_average
    assert_equal 2.5, ArrayUtils.average([1, 2, 3, 4])
  end
end
