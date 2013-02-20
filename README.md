# MiniSat

[![Build Status](https://secure.travis-ci.org/eagletmt/ruby-minisat.png)](https://travis-ci.org/eagletmt/ruby-minisat)

Ruby binding for [MiniSat](http://minisat.se/).

## Installation

Add this line to your application's Gemfile:

    gem 'minisat'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install minisat

## Usage

```ruby
require 'minisat'

s = MiniSat::Solver.new
v1 = MiniSat::Var.new s
v2 = MiniSat::Var.new s
v3 = MiniSat::Var.new s
s << [v1] << [-v2, v3]  # v1 /\ (not(v2) \/ v3)
m = s.solve
puts "v1: #{m[v1]}, v2: #{m[v2]}, v3: #{m[v3]}"
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
