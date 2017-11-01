require 'test_helper'

WIKITEXT_MULTIPLE_TERMINATED = 'Hi, here is some introductory text.

Now let\'s have a recognized template:

{{Politician scraper comparison
|foo=43
|bar=Woolly Mountain Tapir
}}

Old content of the first section.

<!-- OUTPUT END -->

And some other text here before a new template:

{{Equine list
|quux=13
|bar=Horse
}}

Old content of the second section.
<!-- OUTPUT END -->

And a template with the same name as the original, but which will be
ignored because it\'s the second one on the page.

{{Politician scraper comparison
|foo=43
|bar=Woolly Mountain Tapir
}}

<!-- OUTPUT END -->

Now some trailing text.

'.freeze

WIKITEXT_SINGLE_UNTERMINATED = 'Hi, here is some introductory text.

Now let\'s have a recognized template:

{{Politician scraper comparison
|foo=43
|bar=Woolly Mountain Tapir
}}

But there\'s no terminating HTML comment.'.freeze

WIKITEXT_NOTHING_AFTER_TEMPLATE = 'Hi, here is some introductory text.

Now let\'s have a recognized template:

{{Politician scraper comparison
|foo=43
|bar=Woolly Mountain Tapir
}}'.freeze

WIKITEXT_NO_WHITESPACE_AFTER_TEMPLATE = 'Hi, here is some introductory text.

Now let\'s have a recognized template:

{{Politician scraper comparison
|foo=43
|bar=Woolly Mountain Tapir
}}Hello - this text immediately abuts the template.'.freeze

WIKITEXT_NOTHING_AFTER_TERMINATOR = '{{Politician scraper comparison
|foo=43
|bar=Woolly Mountain Tapir
}}

Old content of the first section.

<!-- OUTPUT END -->'.freeze

WIKITEXT_SINGLE_POSITIONAL_PARAMETER = '{{Politician scraper comparison|12345}}'.freeze

WIKITEXT_NUMBERED_PARAMETERS = '{{Politician scraper comparison|1=foo|2=bar|10=baz}}'.freeze

WIKITEXT_CONFUSING_PARAMETER_MIX = '{{Politician scraper comparison|id=42|12345|1=foo|baz=bar|789}}'.freeze

FakeResponse = Struct.new(:body)

describe 'ReplaceableContent' do
  let(:client) do
    client = MiniTest::Mock.new
    client.expect(
      :get_wikitext,
      FakeResponse.new(wikitext),
      ['Some Wiki page']
    )
    client
  end

  let(:section) do
    MediaWiki::Page::ReplaceableContent.new(
      client: client,
      title: 'Some Wiki page',
      template: 'Politician scraper comparison'
    )
  end

  describe 'multiple sections with output terminated by HTML comments' do
    let(:wikitext) { WIKITEXT_MULTIPLE_TERMINATED }

    it 'can be created an non-nill' do
      section.wont_be_nil
    end

    it 'can return the wikitext within a section' do
      section.existing_content.must_equal(
        "\n\nOld content of the first section.\n"
      )
      client.verify
    end

    it 'can be reassembled with some new content' do
      section.reassemble_page(
        'New content for the first section!',
        'succeeded'
      ).must_equal(
        'Hi, here is some introductory text.

Now let\'s have a recognized template:

{{Politician scraper comparison
|foo=43
|bar=Woolly Mountain Tapir
}}
New content for the first section!
<!-- OUTPUT END succeeded -->

And some other text here before a new template:

{{Equine list
|quux=13
|bar=Horse
}}

Old content of the second section.
<!-- OUTPUT END -->

And a template with the same name as the original, but which will be
ignored because it\'s the second one on the page.

{{Politician scraper comparison
|foo=43
|bar=Woolly Mountain Tapir
}}

<!-- OUTPUT END -->

Now some trailing text.

'
      )
      client.verify
    end

    it 'allows you to access the template parameters' do
      section.params.must_equal(foo: '43', bar: 'Woolly Mountain Tapir')
    end
  end

  describe 'single section with unterminated output' do
    let(:wikitext) { WIKITEXT_SINGLE_UNTERMINATED }

    it 'can be created an non-nill' do
      section.wont_be_nil
    end

    it 'can return the wikitext within a section' do
      section.existing_content.must_equal('')
      client.verify
    end

    it 'can be reassembled with some new content after the template, adding a terminating comment' do
      section.reassemble_page(
        'New content for the first section!',
        'succeeded'
      ).must_equal(
        'Hi, here is some introductory text.

Now let\'s have a recognized template:

{{Politician scraper comparison
|foo=43
|bar=Woolly Mountain Tapir
}}
New content for the first section!
<!-- OUTPUT END succeeded -->

But there\'s no terminating HTML comment.'
      )
      client.verify
    end

    it 'allows you to access the template parameters' do
      section.params.must_equal(foo: '43', bar: 'Woolly Mountain Tapir')
    end

    it 'has no anonymous parameters' do
      section.anonymous_params.must_be_empty
    end

    it 'will post back with the new content and an optional comment on the run' do
      client.expect(
        :edit,
        nil,
        [
          title: 'Some Wiki page',
          text: 'Hi, here is some introductory text.

Now let\'s have a recognized template:

{{Politician scraper comparison
|foo=43
|bar=Woolly Mountain Tapir
}}
New content for the first section!
<!-- OUTPUT END Run time: took absolutely ages -->

But there\'s no terminating HTML comment.',
        ]
      )
      section.replace_output(
        'New content for the first section!',
        'Run time: took absolutely ages'
      )
      client.verify
    end
  end

  describe 'no whitespace is found after the template' do
    let(:wikitext) { WIKITEXT_NO_WHITESPACE_AFTER_TEMPLATE }

    it 'can parse the page and return empty existing content' do
      section.existing_content.must_equal('')
    end

    it 'can be reassembled with new content' do
      section.reassemble_page(
        'New content here!',
        'succeeded'
      ).must_equal(
        'Hi, here is some introductory text.

Now let\'s have a recognized template:

{{Politician scraper comparison
|foo=43
|bar=Woolly Mountain Tapir
}}
New content here!
<!-- OUTPUT END succeeded -->Hello - this text immediately abuts the template.'
      )
    end
  end

  describe 'nothing is after the template' do
    let(:wikitext) { WIKITEXT_NOTHING_AFTER_TEMPLATE }

    it 'can parse the page and return empty existing content' do
      section.existing_content.must_equal('')
    end

    it 'can be reassembled with new content' do
      section.reassemble_page(
        'New content here!',
        'succeeded'
      ).must_equal(
        'Hi, here is some introductory text.

Now let\'s have a recognized template:

{{Politician scraper comparison
|foo=43
|bar=Woolly Mountain Tapir
}}
New content here!
<!-- OUTPUT END succeeded -->'
      )
    end
  end

  describe 'existing template with nothing after the terminating comment' do
    let(:wikitext) { WIKITEXT_NOTHING_AFTER_TERMINATOR }

    it 'can return the wikitext within a section' do
      section.existing_content.must_equal(
        "\n\nOld content of the first section.\n"
      )
      client.verify
    end

    it 'can be reassembled with new content' do
      section.reassemble_page(
        'New content here!',
        'succeeded'
      ).must_equal(
        '{{Politician scraper comparison
|foo=43
|bar=Woolly Mountain Tapir
}}
New content here!
<!-- OUTPUT END succeeded -->'
      )
    end
  end

  describe 'a template with a single positional parameter' do
    let(:wikitext) { WIKITEXT_SINGLE_POSITIONAL_PARAMETER }

    it 'must return only one anonymous parameter' do
      section.anonymous_params.must_equal(%w[12345])
    end

    it 'must not return named parameters' do
      section.params.must_be_empty
    end
  end

  describe 'a template with numbered parameters' do
    let(:wikitext) { WIKITEXT_NUMBERED_PARAMETERS }

    it 'returns numbered parameters' do
      section.params.must_equal(
        1 => 'foo',
        2 => 'bar',
        10 => 'baz'
      )
    end

    it 'must not return anonymous parameters' do
      section.anonymous_params.must_be_empty
    end
  end

  describe 'a template with a confusing mix of parameters' do
    let(:wikitext) { WIKITEXT_CONFUSING_PARAMETER_MIX }

    it 'returns both parameters in an array' do
      section.anonymous_params.must_equal(%w[12345 789])
    end

    it 'returns the named and numbered parameters' do
      section.params.must_equal(
        :id => '42',
        1 => 'foo',
        :baz => 'bar'
      )
    end
  end
end
