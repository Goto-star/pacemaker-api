class HealthController < ApplicationController
  # GET /
  # Lightweight JSON health check. Verifies the app booted and the database
  # connection is reachable, returning 200 on success and 503 otherwise.
  def show
    ActiveRecord::Base.connection.execute("SELECT 1")

    render json: { status: "ok", database: "connected" }, status: :ok
  rescue StandardError => e
    render json: { status: "error", database: "disconnected", message: e.message },
           status: :service_unavailable
  end
end
