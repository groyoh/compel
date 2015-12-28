Compel
==========================
![](https://travis-ci.org/joaquimadraz/compel.svg)
[![Code Climate](https://codeclimate.com/github/joaquimadraz/compel/badges/gpa.svg)](https://codeclimate.com/github/joaquimadraz/compel)
[![Test Coverage](https://codeclimate.com/github/joaquimadraz/compel/badges/coverage.svg)](https://codeclimate.com/github/joaquimadraz/compel/coverage)

Ruby Hash Coercion and Validation

This is a straight forward way to validate a Ruby Hash: just give an object and the schema.

The motivation was to create an integration for [RestMyCase](https://github.com/goncalvesjoao/rest_my_case) and have validations before any business logic execution.

Based on the same principle from [Grape](https://github.com/ruby-grape/grape) framework and [sinatra-param](https://github.com/mattt/sinatra-param) gem to validate request params. The schema builder is based on [Joi](https://github.com/hapijs/joi).

### Example

```ruby
object = {
  first_name: 'Joaquim',
  birth_date: '1989-0',
  address: {
    line_one: 'Lisboa',
    post_code: '1100',
    country_code: 'PT'
  }
}

schema = Compel.hash.keys({
  first_name: Compel.string.required,
  last_name: Compel.string.required,
  birth_date: Compel.datetime,
  address: Compel.hash.keys({
    line_one: Compel.string.required,
    line_two: Compel.string.default('-'),
    post_code: Compel.string.format(/^\d{4}-\d{3}$/).required,
    country_code: Compel.string.in(['PT', 'GB']).default('PT')
  })
})

Compel.run(object, schema)
```

Will return an [Hashie::Mash](https://github.com/intridea/hashie) object:

```ruby
{
  "first_name" => "Joaquim",
  "birth_date" => "1989-0",
  "address" => {
    "line_one" => "Lisboa",
    "line_two" => "-",
    "post_code" => "1100",
    "country_code" => "PT"
  },
  "errors" => {
    "last_name" => ["is required"],
    "birth_date" => ["'1989-0' is not a parsable date with format: %Y-%m-%d"],
    "address" => {
      "post_code" => ["must match format ^\d{4}-\d{3}$"]
    }
  }
}
```

There are 3 ways to run validations:

Method  | Behaviour
------------- | -------------
`#run`  | Validates and returns an Hash with coerced params plus a `:errors` key with a _Rails like_ Hash of errors if any.
`#run!` | Validates and raises `Compel::InvalidHashError` exception with the coerced params and errors.
`#run?` | Validates and returns true or false.

### Types

- `#integer`
- `#float`
- `#string`
- `#json`
  - ex: `"{\"a\":1,\"b\":2,\"c\":3}"`
- `#hash`
  - ex: `{ a: 1,  b: 2, c: 3 }`
- `#date`
- `#time`
- `#datetime`
- `#boolean`,
  - ex: `1`/`0`, `true`/`false`, `t`/`f`, `yes`/`no`, `y`/`n`

### Sinatra Integration

If you want to use with `Sinatra`, here's an example:

```ruby
class App < Sinatra::Base

  set :show_exceptions, false
  set :raise_errors, true

  before do
    content_type :json
  end

  helpers do

    def compel(schema)
      params.merge! Compel.run!(params, Compel.hash.keys(schema))
    end

  end

  error Compel::InvalidHashError do |exception|
    status 400
    { errors: exception.errors }.to_json
  end

  configure :development do
    set :show_exceptions, false
    set :raise_errors, true
  end

  post '/api/posts' do
    compel({
      post: Compel.hash.keys({
        title: Compel.string.required,
        body: Compel.string,
        published: Compel.boolean.default(false)
      }).required
    })

    params.to_json
  end

end
```
###Installation

Add this line to your application's Gemfile:

    gem 'compel', '~> 0.2.0'

And then execute:

    $ bundle

### TODO

- Write more Documentation (check specs for now ;)
- Rails integration
- [RestMyCase](https://github.com/goncalvesjoao/rest_my_case) integration


### Get in touch
If you have any questions, write an issue or get in touch [@joaquimadraz](https://twitter.com/joaquimadraz)

