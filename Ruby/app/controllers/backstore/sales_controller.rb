class Backstore::SalesController < Backstore::BaseController
  before_action :set_sale, only: %i[ show cancel ]

  # GET /sales or /sales.json
  def index
    @filter = params[:filter] == "cancelled" ? "cancelled" : "active"
    scope = @filter == "cancelled" ? Sale.cancelled : Sale.active
    @sales = scope.order(created_at: :desc).page(params[:page]).per(20)
  end

  # GET /sales/new
  def new
    @sale = Sale.new
    @products = Product.active.where.not(retired: true).order(:name)
    # No crear un item vacío inicialmente
  end

  # POST /sales or /sales.json
  def create
    @sale = Sale.new(sale_params)
    @products = Product.active.where.not(retired: true).order(:name)
    
    # Establecer automáticamente el empleado que realizó la venta
    @sale.employee_email = current_user.email
    @sale.employee_name = "#{current_user.nombre} #{current_user.apellido}".strip

    # Validar que haya al menos un item
    if sale_params[:sale_items_attributes].blank? || sale_params[:sale_items_attributes].values.all? { |item| item[:product_id].blank? }
      @sale.errors.add(:base, "Debe seleccionar al menos un producto")
      @sale.sale_items.build if @sale.sale_items.empty?
      render :new, status: :unprocessable_entity
      return
    end

    # Validar stock antes de crear la venta
    sale_params[:sale_items_attributes]&.each do |key, item_params|
      next if item_params[:product_id].blank? || item_params[:quantity].blank? || item_params[:_destroy] == "1"
      
      product = Product.find_by(id: item_params[:product_id])
      quantity = item_params[:quantity].to_i
      
      if product.nil?
        @sale.errors.add(:base, "Producto no encontrado")
        @sale.sale_items.build if @sale.sale_items.empty?
        render :new, status: :unprocessable_entity
        return
      end
      
      if product.retired?
        @sale.errors.add(:base, "El producto '#{product.name}' está dado de baja")
        @sale.sale_items.build if @sale.sale_items.empty?
        render :new, status: :unprocessable_entity
        return
      end
      
      if quantity > product.stock
        @sale.errors.add(:base, "El producto '#{product.name}' no tiene suficiente stock (disponible: #{product.stock})")
        @sale.sale_items.build if @sale.sale_items.empty?
        render :new, status: :unprocessable_entity
        return
      end
    end

    respond_to do |format|
      begin
        Sale.transaction do
          @sale.save!

          # Actualizar stock de productos
          @sale.sale_items.each do |item|
            product = item.product
            if product.state_new_item? && !product.retired?
              # Solo actualizar stock para productos nuevos
              product.change_stock!(-item.quantity)
            elsif product.state_used_item?
              # Para productos usados, marcar como dado de baja (soft delete)
              product.soft_delete! if product.stock == 1
            end
          end
        end

        format.html { redirect_to [:backstore, @sale], notice: "Venta realizada correctamente." }
        format.json { render :show, status: :created, location: [:backstore, @sale] }
      rescue ActiveRecord::RecordInvalid
        @sale.sale_items.build if @sale.sale_items.empty?
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @sale.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /sales/1 or /sales/1.json or /sales/1.pdf
  def show
    respond_to do |format|
      format.html
      format.json
      format.pdf do
        render pdf: "venta_#{@sale.id}",
               template: "backstore/sales/show",
               layout: "pdf",
               page_size: "A4",
               margin: { top: 20, bottom: 20, left: 20, right: 20 },
               show_as_html: params[:debug].present?
      end
      
    end
  end
  # PATCH /sales/1/cancel
  def cancel
    if @sale.cancelled?
      redirect_to [:backstore, @sale], alert: "La venta ya está cancelada."
      return
    end

    @sale.cancel!
    redirect_to [:backstore, @sale], notice: "Venta cancelada correctamente. El stock ha sido devuelto a los productos."
  end

  # GET /sales/search_products
  def search_products
    query = params[:q].to_s.strip
    products = Product.active.where.not(retired: true)
    
    # Si el query está vacío, devolver todos los productos
    if query.blank?
      products = products.order(:name).limit(100)
    # Si el query es solo un número, buscar por ID
    elsif query.match?(/^\d+$/)
      products = products.where(id: query).order(:name).limit(10)
    # Si hay texto, filtrar por nombre o autor
    else
      products = products.where("name LIKE ? OR author LIKE ?", "%#{query}%", "%#{query}%")
                      .order(:name)
                      .limit(100)
    end
    
    render json: products.map { |p| 
      { 
        id: p.id, 
        name: p.name, 
        author: p.author,
        stock: p.stock, 
        unit_price: p.unit_price.to_f,
        display: "#{p.name} - #{p.author} - Stock: #{p.stock} - $#{sprintf('%.2f', p.unit_price)}"
      } 
    }
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_sale
      @sale = Sale.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def sale_params
      params.require(:sale).permit(
        :client_name, :client_email,
        sale_items_attributes: [:id, :product_id, :quantity, :unit_price, :_destroy]
      )
    end
end

