# db/seeds.rb

puts "🔄 Iniciando limpieza de la base de datos..."

SaleItem.delete_all
Sale.delete_all
ProductGenre.delete_all
Product.delete_all
Genre.delete_all
User.delete_all

# =====================================================
# 1. USUARIOS (Únicamente 4)
# =====================================================
puts "👤 Creando usuarios..."

password_base = "12345678"

admin = User.create!(
  nombre: "Admin",
  apellido: "Principal",
  email: "admin@example.com",
  password: password_base,
  role: :administrador
)

gerente = User.create!(
  nombre: "Ana",
  apellido: "Gerente",
  email: "ana.gerente@example.com",
  password: password_base,
  role: :gerente
)

empleado1 = User.create!(
  nombre: "Sofía",
  apellido: "Empleado",
  email: "sofia.empleado@example.com",
  password: password_base,
  role: :empleado
)

empleado2 = User.create!(
  nombre: "Juan",
  apellido: "Empleado",
  email: "juan.empleado@example.com",
  password: password_base,
  role: :empleado
)

puts "Usuarios creados: #{User.count}"

# =====================================================
# 2. GÉNEROS MUSICALES
# =====================================================
puts "🎵 Creando géneros musicales..."

genre_names = [
  "Rock", "Pop", "Punk", "Metal", "Blues", "Jazz", "Folk", 
  "Soul", "Funk", "Reggae", "Hip Hop", "Indie", "Progresivo", 
  "Psicodelia", "Alternativo"
]

genres_by_name = {}
genre_names.each do |name|
  genres_by_name[name] = Genre.create!(name: name)
end

puts "Géneros creados: #{Genre.count}"

# =====================================================
# 3. CONFIGURACIÓN DE PORTADAS Y AUDIOS (Active Storage)
# =====================================================

image_dir = Rails.root.join("app/assets/images/seeds")
audio_dir = Rails.root.join("app/assets/audio/seeds")

audio_by_key = {}
Dir[audio_dir.join("*.mp3")].sort.each do |path|
  key = File.basename(path, ".mp3")
  audio_by_key[key] = Pathname.new(path)
end

# Definición de álbumes comerciales
albums = [
  { key: "Beatles-Abbey-Road",                 artist: "The Beatles",           title: "Abbey Road",                               genres: ["Rock"],                 state: :new_item },
  { key: "Black-Sabbath-Black-Sabbath",         artist: "Black Sabbath",          title: "Black Sabbath",                             genres: ["Metal", "Rock"],        state: :new_item },
  { key: "1971-Whos-Next",                      artist: "The Who",                title: "Who's Next",                               genres: ["Rock"],                 state: :new_item },
  { key: "Bob-Dylan-Freewheelin-Bob-Dylan",     artist: "Bob Dylan",              title: "The Freewheelin' Bob Dylan",               genres: ["Folk", "Rock"],         state: :new_item },
  { key: "Carole-King-Tapestry",                artist: "Carole King",            title: "Tapestry",                                 genres: ["Pop", "Folk"],          state: :new_item },
  { key: "Joy-Division-Unknown-Pleasures",      artist: "Joy Division",           title: "Unknown Pleasures",                         genres: ["Rock", "Alternativo"],  state: :new_item },
  { key: "Pink-Floyd-Dark-Side-of-the-Moon",    artist: "Pink Floyd",             title: "The Dark Side Of The Moon",                 genres: ["Rock", "Progresivo"],   state: :used_item },
  { key: "Notorious-BIG-ready-to-die",          artist: "The Notorious B.I.G.",   title: "Ready To Die",                             genres: ["Hip Hop"],              state: :new_item },
  { key: "Patti-Smith-Horses",                  artist: "Patti Smith",            title: "Horses",                                   genres: ["Rock", "Punk"],         state: :new_item },
  { key: "Nirvana-Nevermind",                   artist: "Nirvana",                title: "Nevermind",                                 genres: ["Rock", "Alternativo"],  state: :new_item },
  { key: "Kendrick-Lamar-To-Pimp-a-Butterfly",  artist: "Kendrick Lamar",          title: "To Pimp A Butterfly",                       genres: ["Hip Hop"],              state: :new_item },
  { key: "Hole-Live-Through-This",              artist: "Hole",                   title: "Live Through This",                         genres: ["Rock", "Alternativo"],  state: :new_item },
  { key: "Beatles-Sgt.-Pepper",                 artist: "The Beatles",           title: "Sgt. Pepper's Lonely Hearts Club Band",     genres: ["Rock", "Psicodelia"],   state: :used_item },
  { key: "Talking-Heads-Remain-In-Light",       artist: "Talking Heads",          title: "Remain In Light",                           genres: ["Rock", "Funk", "Alternativo"], state: :new_item },
  { key: "The Wailers, ‘Catch a Fire’",         artist: "The Wailers",            title: "Catch A Fire",                              genres: ["Reggae"],              state: :new_item },
  { key: "KISS, ‘Alive!’",                      artist: "KISS",                   title: "Alive!",                                   genres: ["Rock"],                 state: :new_item },
  { key: "Led Zeppelin, ‘IV’",                  artist: "Led Zeppelin",           title: "Led Zeppelin IV",                           genres: ["Rock"],                 state: :new_item },
  { key: "Yes-Relayer",                         artist: "Yes",                    title: "Relayer",                                   genres: ["Rock", "Progresivo"],   state: :new_item },
  { key: "Prince-Dirty-Mind",                   artist: "Prince",                 title: "Dirty Mind",                               genres: ["Pop", "Funk"],          state: :new_item },
  { key: "Outkast-Stankonia",                   artist: "Outkast",                title: "Stankonia",                                 genres: ["Hip Hop", "Funk"],      state: :new_item },
  { key: "Rolling-Stones-Sticky-Fingers",       artist: "The Rolling Stones",     title: "Sticky Fingers",                            genres: ["Rock", "Blues"],        state: :used_item },
  { key: "The Rolling Stones, ‘Some Girls’",    artist: "The Rolling Stones",     title: "Some Girls",                               genres: ["Rock"],                 state: :new_item },
  { key: "Sex-Pistols-Never-Mind-The-Bollocks", artist: "Sex Pistols",            title: "Never Mind The Bollocks",                   genres: ["Punk"],                 state: :new_item },
  { key: "Ramones-Ramones",                     artist: "Ramones",                title: "Ramones",                                   genres: ["Punk"],                 state: :new_item },
  { key: "1971-Whos-Next",                      artist: "The Who",                title: "Who's Next (Alt. Edición)",                  genres: ["Rock"],                 state: :new_item }
]

new_products_pool = []

puts "📀 Creando catálogo de productos (25)..."

albums.each do |album|
  image_path = image_dir.join("#{album[:key]}.webp")

  unless File.exist?(image_path)
    puts "⚠️  Falta imagen para #{album[:key]}, se saltea el producto."
    next
  end

  state = album[:state]
  stock = state == :new_item ? rand(15..45) : 1

  product = Product.new(
    name:        album[:title],
    author:      album[:artist],
    description: "Edición especial cargada por Seed para #{album[:artist]} - #{album[:title]}.",
    unit_price:  rand(15.0..90.0).round(2),
    media_type:  [:vinyl, :cd].sample,
    state:       state,
    stock:       stock,
    received_on: Date.today - rand(10..365).days
  )

  chosen_genres = album[:genres].map { |g_name| genres_by_name[g_name] }.compact
  chosen_genres = [genres_by_name.values.sample] if chosen_genres.empty?
  product.genres = chosen_genres.uniq

  product.cover_image.attach(
    io: File.open(image_path),
    filename: File.basename(image_path),
    content_type: "image/webp"
  )

  if state == :used_item
    audio_path = audio_by_key[album[:key]]
    if audio_path && File.exist?(audio_path)
      product.audio_preview.attach(
        io: File.open(audio_path),
        filename: File.basename(audio_path),
        content_type: "audio/mpeg"
      )
    end
  end

  if product.save
    new_products_pool << product if state == :new_item
  end
end

puts "Productos guardados: #{Product.count}"

raise "Error: El catálogo no generó productos válidos para las ventas fijos." if new_products_pool.size < 6
p1, p2, p3, p4, p5, p6 = new_products_pool.first(6)

# =====================================================
# 4. MÓDULO DE VENTAS
# =====================================================
puts "💰 Procesando ventas históricas..."

# Trasladamos los helpers a Lambdas (Procs) para un diseño de script top-level super moderno
parse_day = ->(date_str, hour = 12) { Time.parse("#{date_str} #{hour}:00:00") }
calc_qty  = ->(product, requested) { [requested, product.stock.to_i].min }

sales_data = [
  { date: "2026-01-05", product: p1, qty: 2, cancelled: false, employee: empleado2 },
  { date: "2026-01-10", product: p1, qty: 1, cancelled: true,  employee: empleado2 },

  { date: "2026-01-20", product: p2, qty: 3, cancelled: false, employee: empleado1 },
  { date: "2026-02-03", product: p2, qty: 1, cancelled: false, employee: empleado1 },

  { date: "2026-02-14", product: p3, qty: 2, cancelled: true,  employee: empleado1 },
  { date: "2026-02-28", product: p3, qty: 1, cancelled: false, employee: empleado1 },

  { date: "2026-03-02", product: p4, qty: 2, cancelled: false, employee: empleado1 },
  { date: "2026-03-15", product: p4, qty: 1, cancelled: true,  employee: empleado1 },

  { date: "2026-03-25", product: p5, qty: 3, cancelled: false, employee: empleado2 },
  { date: "2026-04-01", product: p5, qty: 2, cancelled: false, employee: empleado1 },

  { date: "2026-04-12", product: p6, qty: 1, cancelled: true,  employee: empleado1 },
  { date: "2026-04-20", product: p6, qty: 4, cancelled: false, employee: empleado1 }
]

sales_data.each do |data|
  emp = data[:employee]
  current_product = data[:product]

  sale = Sale.new(
    client_name:    "Cliente Demo",
    client_email:   "cliente@demo.com",
    employee_name:  "#{emp.nombre} #{emp.apellido}".strip,
    employee_email: emp.email,
    cancelled:      data[:cancelled],
    cancelled_at:   data[:cancelled] ? parse_day.call(data[:date], 14) : nil, # Ejemplo 14hs para cancelado
    created_at:     parse_day.call(data[:date]),
    updated_at:     parse_day.call(data[:date])
  )

  sale.save!(validate: false)

  SaleItem.create!(
    sale:       sale,
    product:    current_product,
    quantity:   calc_qty.call(current_product, data[:qty]),
    unit_price: current_product.unit_price
  )
end

puts "Ventas registradas: #{Sale.count}"
puts "Items de venta asociados: #{SaleItem.count}"

puts "✅ SEEDS CARGADAS Y CONFIGURADAS"