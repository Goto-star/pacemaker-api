class StudyUnitsController < ApplicationController
  include Authenticatable

  def index
    study_units = material.study_units.order(:position, :id)
    render json: { study_units: study_units.map { |study_unit| study_unit_json(study_unit) } }
  end

  def create
    study_unit = material.study_units.new(study_unit_params)

    if study_unit.save
      render json: { study_unit: study_unit_json(study_unit) }, status: :created
    else
      render_unprocessable(study_unit)
    end
  end

  def update
    study_unit = material.study_units.find(params[:id])

    if study_unit.update(study_unit_params)
      render json: { study_unit: study_unit_json(study_unit) }
    else
      render_unprocessable(study_unit)
    end
  end

  def destroy
    study_unit = material.study_units.find(params[:id])
    study_unit.destroy
    head :no_content
  end

  private

  # 自分が所有する教材のみを対象にし、他ユーザーの教材配下は 404 にする。
  def material
    @material ||= current_user.materials.find(params[:material_id])
  end

  def study_unit_params
    params.require(:study_unit).permit(:title, :position, :estimated_minutes)
  end

  def study_unit_json(study_unit)
    {
      id: study_unit.id,
      material_id: study_unit.material_id,
      title: study_unit.title,
      position: study_unit.position,
      estimated_minutes: study_unit.estimated_minutes
    }
  end
end
