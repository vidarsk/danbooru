module Sources::Strategies
  class Twitter < Base
    attr_reader :image_urls

    def self.url_match?(url)
      url =~ %r!https?://(?:mobile\.)?twitter\.com/\w+/status/\d+! || url =~ %r{https?://pbs\.twimg\.com/media/}
    end

    def referer_url
      if @referer_url =~ %r!https?://(?:mobile\.)?twitter\.com/\w+/status/\d+! && @url =~ %r{https?://pbs\.twimg\.com/media/}
        @referer_url
      else
        @url
      end
    end

    def site_name
      "Twitter"
    end

    def api_response
      status_id = status_id_from_url(url)
      @api_response ||= TwitterService.new.client.status(status_id, tweet_mode: "extended")
    end

    def get
      attrs = api_response.attrs
      @artist_name = attrs[:user][:name]
      @profile_url = "https://twitter.com/" + attrs[:user][:screen_name]
      @image_urls = TwitterService.new.image_urls(api_response)
      @image_url = @image_urls.first
      @artist_commentary_title = ""
      @artist_commentary_desc = attrs[:full_text]
      @tags = attrs[:entities][:hashtags].map do |text:, indices:|
        [text, "https://twitter.com/hashtag/#{text}"]
      end
    rescue ::Twitter::Error::Forbidden
    end

    def normalize_for_artist_finder!
      url.downcase
    end

    def normalizable_for_artist_finder?
      true
    end

    def dtext_artist_commentary_desc
      url_replacements = api_response.urls.map do |obj|
        [obj.url.to_s, obj.expanded_url.to_s]
      end
      url_replacements += api_response.media.map do |obj|
        [obj.url.to_s, ""]
      end
      url_replacements = url_replacements.to_h

      desc = artist_commentary_desc
      desc = CGI::unescapeHTML(desc)
      desc = desc.gsub(%r!https?://t\.co/[^[:space:]]+!i, url_replacements)
      desc = desc.gsub(%r!#([^[:space:]]+)!, '"#\\1":[https://twitter.com/hashtag/\\1]')
      desc = desc.gsub(%r!@([a-zA-Z0-9_]+)!, '"@\\1":[https://twitter.com/\\1]')
      desc.strip
    end

    def status_id_from_url(url)
      if url =~ %r{^https?://(?:mobile\.)?twitter\.com/\w+/status/(\d+)}
        $1.to_i
      else
        raise Sources::Error.new("Couldn't get status ID from URL: #{url}")
      end
    end
  end
end
