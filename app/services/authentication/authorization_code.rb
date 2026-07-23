require "digest"
require "securerandom"

module Authentication
  class AuthorizationCode
    EXPIRATION = 2.minutes

    class InvalidCode < StandardError; end

    class << self
      def issue(user:, frontend_state:)
        validate_value!(frontend_state)
        code = SecureRandom.urlsafe_base64(32)
        OauthAuthorizationCode.create!(
          user:,
          code_digest: digest(code),
          state_digest: digest(frontend_state),
          expires_at: EXPIRATION.from_now
        )
        code
      end

      def consume(code:, frontend_state:)
        validate_value!(code)
        validate_value!(frontend_state)
        record = OauthAuthorizationCode.find_by(code_digest: digest(code))
        raise InvalidCode if record.nil?

        record.with_lock do
          raise InvalidCode unless usable?(record, frontend_state)

          record.update!(consumed_at: Time.current)
          record.user
        end
      rescue ArgumentError
        raise InvalidCode
      end

      private

      def usable?(record, frontend_state)
        record.consumed_at.nil? &&
          record.expires_at.future? &&
          ActiveSupport::SecurityUtils.secure_compare(
            record.state_digest,
            digest(frontend_state)
          )
      end

      def digest(value)
        Digest::SHA256.hexdigest(value)
      end

      def validate_value!(value)
        raise ArgumentError unless value.is_a?(String) && value.present?
      end
    end
  end
end
