module FriendlyId
  module Adapters
    module ActiveRecord
      
      module SimpleModel
        
        class Finder < FriendlyId::Finder
          
          def column
            "#{table_name}.#{friendly_id_config.method}"
          end
          
          def primary_key
            "#{quoted_table_name}.#{model.send :primary_key}"
          end
          
        end
        
        class MultipleFinder < Finder
          
          attr_reader :friendly_ids, :results, :unfriendly_ids
          
          def initialize(ids, model, options={})
            @friendly_ids, @unfriendly_ids = ids.partition {|id| self.class.friendly?(id) && id.to_s }
            super
          end
          
          def error_message
            "Couldn't find all %s with IDs (%s) AND %s (found %d results, but was looking for %d)" % [
              model.name.pluralize,
              ids * ', ',
              sanitize_sql(options[:conditions]),
              results.size,
              expected_size
            ]
          end
          
          def find
            @results = with_scope(:find => options) { all(:conditions => conditions) }
            raise(::ActiveRecord::RecordNotFound, error_message) if @results.size != expected_size
            friendly_results.each { |result| result.friendly_id_status.name = result.friendly_id }
            @results
          end
          
          def friendly_results
            results.select { |result| friendly_ids.include? result.friendly_id.to_s }
          end
          
          def conditions
            ["#{primary_key} IN (?) OR #{column} IN (?)", unfriendly_ids, friendly_ids]
          end
          
        end
        
        class SingleFinder < Finder

          def find
            result = with_scope(:find => find_options) { find_initial options }
            raise ::ActiveRecord::RecordNotFound.new if !result
            result.friendly_id_status.name = id
            result
          end

          def find_options
            {:conditions => {column => id}}
          end

        end

        class Status < FriendlyId::Status
          # Did the find operation use a friendly id?
          def friendly?
            !! name
          end
          alias :best? :friendly?
        end
        
        module Finders
          def find_one(id, options)
            finder = SingleFinder.new(id, self, options)
            finder.unfriendly? ? super : finder.find
          end
        
          def find_some(ids_and_names, options)
            MultipleFinder.new(ids_and_names, self, options).find
          end
          protected :find_one, :find_some
        end

        def self.included(base)
          base.validate :validate_friendly_id
          base.extend Finders
        end

        def friendly_id_status
          @friendly_id_status ||= Status.new(:model => self)
        end

        # Was the record found using one of its friendly ids?
        def found_using_friendly_id?
          friendly_id_status.friendly?
        end

        # Was the record found using its numeric id?
        def found_using_numeric_id?
          friendly_id_status.numeric?
        end
        alias has_better_id? found_using_numeric_id?

        # Returns the friendly_id.
        def friendly_id
          send friendly_id_config.method
        end
        alias best_id friendly_id

        # Returns the friendly id, or if none is available, the numeric id.
        def to_param
          (friendly_id || id).to_s
        end

        private

        def validate_friendly_id
          if result = friendly_id_config.reserved_error_message(friendly_id)
            self.errors.add(*result)
            return false
          end
        end

      end
    end
  end
end