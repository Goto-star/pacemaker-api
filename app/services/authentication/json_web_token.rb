module Authentication
  # フロントに渡す PaceMaker 独自セッショントークンの発行と検証を担う。
  # 署名鍵は Rails の secret_key_base（credentials / 環境変数で管理）を使う。
  class JsonWebToken
    ALGORITHM = "HS256".freeze
    DEFAULT_EXPIRATION = 24.hours

    class << self
      def encode(payload, expires_in: DEFAULT_EXPIRATION)
        claims = payload.merge(exp: expires_in.from_now.to_i)
        JWT.encode(claims, secret_key, ALGORITHM)
      end

      # 検証に失敗した場合（改ざん・期限切れ・不正な形式）は nil を返す。
      def decode(token)
        return if token.blank?

        payload, = JWT.decode(token, secret_key, true, algorithm: ALGORITHM)
        payload.with_indifferent_access
      rescue JWT::DecodeError
        nil
      end

      private

      def secret_key
        Rails.application.secret_key_base
      end
    end
  end
end
