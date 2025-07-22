--SQL Project- Library Management System N2

SELECT * FROM books;
SELECT * FROM branch;
SELECT * FROM employees;
SELECT * FROM issued_status;
SELECT * FROM members;
SELECT * FROM return_status;

/*
Task 13: Identify Members with Overdue Books 
Write a query to identify members who have overdue books 
(assume a 30-day return period). Display the member's_id, member's name, book title, issue date, and days overdue.
*/

-- issued_status == members == books == return status
--  filter books which have been returned
-- overdut > 30

SELECT 
	ist.issued_member_id,
	m.member_name,
	bk.book_title,
	ist.issued_date,
	CURRENT_DATE - ist.issued_date as over_dues_days
FROM issued_status as ist
JOIN 
members as m
	ON m.member_id = ist.issued_member_id
JOIN 
books as bk
ON bk.isbn = ist.issued_book_isbn
lEFT JOIN
return_status as rs
ON rs.issued_id = ist.issued_id
WHERE 
	rs.return_date IS NULL
	AND 
	(CURRENT_DATE - ist.issued_date)>30
ORDER BY 1

/*
Task 14: Update Book Status on Return
Write a query to update the status of books in the books table to "Yes" when they are returned
(based on entries in the return_status table).
*/

SELECT * FROM issued_status;

SELECT * FROM books
WHERE isbn = '978-0-451-52994-2';

UPDATE books
SET status = 'no'
WHERE isbn = '978-0-451-52994-2';

SELECT * FROM return_status
WHERE issued_id = 'IS130';

--
INSERT INTO return_status(return_id, issued_id, return_date,book_quality)
VALUES
('RS125','IS130',CURRENT_DATE, 'Good');
SELECT * FROM return_status
WHERE issued_id = 'IS130';


-- SQL STORE PROCEDURES FOR AUTOMATION

CREATE OR REPLACE PROCEDURE add_return_records(p_return_id VARCHAR(10),p_issued_id VARCHAR(10),p_book_quality VARCHAR(15))
LANGUAGE plpgsql--Procedural Language/PostgreSQL
AS $$

DECLARE
	v_isbn VARCHAR(50);
	v_book_name VARCHAR(80);
	
BEGIN
	-- all your logic and code
	-- inserting into returns based on users input
	INSERT INTO return_status(return_id, issued_id, return_date,book_quality)
	VALUES
	(p_return_id,p_issued_id,CURRENT_DATE, p_book_quality);

	SELECT 
		issued_book_isbn,
		issued_book_name
		INTO
		v_isbn,
		v_book_name
	FROM issued_status
	WHERE issued_id = p_issued_id;

	UPDATE books
	SET status = 'yes'
	WHERE isbn = v_isbn;

	RAISE NOTICE 'Thank you for returning the book %', v_book_name;

END
$$

-- Testing FUNCTION add_return_records

issued_id = IS135
ISBN = WHERE isbn = '978-0-307-58837-1'

SELECT * FROM books
WHERE isbn =  '978-0-307-58837-1';

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-307-58837-1';

SELECT * FROM return_status

DELETE FROM return_status
WHERE issued_id = 'IS135';

-- calling function
CALL add_return_records('RS138','IS135','Good')

-- calling function
CALL add_return_records('RS139','IS140','Good')

/*
--Task 15: Branch Performance Report:
Create a query that generates a performance report for each branch, 
showing the number of books issued, the number of books returned,
and the total revenue generated from book rentals.
*/

SELECT * FROM branch;

SELECT * FROM issued_status;

SELECT * FROM employees;

SELECT * FROM books;

SELECT * FROM  return_status;


CREATE TABLE branch_reports
AS
SELECT
	b.branch_id,
	b.manager_id,
	COUNT(ist.issued_id) as number_book_issued,
	COUNT(rs.return_id) as number_of_book_return,
	SUM(bk.rental_price) as total_revenue
FROM issued_status as ist
JOIN
employees as e
ON e.emp_id = ist.issued_emp_id
JOIN
branch as b
ON e.branch_id = b.branch_id
JOIN
return_status as rs
ON rs.issued_id = ist.issued_id
JOIN
books as bk
ON ist.issued_book_isbn = bk.isbn
GROUP BY 1,2;

SELECT * FROM branch_reports;

/*
Task 16: CTAS: Create a Table of Active Members
Use the CREATE TABLE AS (CTAS) statement to 
create a new table active_members containing 
members who have issued at least one book in the last 2 months.
*/
CREATE TABLE active_members
AS
SELECT * FROM members
WHERE member_id IN (SELECT 
					DISTINCT issued_member_id
					FROM issued_status
					WHERE
					issued_date > CURRENT_DATE - INTERVAL '2 month'
					)
SELECT * FROM active_members

/*
Task 17: Find Employees with the Most Book Issues Processed
Write a query to find the top 3 employees who have processed 
the most book issues. 
Display the employee name, number of books processed, and their branch.
*/

SELECT
	e.emp_name,
	b.*,
	COUNT(ist.issued_id) as no_book_issued
FROM issued_status as ist
JOIN
employees as e
ON e.emp_id = ist.issued_emp_id
JOIN
branch as b
ON e.branch_id = b.branch_id
GROUP BY 1,2

/*
Task 18: Identify Members Issuing High-Risk Books
Write a query to identify members who have issued books 
more than twice with the status "damaged" in the books table. 
Display the member name, book title, and the number of times they've issued damaged books.
*/


select 
	m.member_name,
	r.book_quality,
	i.issued_book_name,
	count (distinct i.issued_id) as Total_issued
FROM return_status r
	LEFT JOIN issued_status i
	ON r.issued_id = i.issued_id
		LEFT JOIN members m
		ON i.issued_member_id = m.member_id
WHERE r.book_quality = 'Damaged'
GROUP BY 1,2,3


/*
Task 19: Stored Procedure Objective: 

Create a stored procedure to manage the status of books in a library system.

Description: Write a stored procedure that updates the status of a book in the library based on its issuance. 
The procedure should function as follows: The stored procedure should take the book_id as an input parameter. 
The procedure should first check if the book is available (status = 'yes'). 
If the book is available, it should be issued, and the status in the books table should be updated to 'no'. 
If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.
*/


SELECT * FROM books;

SELECT * FROM issued_status;


CREATE OR REPLACE PROCEDURE issue_book(p_issued_id VARCHAR(10), p_issued_member_id VARCHAR(30), p_issued_book_isbn VARCHAR(30), p_issued_emp_id VARCHAR(10))
LANGUAGE plpgsql
AS $$


DECLARE
-- all the variable
	v_status VARCHAR(10);
	

BEGIN
-- all the code
-- check if book is available
	SELECT 
		status 
		INTO
		v_status
	FROM books
	WHERE isbn = p_issued_book_isbn;

	IF  v_status ='yes' THEN

	INSERT INTO issued_status(issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
	VALUES
	(p_issued_id, p_issued_member_id, CURRENT_DATE, p_issued_book_isbn, p_issued_emp_id);

	UPDATE books
		SET status = 'no'
	WHERE isbn = p_issued_book_isbn;

	RAISE NOTICE 'Book records added succesfully for book isbn : %', p_issued_book_isbn;


	ELSE
		RAISE NOTICE 'Sorry to inform you the book you have requested is unavailable book_isbn: %', p_issued_book_isbn;
	END IF;
	

END;

$$


DROP PROCEDURE issue_book(p_issued_id VARCHAR(10), p_issued_member_id VARCHAR(30), p_issued_book_isbn VARCHAR(30), issued_emp_id VARCHAR(10))

SELECT * FROM books;
-- "978-0-553-29698-2"--yes
-- "978-0-375-41398-8" --no

SELECT * FROM issued_status;

CALL issue_book('IS155','C108','978-0-553-29698-2', 'E104')


CALL issue_book('IS156','C108','978-0-375-41398-8', 'E104')

SELECT * FROM books
WHERE isbn = '978-0-375-41398-8'

/*
Task 20: Create Table As Select (CTAS) Objective:
Create a CTAS (Create Table As Select) 
query to identify overdue books and calculate fines.
*/

SELECT 
    m.member_id,
    COUNT(r.return_id IS NULL),
    (DATEDIFF(CURRENT_DATE, i.issued_date) - 30) AS overdue_by_days,
    (DATEDIFF(CURRENT_DATE, i.issued_date) - 30) * 0.50 AS fine
FROM
    members m
        JOIN
    issued_status i ON m.member_id = i.issued_member_id
        JOIN
    books b ON i.issued_book_isbn = b.isbn
        LEFT JOIN
    return_status r ON i.issued_id = r.issued_id
WHERE
    r.return_id IS NULL
        AND (DATEDIFF(CURRENT_DATE, i.issued_date) - 30) > 0
GROUP BY member_id