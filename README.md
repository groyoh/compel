Compel
==========================
![](https://travis-ci.org/joaquimadraz/compel.svg)
[![Code Climate](https://codeclimate.com/github/joaquimadraz/compel/badges/gpa.svg)](https://codeclimate.com/github/joaquimadraz/compel)
[![Test Coverage](https://codeclimate.com/github/joaquimadraz/compel/badges/coverage.svg)](https://codeclimate.com/github/joaquimadraz/compel/coverage)

Ruby Object Coercion and Validation

This is a straight forward way to validate any Ruby object: just give an object and the schema.

The motivation was to create an integration for [RestMyCase](https://github.com/goncalvesjoao/rest_my_case) to have validations before any business logic execution and to build a easy way coerce and validate params on [Sinatra](https://github.com/sinatra/sinatra).

The schema builder is based on [Joi](https://github.com/hapijs/joi).

### Usage

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

Compel.run(object, schema) # or schema.validate(object)
```

Will return a `Compel::Result` object:

```ruby
=> <Compel::Result
  @errors={
    "last_name" => ["is required"],
    "birth_date" => ["'1989-0' is not a parsable datetime with format: %FT%T"],
    "address" => {
      "post_code" => ["must match format ^\\d{4}-\\d{3}$"]
    }
  },
  @valid=false,
  @value={
    "first_name" => "Joaquim",
    "birth_date" => "1989-0",
    "address" => {
      "line_one" => "Lisboa",
      "post_code" => "1100",
      "country_code" => "PT",
      "line_two" => "-"
    },
    "errors" => {
      "last_name" => ["is required"],
      "birth_date" => ["'1989-0' is not a parsable datetime with format: %FT%T"],
      "address" => {
        "post_code" => ["must match format ^\\d{4}-\\d{3}$"]
      }
    }
  }>
```

There are 4 ways to run validations:

Method  | Behaviour
------------- | -------------
`#run`  | Validates and returns a `Compel::Result` (see below)
`#run!` | Validates and raises `Compel::InvalidObjectError` exception with the coerced params and errors.
`#run?` | Validates and returns true or false.
`schema#validate` | Check below

==========================

### Schema Builder API

#### Compel#any
`Any` referes to any type that is available to coerce with Compel.
Methods `length`, `min_length` and `max_length` turn the object to validate into a `string` to compare the length.

**Methods**:
- `is(``value``)`
- `required`
- `default(``value``)`
- `length(``integer``)`
- `min_length(``integer``)`
- `max_length(``integer``)`
- `if`
  - `if(->(value){ value == 1 })`
  - `if{|value| value == 1 }`
  - `if{:custom_validation} # Check the specs for now, I'm rewriting the docs ;)` 

==========================

#### Compel#array

**Methods**:
- `#items(``schema``)`

**Examples**:
```ruby
. [1, 2, 3]
. [{ a: 1, b: 2}
. { a: 3, b: 4 }]
```

==========================

#### Compel#hash

**Methods**:
- `keys(``schema_hash``)`

**Examples**:
```ruby
. { a: 1,  b: 2, c: 3 }
```

==========================

#### Compel#date

**Methods**:
- `format(``ruby_date_format``)`
- `iso8601`, set format to: `%Y-%m-%d`

==========================

#### Compel#datetime & Compel#time

**Methods**:
- `format(``ruby_date_format``)`
- `iso8601`, set format to: `%FT%T`

==========================

#### Compel#json

**Examples**:
```ruby
. "{\"a\":1,\"b\":2,\"c\":3}"
```

==========================

#### Compel#boolean

**Examples**:
```ruby
. 1/0
. true/false
. 't'/'f'
. 'yes'/'no'
. 'y'/'n'
```

==========================

#### Compel#string

**Methods**:
- `in(``array``)`
- `min(``value``)`
- `max(``value``)`
- `format(``regexp``)`
- `email`
- `url`

==========================

#### Compel#integer

**Methods**:
- `in(``array``)`
- `min(``value``)`
- `max(``value``)`

==========================

#### Compel#float

**Methods**:
- `in(``array``)`
- `min(``value``)`
- `max(``value``)`

==========================

### Schema Validate

For straight forward validations, you can call `#validate` on schema and it will return a `Compel::Result` object.

```ruby
result = Compel.string
               .format(/^\d{4}-\d{3}$/)
               .required
               .validate('1234')

puts result.errors
# => ["must match format ^\\d{4}-\\d{3}$"]
```

#### Compel Result

Simple object that encapsulates a validation result.

Method  | Behaviour
------------- | -------------
`#value`  | the coerced value or the input value is invalid
`#errors` | array of errors is any.
`#valid?` | `true` or `false`
`#raise?` | raises a `Compel::InvalidObjectError` if invalid, otherwise returns `#value`

#### Custom Options

`Custom error message`

Examples:
```ruby
schema = Compel.string.required(message: 'this is really required')

result = schema.validate(nil)

p result.errors
=> ["this is really required"]

schema = Compel.string.is('Hello', message: 'give me an Hello!')

result = schema.validate(nil)

p result.errors
=> ["give me an Hello!"]
```

==========================

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

  error Compel::InvalidObjectError do |exception|
    status 400
    { errors: exception.object[:errors] }.to_json
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

    gem 'compel', '~> 0.5.0'

And then execute:

    $ bundle

### Get in touch

If you have any questions, write an issue or get in touch [@joaquimadraz](https://twitter.com/joaquimadraz)

