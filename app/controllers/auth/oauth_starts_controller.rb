require "cgi"

module Auth
  class OauthStartsController < ApplicationController
    include ActionController::RequestForgeryProtection

    FRONTEND_STATE_PATTERN = /\A[A-Za-z0-9_-]{43,128}\z/

    protect_from_forgery with: :exception

    def create
      frontend_state = params[:state].to_s
      unless FRONTEND_STATE_PATTERN.match?(frontend_state)
        return render json: { error: "Invalid OAuth state" }, status: :unprocessable_content
      end

      session[:frontend_oauth_state] = frontend_state
      render_oauth_form
    end

    private

    def render_oauth_form
      nonce = SecureRandom.urlsafe_base64(16)
      response.headers["Cache-Control"] = "no-store"
      response.headers["Content-Security-Policy"] = [
        "default-src 'none'",
        "script-src 'nonce-#{nonce}'",
        "form-action 'self'",
        "base-uri 'none'"
      ].join("; ")
      response.headers["Referrer-Policy"] = "no-referrer"
      render body: oauth_form_html(nonce), content_type: "text/html"
    end

    def oauth_form_html(nonce)
      authenticity_token = CGI.escapeHTML(form_authenticity_token)

      <<~HTML
        <!doctype html>
        <html lang="ja">
          <head><meta charset="utf-8"><title>Googleログイン</title></head>
          <body>
            <form id="oauth-start" method="post" action="/auth/google_oauth2">
              <input type="hidden" name="authenticity_token" value="#{authenticity_token}">
              <noscript><button type="submit">Googleログインを続ける</button></noscript>
            </form>
            <script nonce="#{nonce}">document.getElementById("oauth-start").submit()</script>
          </body>
        </html>
      HTML
    end
  end
end
