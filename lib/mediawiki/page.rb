require 'mediawiki_api'

module MediaWiki
  module Page
    class ReplaceableContent
      def initialize(client:, title:, template:)
        @client = client
        @title = title
        @template = template
      end

      def existing_content
        page_parts[:to_replace]
      end

      def reassemble_page(new_content, run_comment = '')
        "%<before>s{{%<template_name>s%<parameters>s}}
#{new_content}
<!-- OUTPUT END #{run_comment} -->
%<keep>s" % page_parts
      end

      def replace_output(new_content, run_comment = '')
        new_wikitext = reassemble_page(new_content, run_comment)
        client.edit(title: title, text: new_wikitext)
      end

      def params
        # Returns the named parameters from the template tag as a Hash
        # where the keys are symbolized versions of the parameter
        # names.
        # FIXME: untemplate these using the MediaWiki API before
        # returning them.
        all_parameters.map do |p|
          m = /(.*?)=(.*)/m.match(p)
          [m[1].strip.to_sym, m[2]]
        end.to_h
      end

      private

      attr_accessor :client, :title, :template

      def wikitext
        @wikitext ||= client.get_wikitext(title).body
      end

      def template_re
        # FIXME: there are obviously better ways of doing this parsing
        # than with a regular expression. e.g. there is an EBNF
        # version of the MediaWiki grammar which we could use to
        # generate a proper parser.
        /
          ^(?<before>.*?)
          \{\{
          (?<template_name>#{Regexp.quote(template)})
          (?<parameters>.*?)
          \}\}\n
          (?<after>.*)$
        /xm
      end

      def page_parts
        return @page_parts if @page_parts
        m = template_re.match(wikitext)
        raise "The template '#{template}' was not found in '#{title}'" unless m
        parts = matchdata_to_h(m)
        @page_parts = parts.merge(split_after(parts[:after]))
      end

      def split_after(after)
        # The part of the page after the template may or may not have
        # the special HTML comment that marks the end of the previous
        # output; if it's not there we insert the new content right
        # after the template tag.
        if after =~ /^(?<to_replace>.*?)\n<!-- OUTPUT END (?:.*?)-->\n(?<keep>.*)/m
          matchdata_to_h(Regexp.last_match)
        else
          { to_replace: '', keep: after }
        end
      end

      def all_parameters
        # This returns all parameters, including anonymous, numbered and
        # named parameters. (Though we only handle named parameters at
        # the moment.)
        page_parts[:parameters].split('|').select do |s|
          s.strip!
          s.empty? ? nil : s
        end
      end

      def matchdata_to_h(md)
        md.names.map(&:to_sym).zip(md.captures).to_h
      end
    end
  end
end
