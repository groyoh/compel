require 'pry'

module Compel

  class Contract

    attr_reader :errors,
                :conditions,
                :serialized_errors

    def initialize(params, &block)
      if params.nil? || !Coercion.valid?(params, Hash)
        raise ParamTypeError, 'params must be an Hash'
      end

      @errors = Errors.new
      @params = Hashie::Mash.new(params)
      @conditions = Hashie::Mash.new
      @coerced_params = Hashie::Mash.new

      instance_eval(&block)
    end

    def validate
      @conditions.values.each do |param|
        begin
          # If it is an Hash and it was given conditions for that Hash,
          # build a new Compel::Contract form inner conditions
          if (param.hash? && param.conditions?)

            # If this param is required, a value must be given to build the Compel::Contract
            # otherwise, only build it if is given a value for the param
            if (param.required? && !param.value.nil?) || !param.value.nil?
              contract = Contract.new(param.value, &param.conditions).validate

              @errors.add(param.name, contract.errors)

              # Update the param value with coerced values to use later
              # when coercing param parent
              @coerced_params[param.name] = contract.coerced_params
            end
          end

          # All values must coerce before going through validation,
          # raise exception to avoid validation

          # If the param value has already been coerced from digging into child Hash
          # use that value instead, so we don't lose the previous coerced values
          coerced_value = Coercion.coerce! \
            (@coerced_params[param.name].nil? ? param.value : @coerced_params[param.name]), param.type, param.options

          # Only add to coerced values if not nil
          if !coerced_value.nil?
            @coerced_params[param.name] = coerced_value
          end

          @errors.add \
            param.name, Validation.validate(param.value, param.options)

        rescue Compel::ParamTypeError => exception
          @errors.add(param.name, exception.message)
        end
      end

      self
    end

    def param(name, type, options = {}, &block)
      @conditions[name] = \
        Param.new(name, type, @params.delete(name), options, &block)
    end

    def coerced_params
      # @params has all params that are not affected by the validation
      @params.merge(@coerced_params)
    end

    def serialize
      coerced_params.tap do |hash|
        if !valid?
          hash[:errors] = serialized_errors
        end
      end
    end

    def valid?
      @errors.empty?
    end

    def serialized_errors
      @errors.to_hash
    end

    def raise?
      if !valid?
        exception = InvalidParamsError.new
        exception.params = coerced_params
        exception.errors = serialized_errors

        raise exception, 'params are invalid'
      end

      coerced_params
    end

  end

end
