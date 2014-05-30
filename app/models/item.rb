class Item < ActiveRecord::Base

    def self.client
      Faraday.new(url: ENDPOINT) do |faraday|
        faraday.request :basic_auth, API_KEY, API_SECRET
        faraday.adapter :net_http
      end
    end

end
