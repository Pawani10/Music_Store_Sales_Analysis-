CREATE TABLE artist (
    artist_id   INT PRIMARY KEY,
    name        VARCHAR(120)
);

CREATE TABLE album (
    album_id    INT PRIMARY KEY,
    title       VARCHAR(160) NOT NULL,
    artist_id   INT NOT NULL REFERENCES artist(artist_id)
);

CREATE TABLE genre (
    genre_id    INT PRIMARY KEY,
    name        VARCHAR(120)
);

CREATE TABLE media_type (
    media_type_id INT PRIMARY KEY,
    name          VARCHAR(120)
);

CREATE TABLE track (
    track_id       INT PRIMARY KEY,
    name           VARCHAR(200) NOT NULL,
    album_id       INT REFERENCES album(album_id),
    media_type_id  INT NOT NULL REFERENCES media_type(media_type_id),
    genre_id       INT REFERENCES genre(genre_id),
    composer       VARCHAR(220),
    milliseconds   INT,
    bytes          INT,
    unit_price     NUMERIC(10, 2)
);

CREATE TABLE playlist (
    playlist_id INT PRIMARY KEY,
    name        VARCHAR(120)
);

CREATE TABLE playlist_track (
    playlist_id INT NOT NULL REFERENCES playlist(playlist_id),
    track_id    INT NOT NULL REFERENCES track(track_id),
    PRIMARY KEY (playlist_id, track_id)
);

CREATE TABLE employee (
    employee_id INT PRIMARY KEY,
    last_name   VARCHAR(80),
    first_name  VARCHAR(80),
    title       VARCHAR(120),
    reports_to  INT REFERENCES employee(employee_id),
    levels      VARCHAR(10),          -- extra column found in CSV, not in diagram
    birthdate   TIMESTAMP,
    hire_date   TIMESTAMP,
    address     VARCHAR(160),
    city        VARCHAR(80),
    state       VARCHAR(80),
    country     VARCHAR(80),
    postal_code VARCHAR(20),
    phone       VARCHAR(30),
    fax         VARCHAR(30),
    email       VARCHAR(120)
);

CREATE TABLE customer (
    customer_id     INT PRIMARY KEY,
    first_name      VARCHAR(80) NOT NULL,
    last_name       VARCHAR(80) NOT NULL,
    company         VARCHAR(160),
    address         VARCHAR(160),
    city            VARCHAR(80),
    state           VARCHAR(80),
    country         VARCHAR(80),
    postal_code     VARCHAR(20),
    phone           VARCHAR(30),
    fax             VARCHAR(30),
    email           VARCHAR(120) NOT NULL,
    support_rep_id  INT REFERENCES employee(employee_id)
);

CREATE TABLE invoice (
    invoice_id           INT PRIMARY KEY,
    customer_id          INT NOT NULL REFERENCES customer(customer_id),
    invoice_date         TIMESTAMP NOT NULL,
    billing_address      VARCHAR(160),
    billing_city         VARCHAR(80),
    billing_state        VARCHAR(80),
    billing_country      VARCHAR(80),
    billing_postal_code  VARCHAR(20),
    total                NUMERIC(10, 2)
);

CREATE TABLE invoice_line (
    invoice_line_id INT PRIMARY KEY,
    invoice_id      INT NOT NULL REFERENCES invoice(invoice_id),
    track_id        INT NOT NULL REFERENCES track(track_id),
    unit_price      NUMERIC(10, 2) NOT NULL,
    quantity        INT NOT NULL
);


ALTER DATABASE "Music_store" SET datestyle = 'DMY, ISO';

-- ANALYSIS QUERIES

-- Q1: Senior-most employee, based on job title
SELECT
    employee_id,
    CONCAT(first_name, ' ', last_name) AS full_name,
    title,
    levels
FROM public.employee
WHERE reports_to IS NULL;


-- Q2: Country with the most invoices generated
SELECT
    billing_country,
    COUNT(total) AS total_invoices
FROM public.invoice
GROUP BY billing_country
ORDER BY COUNT(total) DESC
LIMIT 1;


-- Q3: Top 3 highest invoice totals
SELECT total
FROM public.invoice
ORDER BY total DESC
LIMIT 3;


-- Q4: City with the highest total invoice value 
    billing_city,
    SUM(total) AS invoice_sum
FROM public.invoice
GROUP BY billing_city
ORDER BY SUM(total) DESC
LIMIT 1;


-- Q5: Best customer overall, by total amount spent
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS full_name,
    SUM(i.total) AS sum_invoice,
    i.billing_city
FROM public.customer c
JOIN public.invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, i.billing_city
ORDER BY SUM(i.total) DESC
LIMIT 1;


-- Q6: Email and full name of all Rock genre listeners, alphabetical by email
SELECT DISTINCT
    c.email,
    CONCAT(c.first_name, ' ', c.last_name) AS name
FROM public.customer c
JOIN public.invoice i ON c.customer_id = i.customer_id
JOIN public.invoice_line il ON i.invoice_id = il.invoice_id
WHERE il.track_id IN (
    SELECT t.track_id
    FROM public.track t
    JOIN genre g ON t.genre_id = g.genre_id
    WHERE g.name = 'Rock'
)
ORDER BY c.email;


-- Q7: Top 10 artists with the most Rock tracks 
SELECT
    a.artist_id,
    a.name,
    COUNT(a.artist_id) AS no_of_songs
FROM track t
JOIN album ab ON ab.album_id = t.album_id
JOIN artist a ON a.artist_id = ab.artist_id
JOIN genre g ON g.genre_id = t.genre_id
WHERE g.name = 'Rock'
GROUP BY a.artist_id
ORDER BY COUNT(a.artist_id) DESC
LIMIT 10;


-- Q8: Tracks longer than the average track length, longest first
SELECT
    name,
    milliseconds
FROM public.track
WHERE milliseconds > (
    SELECT ROUND(AVG(milliseconds), 2)
    FROM public.track
)
ORDER BY milliseconds DESC;


-- Q9: For the best-selling artist (by revenue), how much has each customer
--     spent on that artist's tracks specifically?
WITH best_selling_artist AS (
    SELECT
        artist.artist_id AS artist_id,
        artist.name AS artist_name,
        SUM(invoice_line.unit_price * invoice_line.quantity) AS total_sales
    FROM invoice_line
    JOIN track ON track.track_id = invoice_line.track_id
    JOIN album ON album.album_id = track.album_id
    JOIN artist ON artist.artist_id = album.artist_id
    GROUP BY 1
    ORDER BY 3 DESC
    LIMIT 1
)
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    bsa.artist_name,
    SUM(il.unit_price * il.quantity) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1, 2, 3, 4
ORDER BY 5 DESC;


-- Q10: Most popular genre in each country
WITH popular_genre AS (
    SELECT
        COUNT(invoice_line.quantity) AS purchases,
        customer.country,
        genre.name,
        genre.genre_id,
        ROW_NUMBER() OVER (
            PARTITION BY customer.country
            ORDER BY COUNT(invoice_line.quantity) DESC
        ) AS row_no
    FROM invoice_line
    JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
    JOIN customer ON customer.customer_id = invoice.customer_id
    JOIN track ON track.track_id = invoice_line.track_id
    JOIN genre ON genre.genre_id = track.genre_id
    GROUP BY 2, 3, 4
    ORDER BY 2 ASC, 1 DESC
)
SELECT *
FROM popular_genre
WHERE row_no = 1;


-- Q11: Customer who spent the most in each country (ties included)
WITH customer_with_country AS (
    SELECT
        customer.customer_id,
        first_name,
        last_name,
        billing_country,
        SUM(total) AS total_spending,
        RANK() OVER (
            PARTITION BY billing_country
            ORDER BY SUM(total) DESC
        ) AS rank_no
    FROM invoice
    JOIN customer ON customer.customer_id = invoice.customer_id
    GROUP BY 1, 2, 3, 4
    ORDER BY 4 ASC, 5 DESC
)
SELECT *
FROM customer_with_country
WHERE rank_no = 1;