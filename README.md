Compel 
==========================
![](https://travis-ci.org/joaquimadraz/compel.svg)
[![Code Climate](https://codeclimate.com/github/joaquimadraz/compel/badges/gpa.svg)](https://codeclimate.com/github/joaquimadraz/compel)

Ruby Hash Coercion and Validation

This is a straight forward way to validate a Ruby Hash: just give your object and the schema to validate.
Based on the same principle from [Grape](https://github.com/ruby-grape/grape) framework and [sinatra-param](https://github.com/mattt/sinatra-param) gem to validate request params.

There are 3 ways run validations:

- `#run`  
  - Validates and return an Hash with coerced params plus a `:errors` key with an Hash of errors if any.
- `#run!`
  - Validates and raises `Compel::InvalidParamsError` exception the coerced params and generated errors.
- `#run?`
  - Validates and returns true or false.

### Example
```ruby
params= {
  first_name: 'Joaquim',
  birth_date: '1989-0',
  address: {
    line_one: 'Lisboa',
    post_code: '1100',
    country: 'PT'
  }
}

Compel.run(params) do
  param :first_name, String, required: true
  param :last_name, String, required: true
  param :birth_date, DateTime
  param :address, Hash do
    param :line_one, String, required: true
    param :line_two, String, default: '-'
    param :post_code, String, required: true, format: /^\d{4}-\d{3}$/
    param :country_code, String, in: ['PT', 'GB'], default: 'PT'
  end
end
```

Will return an [Hashie::Mash](https://github.com/intridea/hashie) object:

```ruby
{
  "first_name" => "Joaquim",
  "address" => {
    "line_one" => "Lisboa", 
    "line_two" => "-", # default value
    "post_code_pfx" => 1100, # Already an Integer
    "country_code"=> "PT"
  },
  "errors" => {
    "last_name" => ["is required"],
    "birth_date" => ["'1989-0' is not a valid DateTime"],
    "address" => {
      "post_code_sfx" => ["is required"]
    }
  }
}
```

### Types

- `Integer`
- `Float`
- `String`
- `JSON`
  - ex: `"{\"a\":1,\"b\":2,\"c\":3}"`
- `Hash`
  - ex: `{ a: 1,  b: 2, c: 3 }`
- `Date`
- `Time`
- `DateTime`
- `Compel::Boolean`, 
  - ex: `1`/`0`, `true`/`false`, `t`/`f`, `yes`/`no`, `y`/`n`
