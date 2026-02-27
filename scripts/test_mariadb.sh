#!/bin/bash
# ============================================================================
# MariaDB Test Script for Inception Project
# Demonstrates: connection, table creation, inserts, queries, filtering
# ============================================================================

set -e

CONTAINER="inception-mariadb"
DB="wordpress_db"
USER="wp_user"
PASS="dbpassword123"

# Helper: run SQL inside the mariadb container
sql() {
    docker exec "$CONTAINER" mariadb -u"$USER" -p"$PASS" "$DB" -e "$1"
}

echo "============================================"
echo "  MariaDB Demonstration & Test Script"
echo "============================================"
echo ""

# ── 1. Verify connection ────────────────────────────────────────────
echo "▶ 1. Testing connection..."
docker exec "$CONTAINER" mariadb -u"$USER" -p"$PASS" -e "SELECT 'Connection OK' AS status;" 2>/dev/null
echo ""

# ── 2. Show existing databases ──────────────────────────────────────
echo "▶ 2. Listing databases..."
docker exec "$CONTAINER" mariadb -u"$USER" -p"$PASS" -e "SHOW DATABASES;" 2>/dev/null
echo ""

# ── 3. Show WordPress tables (proves WP installed correctly) ────────
echo "▶ 3. WordPress tables in '$DB':"
sql "SHOW TABLES;" 2>/dev/null
echo ""

# ── 4. Show WordPress users (proves WP-CLI setup worked) ───────────
echo "▶ 4. WordPress users:"
sql "SELECT ID, user_login, user_email, user_registered FROM wp_users;" 2>/dev/null
echo ""

# ── 5. Create a demo test table ─────────────────────────────────────
echo "▶ 5. Creating demo table 'test_products'..."
sql "
DROP TABLE IF EXISTS test_products;
CREATE TABLE test_products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    in_stock BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
" 2>/dev/null
echo "   Done."
echo ""

# ── 6. Insert sample data ──────────────────────────────────────────
echo "▶ 6. Inserting sample data..."
sql "
INSERT INTO test_products (name, category, price, in_stock) VALUES
    ('Laptop Pro 15',     'Electronics',  1299.99, TRUE),
    ('Wireless Mouse',    'Electronics',   29.99,  TRUE),
    ('USB-C Hub',         'Electronics',   49.99,  FALSE),
    ('Standing Desk',     'Furniture',    599.00,  TRUE),
    ('Office Chair',      'Furniture',    349.50,  TRUE),
    ('Monitor Arm',       'Furniture',     89.99,  FALSE),
    ('Mechanical KB',     'Electronics',  159.00,  TRUE),
    ('Desk Lamp',         'Furniture',     45.00,  TRUE),
    ('Webcam HD',         'Electronics',   79.99,  TRUE),
    ('Cable Organizer',   'Accessories',   12.99,  TRUE);
" 2>/dev/null
echo "   Inserted 10 rows."
echo ""

# ── 7. SELECT all ──────────────────────────────────────────────────
echo "▶ 7. All products:"
sql "SELECT * FROM test_products;" 2>/dev/null
echo ""

# ── 8. Filter: only Electronics ─────────────────────────────────────
echo "▶ 8. Filter — Electronics only:"
sql "SELECT name, price FROM test_products WHERE category = 'Electronics' ORDER BY price DESC;" 2>/dev/null
echo ""

# ── 9. Filter: in-stock items under 100€ ───────────────────────────
echo "▶ 9. Filter — In-stock items under 100€:"
sql "SELECT name, category, price FROM test_products WHERE in_stock = TRUE AND price < 100 ORDER BY price;" 2>/dev/null
echo ""

# ── 10. Aggregate: average price per category ───────────────────────
echo "▶ 10. Aggregate — Average price per category:"
sql "SELECT category, COUNT(*) AS items, ROUND(AVG(price),2) AS avg_price, ROUND(SUM(price),2) AS total FROM test_products GROUP BY category;" 2>/dev/null
echo ""

# ── 11. Update & verify ────────────────────────────────────────────
echo "▶ 11. Restocking 'USB-C Hub' (was out-of-stock)..."
sql "UPDATE test_products SET in_stock = TRUE WHERE name = 'USB-C Hub';" 2>/dev/null
sql "SELECT name, in_stock FROM test_products WHERE name = 'USB-C Hub';" 2>/dev/null
echo ""

# ── 12. Clean up ───────────────────────────────────────────────────
echo "▶ 12. Cleaning up test table..."
sql "DROP TABLE IF EXISTS test_products;" 2>/dev/null
echo "   Dropped 'test_products'."
echo ""

echo "============================================"
echo "  ✓ All MariaDB tests passed!"
echo "============================================"
echo ""
echo "TIP: For a GUI, open Adminer in your browser:"
echo "  https://mnaumann.42.fr/adminer"
echo "  Server: mariadb | User: $USER | Pass: $PASS | DB: $DB"
