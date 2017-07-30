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

FakeResponse = Struct.new(:body)

describe 'ReplaceableContent' do
  describe 'multiple sections with output terminated by HTML comments' do
    let(:client) do
      client = MiniTest::Mock.new
      client.expect(
        :get_wikitext,
        FakeResponse.new(WIKITEXT_MULTIPLE_TERMINATED),
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

    it 'can be created an non-nill' do
      section.wont_be_nil
    end

    it 'can return the wikitext within a section' do
      section.existing_content.must_equal(
        "\nOld content of the first section.\n"
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
    let(:client) do
      client = MiniTest::Mock.new
      client.expect(
        :get_wikitext,
        FakeResponse.new(WIKITEXT_SINGLE_UNTERMINATED),
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
end
