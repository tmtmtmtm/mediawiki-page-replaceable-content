# MediaWiki::Page::ReplaceableContent

This gem provides a class,
`MediaWiki::Page::ReplaceableContent`, to help you
programmatically rewrite MediaWiki pages based on the parameters
of a template tag in that page. (This is a model used by the
[Listeria](https://tools.wmflabs.org/listeria/) bot, for
example.)

See the "Usage" section below for an example.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mediawiki-page-replaceable_content'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mediawiki-page-replaceable_content

## Usage

To use the `ReplaceableContent` class, you must first create a
`Client` object, which specifies the MediaWiki site on which you
want to rewrite a page, and the username and password for
authentication.

```ruby
require 'mediawiki/client'

client = MediaWiki::Client.new(
  site:     'www.wikidata.org',
  username: ENV['WIKI_USERNAME'],
  password: ENV['WIKI_PASSWORD']
)
```

Then you can use that to create a `ReplaceableContent` class,
which specifies a particular page and the template on that page
that your content will be placed directly after:

```ruby
require 'mediawiki/page'

section = MediaWiki::Page::ReplaceableContent.new(
  client:   client,
  title:    'User:Mhl20/Fibonnacci test',
  template: 'Fibonacci'
)
```

For example, suppose that page at
https://www.wikidata.org/wiki/User:Mhl20/Fibonnacci_test had the
following content:

```
Here are some Fibonacci numbers:

{{Fibonacci
|max_fib=10
}}

You can find more about them here:
https://en.wikipedia.org/wiki/Fibonacci_number
```

Then you could rewrite it, using the `ReplaceableContent` object
created above, with:

```ruby
def fibonacci_numbers(limit)
  numbers = []
  i, j = 0, 1
  while i <= limit
    numbers << i
    i, j = j, i + j
  end
  numbers
end

def wikitext_fibonacci_rows(limit)
  fibs = fibonacci_numbers(limit)
  "|-\n" + 0.upto(fibs.length - 1).map { |f| "| ''F''<sub>#{f}</sub>\n" }.join('') +
    "|-\n" + fibs.map { |n| "| #{n}\n" }.join('')
end

def wikitext_fibonacci(limit)
  "=== Some Fibonacci numbers ===\n:{| class=\"wikitable\"\n" +
    wikitext_fibonacci_rows(limit) +
    '|}'
end

limit = Integer(section.params[:max_fib])
section.replace_output(
  wikitext_fibonacci(limit),
  "Rewrote with numbers up to #{limit}"
)
```

The result of running that would be that the page had the
following wikitext:

```
Here are some Fibonacci numbers:

{{Fibonacci
|max_fib=10
}}
=== Some Fibonacci numbers ===
:{| class="wikitable"
|-
| ''F''<sub>0</sub>
| ''F''<sub>1</sub>
| ''F''<sub>2</sub>
| ''F''<sub>3</sub>
| ''F''<sub>4</sub>
| ''F''<sub>5</sub>
| ''F''<sub>6</sub>
|-
| 0
| 1
| 1
| 2
| 3
| 5
| 8
|}
<!-- OUTPUT END Rewrote with numbers up to 10 -->

You can find more about them here:
https://en.wikipedia.org/wiki/Fibonacci_number
```

On subsequent uses, only the text between the template tag and
the `<!-- OUTPUT END ... --->` comment will be rewritten.

If you need to rely on the previous content, you can get that
with `section.existing_content`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/everypolitician/mediawiki-page-replaceable_content

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
