module Compel
  module Builder

    class String < Schema

      # Taken from ruby_regex gem by @eparreno
      # https://github.com/eparreno/ruby_regex
      URL_REGEX = /(\A\z)|(\A(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?\z)/ix

      # Taken from Michael Hartl's 'The Ruby on Rails Tutorial'
      # https://www.railstutorial.org/book
      EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i

      include CommonValue

      def initialize
        super(Coercion::String)
      end

      def format(regex, options = {})
        build_option :format, Coercion.coerce!(regex, Coercion::Regexp), options
      end

      def url(options = {})
        build_option :format, URL_REGEX, options
      end

      def email(options = {})
        build_option :format, EMAIL_REGEX, options
      end

    end

  end
end
