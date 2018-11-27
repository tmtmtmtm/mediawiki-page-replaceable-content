require 'mediawiki_api'

module MediaWiki
  class Client
    def initialize(site:, username:, password:)
      @site = site
      @username = username
      @password = password
    end

    extend Forwardable
    def_delegators :wrapped_client, :edit, :get_wikitext

    private

    attr_accessor :site, :username, :password

    def wrapped_client
      @wrapped_client ||= MediawikiApi::Client.new("https://#{site}/w/api.php").tap do |c|
        result = c.log_in(username, password)
        raise "MediawikiApi::Client#log_in failed: #{result}" if result['result'] != 'Success'
      end
    end
  end
end
