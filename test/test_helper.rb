require 'bundler/setup'
require 'mocha'

require 'tmpdir'

class TestHelper < MiniTest::Unit::TestCase
  SAMPLE_REPO = File.dirname(__FILE__) + '/data/sample.tar'

  def self.test(name, &block)
    method = "test_#{name.gsub(/\s+/, '_')}".to_sym
    define_method(method, &block)
  end

  def with_sample_repo
    Dir.mktmpdir do |dir|
      system('tar', '-xf', SAMPLE_REPO, '-C', dir, '--strip-components=1')
      raise 'tar failed' unless $?.success?

      @sample = dir
      yield
    end
  end
end
