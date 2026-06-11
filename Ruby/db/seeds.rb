puts "🔄 Reset parcial..."

SaleItem.delete_all
Sale.delete_all
User.where(email: [
  "admin@example.com",
  "ana.gerente@example.com",
  "sofia.empleado@example.com"
]).delete_all

# =====================================================
# USUARIOS
# =====================================================
puts "👤 Creando usuarios demo..."

password = "12345678"

admin = User.create!(
  nombre: "Admin",
  apellido: "Principal",
  email: "admin@example.com",
  password: password,
  role: :administrador
)

gerente = User.create!(
  nombre: "Ana",
  apellido: "Gerente",
  email: "ana.gerente@example.com",
  password: password,
  role: :gerente
)

empleado = User.create!(
  nombre: "Sofía",
  apellido: "Empleado",
  email: "sofia.empleado@example.com",
  password: password,
  role: :empleado
)

puts "Usuarios OK"

# =====================================================
# PRODUCTOS BASE
# =====================================================
puts "📀 Seleccionando productos..."

products = Product.active.where(state: :new_item).to_a
raise "No hay productos cargados en la base" if products.size < 6

# 6 productos fijos (determinístico)
p1, p2, p3, p4, p5, p6 = products.first(6)

def day(date_str, hour = 12)
  Time.parse("#{date_str} #{hour}:00:00")
end

# =====================================================
# FUNCIÓN SEGURA PARA QTY
# =====================================================
def safe_qty(product, requested)
  [requested, product.stock.to_i].min
end

# =====================================================
# VENTAS
# =====================================================
puts "💰 Creando ventas..."

sales_data = [
  { date: "2026-01-05", product: p1, qty: 2, cancelled: false },
  { date: "2026-01-10", product: p1, qty: 1, cancelled: true },

  { date: "2026-01-20", product: p2, qty: 3, cancelled: false },
  { date: "2026-02-03", product: p2, qty: 1, cancelled: false },

  { date: "2026-02-14", product: p3, qty: 2, cancelled: true },
  { date: "2026-02-28", product: p3, qty: 1, cancelled: false },

  { date: "2026-03-02", product: p4, qty: 2, cancelled: false },
  { date: "2026-03-15", product: p4, qty: 1, cancelled: true },

  { date: "2026-03-25", product: p5, qty: 3, cancelled: false },
  { date: "2026-04-01", product: p5, qty: 2, cancelled: false },

  { date: "2026-04-12", product: p6, qty: 1, cancelled: true },
  { date: "2026-04-20", product: p6, qty: 4, cancelled: false }
]

sales_data.each do |data|
  sale = Sale.new(
    client_name: "Cliente Demo",
    client_email: "cliente@demo.com",
    employee_name: "#{empleado.nombre} #{empleado.apellido}",
    employee_email: empleado.email,
    cancelled: data[:cancelled],
    cancelled_at: data[:cancelled] ? day(data[:date]) + 2.hours : nil,
    created_at: day(data[:date]),
    updated_at: day(data[:date])
  )

  sale.save!(validate: false)

  SaleItem.create!(
    sale: sale,
    product: data[:product],
    quantity: safe_qty(data[:product], data[:qty]),
    unit_price: data[:product].unit_price
  )
end

puts "Ventas creadas: #{Sale.count}"
puts "Items creados: #{SaleItem.count}"

puts "✅ SEED LISTO"