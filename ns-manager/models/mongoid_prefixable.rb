module Mongoid

  module PrefixableDocument
    def self.included(base)
      base.class_eval do

        @@wrapped_stack = []
        @@wrapped_class = base

        def self.prefix(_prefix=nil)
          @@wrapped_class.clone.tap do |wrapper_klass|
            wrapper_klass.class_eval do

              @@wrapped_prefix = _prefix

              include Mongoid::Document

              def self.inspect
                "#<#{@@wrapped_class.name} _prefix: #{@@wrapped_prefix||'none'}>"
              end

              def prefixed_inspect(inspection)
                "#<#{@@wrapped_class.name} _prefix: #{@@wrapped_prefix||'none'}, _id: #{id}, #{inspection * ', '}>"
              end

            end

            #wrapper_klass.store_in([_prefix,@@wrapped_class.name.pluralize.downcase].compact.join("_"))
            wrapper_klass.store_in(collection: [@@wrapped_class.name.downcase, _prefix].compact.join("."))

            @@wrapped_stack.each{ |m,a| wrapper_klass.send(m,*a) }

          end
        end

        def self.method_missing(_method, *args)
          if @@wrapped_stack.frozen?
            self.prefix.send(_method, *args)
          else
            @@wrapped_stack << [_method, args]
          end
        end

        def self.freeze_stack!
          @@wrapped_stack.freeze
        end

      end
    end
  end

  module Inspection

      def inspect
        inspection = []
        inspection.concat(inspect_fields).concat(inspect_dynamic_fields)
        return prefixed_inspect(inspection) if respond_to?(:prefixed_inspect)
        "#<#{self.class.name} _id: #{id}, #{inspection * ', '}>"
      end

  end

end
