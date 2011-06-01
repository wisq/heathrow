class TestHelper < MiniTest::Unit::TestCase
  def self.test(name, &block)
    method = "test_#{name.gsub(/\s+/, '_')}".to_sym
    define_method(method, &block)
  end
end
