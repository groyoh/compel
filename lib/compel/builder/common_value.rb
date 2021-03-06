module Compel
  module Builder

    module CommonValue

      def in(value, options = {})
        build_option :in, coerce_values_ary!(value, :in), options
      end

      def range(value, options = {})
        build_option :range, coerce_values_ary!(value, :range), options
      end

      def min(value, options = {})
        build_option :min, coerce_value!(value, :min), options
      end

      def max(value, options = {})
        build_option :max, coerce_value!(value, :max), options
      end

      def coerce_values_ary!(values, method)
        begin
          fail if values.nil?

          Coercion.coerce!(values, Coercion::Array)
        rescue
          raise_array_error(method)
        end

        values.map{ |value| Coercion.coerce!(value, self.type) }

        rescue
          raise_array_values_error(method)
      end

      def coerce_value!(value, method)
        begin
          fail if value.nil?

          Coercion.coerce!(value, self.type)
        rescue
          raise_value_error(method)
        end
      end

      def raise_array_error(method)
        raise TypeError, "#{self.class.human_name} ##{method} " \
                         "value must an Array"
      end

      def raise_array_values_error(method)
        raise TypeError, "All #{self.class.human_name} ##{method} values " \
                         "must be a valid #{self.type.human_name}"
      end

      def raise_value_error(method)
        raise TypeError, "#{self.class.human_name} ##{method} value " \
                         "must be a valid #{self.type.human_name}"
      end

    end

  end
end
