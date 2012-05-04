require 'minitest/autorun'

require 'test_helper'
require 'heathrow/client'

class ClientTest < TestHelper
  def setup
    @client = Heathrow::Client.new('abc123')
    @store  = Heathrow.store = mock
  end

  test "#<< posts output to store" do
    @store.expects(:rpush).with('client:abc123:output', 'my output')
    @client << 'my output'
  end

  test "#close posts control message to store" do
    @store.expects(:rpush).with('client:abc123:control', 'close')
    @client.close
  end

  test "#read returns output from output queue" do
    @store.expects(:blpop).with('client:abc123:control', 'client:abc123:output', 0).
      returns(['client:abc123:output', 'my output'])
    assert_equal 'my output', @client.read
  end

  test "#read raises EOF on close message" do
    @store.expects(:blpop).with('client:abc123:control', 'client:abc123:output', 0).
      returns(['client:abc123:control', 'close'])
    assert_raise(EOFError) { @client.read }
  end
end
