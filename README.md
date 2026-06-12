# 💎 Proyecto Rails – DiscoStore

Desarrollado por Valentín Nuñez, Uziel Juárez Piñeiro y Zoe Eguaras

---

## Tecnologías Principales

### Backend

* Ruby on Rails 8.1
* SQLite3
* Ruby 3.4.7
* Devise → Autenticación de usuarios
* Cancancan → Autorización y roles
* Kaminari → Paginación
* WickedPDF + wkhtmltopdf → Exportación a PDF
* Groupdate → Agrupaciones por fechas
* Chartkick → Gráficos

### Frontend

* Propshaft → Asset pipeline moderno
* Importmap → Gestión de JS sin Node
* Turbo + Stimulus → Interactividad tipo SPA
* Bootstrap 5


## Decisiones de Diseño

### Autenticación y gestión de usuarios

* Se utilizó la gema **Devise** para implementar el inicio y cierre de sesión.
* Se decidió **eliminar la funcionalidad de recuperación de contraseña por email**, ya que no era requerida por el TFI y agregaba complejidad innecesaria al alcance pedido.
* El modelo inicial de *User* fue provisto por Devise y luego adaptado a las necesidades del proyecto.
* Se decidió que los **usuarios tengan borrado físico**, ya que no se especificaba la necesidad de borrado lógico en este caso.
* Como las ventas deben conservar información del empleado aunque este sea eliminado, las ventas almacenan **el nombre y el email del empleado** al momento de la creación.
---

### Permisos

* Para la gestión de permisos según rol (administrador / gerente / empleado), se utilizó la gema **CanCanCan**.
---

### Productos

* Los **productos** tienen **borrado lógico**, siguiendo la indicación explícita del enunciado.
* Para el resto de entidades (usuarios, géneros), el borrado es **físico**.
* Los **géneros** no pueden eliminarse si están asociados al menos a un producto.
* Las **ventas** no se eliminan: solo pueden **cancelarse** y quedan registradas como tal.

#### Estado de los productos (nuevo / usado)

* Se decidió que **una vez creado un producto no se pueda cambiar su estado (nuevo/usado)**.
  El motivo es que cada estado implica reglas distintas (stock fijo en 1, necesidad de audio, manejo del stock, etc.), y permitir el cambio generaba inconsistencias y pérdida de datos.

#### Unicidad de productos

* La unicidad se controla combinando:
  **nombre + autor + estado**.

  * Los productos nuevos deben ser únicos (un solo registro que concentra el stock).
  * Los productos usados pueden repetirse porque representan ejemplares individuales.

#### Stock

* Los productos **nuevos** muestran un **atajo rápido** para incrementar el stock sin entrar en la edición.
* Los productos **usados** siempre tienen stock igual a 1 y este solo cambia por una venta o por cancelarla.
* Los productos dados de baja **no pueden restaurarse**.

#### Imágenes y portada

* La **portada** se carga por separado al crear o editar un producto.
* La galería permite **hasta 5 imágenes adicionales**.
* Al modificar la galería durante la edición, la galería anterior se reemplaza completamente.
* Si la galería no se modifica, las imágenes se borran.
* La portada nunca se borra automáticamente.
---

### Storefront (parte pública)

* La navegación por **género**, **tipo** y **estado** se realiza desde los chips del propio producto.
  Al hacer clic en ellos, se abre la **misma vista de filtros**, pero ya aplicada para ese valor (ej: “ver todos los de Rock”).
* En la parte pública se muestran todos los productos, incluso si su **stock es 0** (solo se excluyen los dados de baja).
* Para mostrar **productos relacionados**, se buscan aquellos que compartan **al menos un género** o **el mismo autor**. Se usa `distinct` y `limit(4)` para evitar duplicados y acotar resultados.
---

### Paginación

* Para la paginación tanto del backstore como del storefront se utilizó **Kaminari**.

## Módulo de Reportes

El sistema cuenta con una sección de reportes separada de la gestión de ventas, que ofrece gráficos claros, legibles y correctamente rotulados. Para su implementaciòn se hizo uso de **Chartkick** y **Groupdate**.

### Acceso y Permisos
1. **Ingresá a la aplicación** como administrador o gerente.
2. **Accedé a la sección "Reportes"** desde el menú de administración (backstore).
3. URL directa: `http://localhost:3000/backstore/reports`

**Permisos requeridos:** Solo **Administradores** y **Gerentes** pueden acceder a esta sección.

---

### Filtros disponibles
Los filtros se pueden **combinar entre sí** para un análisis más detallado y aplican a todas las vistas:
* **Fecha desde / Hasta:** Rango de fechas para las ventas (no incluye fechas futuras).
* **Empleado:** Filtra por el email del vendedor que realizó la venta.
* **Género:** Filtra productos por género musical.
* **Tipo de producto:** Filtra por Vinilo o CD.

---

### Métricas y Gráficos (Ventas Activas)
*De acuerdo a los requerimientos, las ventas canceladas no se incluyen en los siguientes cálculos:*

#### Resumen numérico (Tarjetas)
* **Total recaudado:** Suma de todas las ventas en dinero dentro del período.
* **Cantidad de ventas realizadas:** Número total de transacciones activas.
* **Promedio de importe por venta:** Total recaudado / cantidad de ventas activas.
* **Cantidad de productos vendidos:** Número total de ítems vendidos.

#### Análisis visual (Gráficos interactivos)
* **Ventas por tipo de producto:** Gráfico de pastel (Vinilo vs CD).
* **Ventas por género musical:** Gráfico de columnas con cantidad de ventas por género.
* **Top 5 productos más vendidos:** Gráfico de barras con los 5 productos con mayor volumen de salida.


## Instalación del Proyecto

### 1. Clonar repo

```bash
git clone <url>
cd <nombre-del-proyecto>
```

### 2. Instalar gems

```bash
bundle install
```

### 3. Configurar la base de datos

```bash
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
```

### 4. Ejecutar el servidor

```bash
bin/rails server
```

La app queda disponible en:

`http://localhost:3000`


## Generación de Datos de Prueba

Al ejecutar el comando `db:seed` o configurar la base de datos, se puebla el sistema automáticamente para que los reportes y la tienda tengan datos funcionales e históricos.

### Usuarios de prueba creados

| Email                     | Rol            | Contraseña |
|--------------------------|----------------|------------|
| admin@example.com        | Administrador  | 12345678   |
| ana.gerente@example.com  | Gerente        | 12345678   |
| sofia.empleado@example.com | Empleado     | 12345678   |

### Datos adicionales autogenerados
- **Géneros musicales:** Rock, Pop, Jazz, Metal, Electrónica, entre otros.
- **Productos:** Varios vinilos y CDs asociados a diferentes géneros con portadas y galerías asignadas.
- **Ventas:** Transacciones históricas asignadas a los empleados de prueba para alimentar los gráficos y métricas del módulo de reportes.

