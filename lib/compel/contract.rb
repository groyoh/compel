module Compel

  class Contract

    attr_reader :errors

    def initialize(params, &block)
      @errors = Errors.new
      @params = params
      @contract = Hashie::Mash.new

      instance_eval(&block)
    end

    def param(name, type, options = {})
      @contract[name] = Hashie::Mash.new(type: type, options: options)
    end

    def coerce
      @errors.merge Coercion.new(complete_params, @contract).run
      self
    end

    def validate
      @errors.merge Validation.new(complete_params, @contract).run
      self
    end

    def valid?
      @errors.empty?
    end

    private

    def complete_params
      {}.tap do |h|
        @contract.keys.each do |key|
          h[key] = @params[key]
        end
      end
    end

  end

end
