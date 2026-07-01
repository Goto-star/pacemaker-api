module Authentication
  class DevelopmentUserResolver
    GOOGLE_UID = "development-user".freeze
    EMAIL = "dev@example.com".freeze
    NAME = "Development User".freeze

    class DisabledEnvironment < StandardError; end

    def self.call
      new.call
    end

    def call
      raise DisabledEnvironment unless Rails.env.development?

      user = User.find_or_initialize_by(google_uid: GOOGLE_UID)
      user.assign_attributes(email: EMAIL, name: NAME)
      user.save!
      user
    end
  end
end
