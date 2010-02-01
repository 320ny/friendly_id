require File.dirname(__FILE__) + '/core'
require File.dirname(__FILE__) + '/slugged'

module FriendlyId
  module Test
    module ActiveRecord2
      class BasicSluggedModelTest < ::Test::Unit::TestCase
        include Core
        include Slugged
      end
    end
  end
end
