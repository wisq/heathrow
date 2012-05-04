require 'minitest/autorun'

require 'test_helper'
require 'heathrow/client'

class ClientIntegrationTest < TestHelper
  def setup
    Heathrow.store = store = Redis.new(:db => 13)
    store.flushdb

    @client = Heathrow::Client.new('user1')
  end

  test "client can fetch output" do
    @client << "some output"
    assert_equal "some output", @client.read_nonblock

    @client << "more output"
    @client << "even more output"
    assert_equal "more output", @client.read
    assert_equal "even more output", @client.read
  end

  test "client can wait for output" do
    pid = fork do
      Heathrow.store.client.reconnect
      sleep 0.2
      @client << "some output"
      sleep 0.2
      @client << "more output"
      @client << "even more output"
    end

    assert_equal nil, @client.read_nonblock
    assert_equal "some output", @client.read
    assert_equal nil, @client.read_nonblock
    assert_equal "more output", @client.read
    assert_equal "even more output", @client.read
    Process.wait(pid)
  end
end
