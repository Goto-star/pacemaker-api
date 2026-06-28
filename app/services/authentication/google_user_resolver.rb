module Authentication
  class GoogleUserResolver
    def self.call(auth_hash)
      new(auth_hash).call
    end

    def initialize(auth_hash)
      @auth_hash = auth_hash.to_h.with_indifferent_access
    end

    def call
      raise ArgumentError, "unexpected OAuth provider" unless auth_hash[:provider] == "google_oauth2"

      info = auth_hash.fetch(:info)
      user = User.find_or_initialize_by(google_uid: auth_hash.fetch(:uid))
      user.assign_attributes(email: info.fetch(:email), name: info[:name])
      user.save!
      user
    end

    private

    attr_reader :auth_hash
  end
end
