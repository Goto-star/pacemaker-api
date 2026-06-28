class MeController < ApplicationController
  include Authenticatable

  def show
    render json: {
      user: {
        id: current_user.id,
        email: current_user.email,
        name: current_user.name
      }
    }
  end
end
