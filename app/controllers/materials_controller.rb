class MaterialsController < ApplicationController
  include Authenticatable

  def index
    materials = current_user.materials.order(:id)
    render json: { materials: materials.map { |material| material_json(material) } }
  end

  def create
    material = current_user.materials.new(material_params)

    if material.save
      render json: { material: material_json(material) }, status: :created
    else
      render_unprocessable(material)
    end
  end

  def update
    material = current_user.materials.find(params[:id])

    if material.update(material_params)
      render json: { material: material_json(material) }
    else
      render_unprocessable(material)
    end
  end

  def destroy
    material = current_user.materials.find(params[:id])
    material.destroy
    head :no_content
  end

  private

  def material_params
    params.require(:material).permit(:title, :total_amount, :unit_label, :deadline)
  end

  def material_json(material)
    {
      id: material.id,
      title: material.title,
      total_amount: material.total_amount,
      unit_label: material.unit_label,
      deadline: material.deadline
    }
  end
end
