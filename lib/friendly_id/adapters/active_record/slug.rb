# A Slug is a unique, human-friendly identifier for an ActiveRecord.
module FriendlyId
  module Adapters
    module ActiveRecord
      class Slug < ::ActiveRecord::Base

        belongs_to :sluggable, :polymorphic => true
        before_save :set_sequence
        table_name = "slugs"

        class << self

          def parse(friendly_id)
            warn("Slug#parse is deprecated and will be removed in FriendlyId 3.0. Please use FriendlyId.parse_friendly_id.")
            FriendlyId.parse_friendly_id(friendly_id)
          end

          def normalize(slug_text)
            warn("Slug#normalize is deprecated and will be removed in FriendlyId 3.0. Please use SlugString#normalize.")
            raise SlugGenerationError if slug_text.blank?
            SlugString.new(slug_text.to_s).normalize.to_s
          end

          def strip_diacritics(string)
            warn("Slug#strip_diacritics is deprecated and will be removed in FriendlyId 3.0. Please use SlugString#approximate_ascii.")
            raise SlugGenerationError if string.blank?
            SlugString.new(string).approximate_ascii
          end

          def strip_non_ascii(string)
            warn("Slug#strip_non_ascii is deprecated and will be removed in FriendlyId 3.0. Please use SlugString#to_ascii.")
            raise SlugGenerationError if string.blank?
            SlugString.new(string).to_ascii
          end

        end

        # Whether this slug is the most recent of its owner's slugs.
        def is_most_recent?
          sluggable.slug == self
        end

        def to_friendly_id
          sequence > 1 ? "#{name}--#{sequence}" : name
        end

        # Raise a FriendlyId::SlugGenerationError if the slug name is blank.
        def validate #:nodoc:#
          if name.blank?
            raise FriendlyId::SlugGenerationError.new("slug.name can not be blank.")
          end
        end

        private

        def set_sequence
          return unless new_record?
          last = Slug.find(:first, :conditions => { :name => name, :scope => scope,
            :sluggable_type => sluggable_type}, :order => "sequence DESC",
            :select => 'sequence')
          self.sequence = last.sequence + 1 if last
        end
        
      end
    end
  end
end