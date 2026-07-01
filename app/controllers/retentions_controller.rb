class RetentionsController < ApplicationController
  include Authenticatable

  def index
    retentions = Scheduling::RetentionListBuilder.new(user: current_user).call

    render json: { retentions: retentions.map { |entry| retention_json(entry) } }
  end

  private

  def retention_json(entry)
    study_unit = entry[:study_unit]
    {
      study_unit: {
        id: study_unit.id,
        material_id: study_unit.material_id,
        title: study_unit.title,
        position: study_unit.position,
        estimated_minutes: study_unit.estimated_minutes
      },
      retention: entry[:retention]
    }
  end
end
