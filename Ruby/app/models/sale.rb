class Sale < ApplicationRecord
  # ---------------------------
  # Relaciones
  # ---------------------------
  has_many :sale_items, dependent: :destroy
  has_many :products, through: :sale_items
  accepts_nested_attributes_for :sale_items, allow_destroy: true, reject_if: :all_blank

  # ---------------------------
  # Validaciones
  # ---------------------------
  validates :employee_email, :employee_name, presence: true
  validates :employee_email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :client_name, :client_email, presence: true
  validates :client_email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validate :at_least_one_sale_item
  validate :no_duplicate_products
  validate :cancelled_cannot_be_reverted, on: :update

  # ---------------------------
  # Scopes
  # ---------------------------
  scope :active, -> { where(cancelled: false) }
  scope :cancelled, -> { where(cancelled: true) }

  # ---------------------------
  # Métodos de dominio
  # ---------------------------
  def total_amount
    sale_items.sum { |item| item.quantity * item.unit_price }
  end

  def total_items
    sale_items.sum(:quantity)
  end

  def cancel!
    return if cancelled?

    Sale.transaction do
      # Devolver stock a los productos
      sale_items.each do |item|
        product = item.product
        next unless product # Por si el producto fue eliminado
        
        if product.state_new_item?
          if product.retired?
            # Si el producto fue dado de baja después de la venta, reactivarlo y devolver stock
            product.update_columns(
              retired: false,
              retired_at: nil,
              stock: item.quantity,
              updated_at: Time.current
            )
          else
            # Devolver stock para productos nuevos activos
            product.change_stock!(item.quantity)
          end
        elsif product.state_used_item? && product.retired?
          # Para productos usados que fueron dados de baja al venderse, reactivarlos
          product.update_columns(
            retired: false,
            retired_at: nil,
            stock: 1,
            updated_at: Time.current
          )
        end
      end

      # Marcar la venta como cancelada
      current_time = Time.current
      update_columns(
        cancelled: true,
        cancelled_at: current_time,
        updated_at: current_time
      )
    end
  end

  private

  def at_least_one_sale_item
    if sale_items.empty? || sale_items.all? { |item| item.marked_for_destruction? || item.product_id.blank? }
      errors.add(:base, "Debe seleccionar al menos un producto")
    end
  end

   def no_duplicate_products
    # Ignoramos items sin producto o marcados para destrucción
    product_ids = sale_items.reject { |item| item.marked_for_destruction? || item.product_id.blank? }
                            .map(&:product_id)

    if product_ids.uniq.size != product_ids.size
      errors.add(:base, "No se puede agregar el mismo producto más de una vez en la misma venta")
    end
  end

  def cancelled_cannot_be_reverted
    if cancelled_in_database == true && cancelled == false
      errors.add(:cancelled, "no puede revertirse una vez cancelada")
    end
  end
end
