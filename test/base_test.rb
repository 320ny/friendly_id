require File.expand_path("../helper.rb", __FILE__)

class CoreTest < MiniTest::Unit::TestCase
  include FriendlyId::Test

  test "friendly_id should accept a base and a hash" do
    klass = Class.new(ActiveRecord::Base) do
      extend FriendlyId
      friendly_id :foo, :use => :slugged, :slug_column => :bar
    end
    assert klass < FriendlyId::Slugged
    assert_equal :foo, klass.friendly_id_config.base
    assert_equal :bar, klass.friendly_id_config.slug_column
  end


  test "friendly_id should accept a block" do
    klass = Class.new(ActiveRecord::Base) do
      extend FriendlyId
      friendly_id :foo do |config|
        config.use :slugged
        config.base = :foo
        config.slug_column = :bar
      end
    end
    assert klass < FriendlyId::Slugged
    assert_equal :foo, klass.friendly_id_config.base
    assert_equal :bar, klass.friendly_id_config.slug_column
  end

end