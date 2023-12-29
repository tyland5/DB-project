/* Create the relations */
CREATE TABLE vendors(
	vendor_id int primary key,
	vendor_name varchar(100),
	open_hours TIME,
	close_hours TIME,
	street varchar(100),
	city varchar(100),
	state_ varchar(100),
	email varchar(100),
	phone_number varchar(12),
	season_op varchar(100)
);

CREATE TABLE products(
	vendor_id int,
	product_name varchar(100),
	price NUMERIC(5,2),
	FOREIGN KEY (vendor_id) REFERENCES vendors(vendor_id) ON DELETE CASCADE,
	primary key(vendor_id, product_name, price)
);

CREATE TABLE markets(
	market_id int primary key,
	market_name varchar(100),
	open_hours TIME,
	close_hours TIME,
	street varchar(100),
	city varchar(100),
	state_ varchar(100),
	phone_number varchar(12),
	season_op varchar(100)
);

CREATE TABLE consumers(
	consumer_id int primary key,
	first_name varchar(100),
	last_name varchar(100),
	phone_number varchar(12),
	email varchar(100)
);

CREATE TABLE vendor_reviews(
	consumer_id int,
	vendor_id int,
	rating NUMERIC(1,0),
	PRIMARY KEY (consumer_id, vendor_id),
	FOREIGN KEY (consumer_id) REFERENCES consumers(consumer_id) ON DELETE CASCADE,
	FOREIGN KEY (vendor_id) REFERENCES vendors(vendor_id) ON DELETE CASCADE
);

CREATE TABLE market_reviews(
	consumer_id int,
	market_id int,
	rating NUMERIC(1,0),
	PRIMARY KEY (consumer_id, market_id),
	FOREIGN KEY (consumer_id) REFERENCES consumers(consumer_id) ON DELETE CASCADE,
	FOREIGN KEY (market_id) REFERENCES markets(market_id) ON DELETE CASCADE
);

CREATE TABLE on_hand(
	market_id int,
	vendor_id int,
	product_name varchar(100),
	price NUMERIC(5,2),
	quantity smallint,
	PRIMARY KEY (market_id, vendor_id, product_name, price),
	FOREIGN KEY (market_id) REFERENCES markets(market_id) ON DELETE CASCADE,
	FOREIGN KEY (vendor_id, product_name, price) REFERENCES products(vendor_id, product_name, price) ON DELETE CASCADE
	ON UPDATE CASCADE
);

CREATE TABLE hosts(
	market_id int,
	vendor_id int,
	PRIMARY KEY (market_id, vendor_id),
	FOREIGN KEY (market_id) REFERENCES markets(market_id) ON DELETE CASCADE,
	FOREIGN KEY (vendor_id) REFERENCES vendors(vendor_id) ON DELETE CASCADE
);

/* Delete the rows in the relations */
DROP TABLE market_reviews;

DROP TABLE on_hand;

DROP TABLE hosts;

DROP TABLE vendor_reviews;

DROP TABLE products;

DROP TABLE vendors;

DROP TABLE markets;

DROP TABLE consumers;

INSERT INTO vendors VALUES (1, 'test');

INSERT INTO products VALUES(10000, 'test', 2.34); /* should give foreign key error */

/* Check relations contents */
SELECT *
FROM vendors;

SELECT * 
FROM markets;

SELECT * 
FROM consumers;

SELECT *
FROM products;

SELECT *
FROM on_hand;

SELECT *
FROM hosts;

SELECT *
FROM market_reviews;

SELECT *
FROM vendor_reviews;

/* 10 Queries */

/* 1. List of Vendors with the Number of Products Each Offers */

SELECT v.vendor_name, COUNT(p.product_name) AS product_count
FROM vendors v
JOIN products p ON v.vendor_id = p.vendor_id
GROUP BY v.vendor_name;


/* 2. Vendors Operating in More Than One Market */
SELECT v.vendor_name, COUNT(DISTINCT h.market_id) AS market_count
FROM vendors v
JOIN hosts h ON v.vendor_id = h.vendor_id
GROUP BY v.vendor_name
HAVING COUNT(DISTINCT h.market_id) > 1;

/* 3. Average Rating of Each Vendor */
SELECT v.vendor_name, AVG(vr.rating) AS average_rating
FROM vendors v
JOIN vendor_reviews vr ON v.vendor_id = vr.vendor_id
GROUP BY v.vendor_name;

/* 4. Markets with the Highest Number of Vendors */
SELECT m.market_name, COUNT(h.vendor_id) AS vendor_count
FROM markets m
JOIN hosts h ON m.market_id = h.market_id
GROUP BY m.market_name
ORDER BY COUNT(h.vendor_id) DESC;

/* 5. Consumers Who Have Rated More Than Three Vendors */
SELECT c.first_name, c.last_name, COUNT(vr.vendor_id) AS ratings_given
FROM consumers c
JOIN vendor_reviews vr ON c.consumer_id = vr.consumer_id
GROUP BY c.consumer_id
HAVING COUNT(vr.vendor_id) > 3;

/* 6. List of Products Available in a Specific Market (e.g., Market ID 1) */
SELECT p.product_name, p.price
FROM products p
JOIN on_hand oh ON p.vendor_id = oh.vendor_id AND p.product_name = oh.product_name
WHERE oh.market_id = 1;

/* 7. Markets Where a Specific Vendor (e.g., Vendor ID 2) Sells Products */
/* unoptimized */
SELECT *
FROM markets m
JOIN hosts h ON m.market_id = h.market_id
WHERE h.vendor_id = 2;

/* optimized */
SELECT m.market_name
FROM markets m
JOIN hosts h ON m.market_id = h.market_id
WHERE h.vendor_id = 2;

/* 8. Vendors Who Have Not Received Any Reviews */
/* Unoptimized */
SELECT vendor_name
FROM vendors
WHERE vendor_id not in(
SELECT DISTINCT vendor_id
FROM vendor_reviews);

/* optimized */
SELECT vendor_name
FROM vendors v
LEFT JOIN vendor_reviews vr ON v.vendor_id = vr.vendor_id
WHERE vr.vendor_id IS NULL;

/* 9. Consumers Who Have Rated Both Markets and Vendors */
SELECT DISTINCT c.first_name, c.last_name
FROM consumers c
JOIN market_reviews mr ON c.consumer_id = mr.consumer_id
JOIN vendor_reviews vr ON c.consumer_id = vr.consumer_id;

/* 10. Total Revenue per Vendor Based on Products Sold */
/* Indexing to optimize query */
CREATE INDEX index_qty
ON on_hand (quantity);

DROP INDEX index_qty;

SELECT market_id, vendor_id, product_name, quantity
FROM on_hand 
WHERE quantity = 0;

/* 11. Top 3 Most Expensive Products Sold by Each Vendor */
SELECT v.vendor_name, p.product_name, p.price
FROM vendors v
JOIN products p ON v.vendor_id = p.vendor_id
WHERE (SELECT COUNT(DISTINCT p2.price)
    FROM products p2
    WHERE p2.price > p.price AND p2.vendor_id = p.vendor_id) < 3
ORDER BY v.vendor_id, p.price DESC;

/* 12. Markets with the Average Product Price Higher than the Overall Average */
SELECT m.market_name, AVG(p.price) AS average_product_price
FROM markets m
JOIN hosts h ON m.market_id = h.market_id
JOIN products p ON h.vendor_id = p.vendor_id
GROUP BY m.market_name
HAVING AVG(p.price) > (SELECT AVG(price) FROM products)
ORDER BY average_product_price DESC;

/* 13. Insert: Adding new market review to relation. should call the trigger */

/* Trigger: Prevent Adding rating number outside 1-5 for Market Rating */
CREATE OR REPLACE function prevent_market_rev()
RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
	RAISE EXCEPTION 'rating can only be values between 1-5';
	RETURN NULL;
END;
$$;

CREATE OR REPLACE TRIGGER market_rev_check BEFORE INSERT ON market_reviews
FOR EACH ROW
WHEN (NEW.rating < 1 OR NEW.rating > 5)
EXECUTE FUNCTION prevent_market_rev();


INSERT INTO market_reviews VALUES (200, 1, 9);
INSERT INTO market_reviews VALUES (200, 1, 3);
SELECT * FROM market_reviews WHERE market_id = 1; -- can use to check

/*14 Delete: Removing Vendors with average rating of 1. Since cascading, it deletes itself from other tables */
DELETE FROM vendors
WHERE vendor_id IN (
	SELECT vendor_id
	FROM vendor_reviews
	GROUP BY vendor_id
	HAVING AVG(rating) = 1
);

SELECT *
FROM on_hand
WHERE vendor_id IN(21, 46, 336, 167, 334, 639, 505);

/* 15. Update Procedure: Update a particular product's price */
CREATE OR REPLACE PROCEDURE update_prod_price(in v_id INT, in p_name VARCHAR(100), in new_price NUMERIC(5,2))
LANGUAGE SQL 
AS $$
UPDATE products 
SET price = new_price
WHERE vendor_id = v_id AND product_name LIKE p_name;
$$;

/*Call the below for the procecure | 0 is the v_id, 'Beets' is p_name, 3.52 is new_price */
CALL update_prod_price(0, 'Beets', 3.52);
SELECT * from products where vendor_id = 0;
SELECT * from on_hand where vendor_id = 0 and product_name = 'Beets';




