# frozen_string_literal: true

require "test_helper"
require_relative "../lib/string_utils"

class StringUtilsTest < Minitest::Test
  def test_reverse
    assert_equal "olleh", StringUtils.reverse("hello")
  end

  def test_upcase
    assert_equal "HELLO", StringUtils.upcase("hello")
  end
end
