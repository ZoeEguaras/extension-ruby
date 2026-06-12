class Backstore::ReportsController < Backstore::BaseController
  before_action :authorize_reports!
  before_action :load_filters
  before_action :load_sales_scope
  before_action :load_employee_emails

  def index
    @total_revenue         = @sales_with_items.sum("sale_items.quantity * sale_items.unit_price")
    @total_sales           = @sales.distinct.count
    @total_items           = @sales_with_items.sum("sale_items.quantity")
    @average_sale          = @total_sales.positive? ? (@total_revenue / @total_sales) : 0
    
    @sales_by_type = @sales
      .joins(sale_items: :product)
      .group("products.media_type")
      .distinct
      .count("sales.id")
      .transform_keys do |key|
        { "vinyl" => "Vinilo", "cd" => "CD" }[key] || key.to_s.titleize
      end

    @sales_by_genre = @sales
      .joins(sale_items: { product: :genres })
      .group("genres.name")
      .distinct
      .count("sales.id")

    @top_products = @sales_with_items
      .joins(sale_items: :product)
      .group("products.name")
      .sum("sale_items.quantity")
      .sort_by { |_, quantity| -quantity }
      .first(5)
      .to_h
  end

  private

  def authorize_reports!
    authorize! :read, :reports
  end

  def load_filters
    @start_date = params[:start_date].presence
    @end_date   = params[:end_date].presence
    @employee   = params[:employee_email].presence
    @genre_id   = params[:genre_id].presence
    @media_type = params[:media_type].presence

    start_date = @start_date ? Date.parse(@start_date) : nil
    end_date   = @end_date ? Date.parse(@end_date) : nil
    today      = Date.today

    validation_errors = []
    validation_errors << "La fecha de fin no puede ser mayor que hoy." if end_date && end_date > today

    if start_date && end_date
      validation_errors << "La fecha de inicio no puede ser mayor que la fecha de fin." if start_date > end_date
    elsif start_date && start_date > today
      validation_errors << "La fecha de inicio no puede ser mayor que hoy."
    end

    if validation_errors.any?
      flash.now[:alert] = validation_errors.to_sentence
      @date_range = nil
    elsif start_date && end_date
      @date_range = start_date..end_date
    elsif start_date
      @date_range = start_date..today
    elsif end_date
      @date_range = Date.new(2000, 1, 1)..end_date
    else
      @date_range = nil
    end

    # Guardar los valores normalizados para que el formulario los muestre tal cual
    @start_date = start_date&.to_s
    @end_date   = end_date&.to_s

    # Nombre de género para mostrar en filtros
    @genre_name = @genre_id.present? ? Genre.find_by(id: @genre_id)&.name : nil
  rescue ArgumentError
    @date_range = nil
  end

  def load_sales_scope
    base_scope = Sale.includes(:sale_items)

    # 1. Filtro por rango de fechas
    if @date_range
      timestamp_range = @date_range.begin.beginning_of_day..@date_range.end.end_of_day
      base_scope = base_scope.where(created_at: timestamp_range)
    end

    # 2. Filtro por empleado
    base_scope = base_scope.where(employee_email: @employee) if @employee

    # 3. Si se pide género o tipo de medio, se hace un único join unificado
    if @genre_id || @media_type
      base_scope = base_scope.joins(sale_items: { product: :genres })
      
      base_scope = base_scope.where(genres: { id: @genre_id }) if @genre_id
      base_scope = base_scope.where(products: { media_type: @media_type }) if @media_type
    end

    # 4. Definición de scopes finales
    @sales            = base_scope.where(cancelled: false).distinct # (ventas únicas)
    @sales_with_items = base_scope.where(cancelled: false).joins(:sale_items) # (se necesitan TODOS los ítems)
  end

  def load_employee_emails
    # Todos los usuarios con rol válido (administrador, gerente, empleado),
    # ordenados alfabéticamente por email.
    @employee_emails = User
      .where(role: User.roles.keys)
      .order(:email)
      .pluck(:email)
  end
end


