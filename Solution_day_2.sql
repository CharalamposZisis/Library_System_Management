select * from books;
select * from branch;
select * from employees;
select * from issued_status;
select * from return_status;
select * from members;

--Project Task 
--Task 1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"

insert into books(isbn, book_title, category, rental_price, status, author, publisher)
values 
('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
select * from books;

--Task 2: Update an Existing Member's Address
update members
set member_address = '125 Main St'
where member_id = 'C101' ;
select * from members;


--Task 3: Delete a Record from the Issued Status Table 
-- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.

delete from issued_status
where issued_id = 'IS121';

--Task 4: Retrieve All Books Issued by a Specific Employee 
-- Objective: Select all books issued by the employee with emp_id = 'E101'.
delete from issued_status
where issued_emp_id = 'E101';
select * from issued_status;


--Task 5: List Members Who Have Issued More Than One Book 
--Objective: Use GROUP BY to find members who have issued more than one book.
select * from issued_status;
select issued_member_id
	--count(issued_id) as total_book_issued
from issued_status
group by issued_member_id
having count(issued_member_id) > 1;


--CTAS (Create Table As Select)
--Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**	
create table book_no
SELECT 
	b.isbn,
	b.book_title,
	count(ist.issued_id) as no_issued
FROM books as b
join 
	issued_status as ist
	on ist.issued_book_isbn = b.isbn
group by 1, 2 ;


--Task 7. Retrieve All Books in a Specific Category:
select * from books
where category = 'Classic';


--Task 8: Find Total Rental Income by Category:
select 
	b.category,
	sum(b.rental_price)
from books as b
join 
	issued_status as ist
	on ist.issued_book_isbn = b.isbn
group by 1;



--task 9:List Members Who Registered in the Last 180 Days:
select * from members
where reg_date >= current_date - interval '180 days';

insert into members(member_id, member_name, member_address, reg_date)
values 
('C128','FAt', '145 Main St', '2025-03-20'),
('C129','Nick', '14 FIl St', '2025-05-04');


-- Task 10:List Employees with Their Branch Manager's Name and their branch details:
select 
	e1.*,
	br.branch_id,
	e2.emp_name as manager
from employees as e1
join
	branch as br
	on br.branch_id = e1.branch_id
join employees as e2
on br.manager_id = e2.emp_id


--Task 11. Create a Table of Books with Rental Price Above a Certain Threshold:

create table expensive_books as
select * from books
where rental_price >=5;

--Task 12: Retrieve the List of Books Not Yet Returned
select distinct ist.issued_book_name
from issued_status as ist
left join 
return_status as rs
on rs.return_id = ist.issued_id
where rs.return_id is null;


/*Task 13: Identify Members with Overdue Books
Write a query to identify members who have overdue books (assume a 30-day return period). 
Display the member's_id, member's name, book title, issue date, and days overdue.*/
select 	
	ist.issued_member_id,
	m.member_name,
	bk.book_title,
	ist.issued_date, 
	current_date - ist.issued_date as days_overdue
from issued_status as ist
join members as m
	on m.member_id = ist.issued_member_id
join books as bk
	on bk.isbn = ist.issued_book_isbn
left join return_status as rs
	on rs.issued_id = ist.issued_id
where 
	rs.return_date is null
	and
	(current_date - ist.issued_date) > 30
order by 1;

/*Task 14: Update Book Status on Return
Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).*/
CREATE OR REPLACE PROCEDURE add_return_records(p_return_id VARCHAR(10), p_issued_id VARCHAR(10), p_book_quality VARCHAR(10))
LANGUAGE plpgsql
AS $$

DECLARE
    v_isbn VARCHAR(50);
    v_book_name VARCHAR(80);
    
BEGIN
    -- all your logic and code
    -- inserting into returns based on users input
    INSERT INTO return_status(return_id, issued_id, return_date, book_quality)
    VALUES
    (p_return_id, p_issued_id, CURRENT_DATE, p_book_quality);

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

    RAISE NOTICE 'Thank you for returning the book: %', v_book_name;
    
END;
$$


-- Testing FUNCTION add_return_records

issued_id = IS135
ISBN = WHERE isbn = '978-0-307-58837-1'

SELECT * FROM books
WHERE isbn = '978-0-307-58837-1';

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-307-58837-1';

SELECT * FROM return_status
WHERE issued_id = 'IS135';

-- calling function 
CALL add_return_records('RS138', 'IS135', 'Good');

-- calling function 
CALL add_return_records('RS148', 'IS140', 'Good');



/*Task 15: Branch Performance Report
Create a query that generates a performance report for each branch, showing the number of books issued, 
the number of books returned, and the total revenue generated from book rentals. */
create table  branch_report 
as select
	b.branch_id,
	b.manager_id,
	count(ist.issued_id) as number_book_issued,
	count(rs.return_id) as number_of_book_returned,
	sum(bk.rental_price) as total_revenue
from issued_status as ist
join employees as e
on e.emp_id = ist.issued_emp_id
join branch as b
on b.branch_id = e.branch_id
join return_status as rs
on rs.issued_id = ist.issued_id
join books as bk
on bk.isbn = ist.issued_book_isbn
group by 1,2;

/*Task 16: CTAS: Create a Table of Active Members
Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 2 months.*/
CREATE TABLE active_member
AS select * from members
	where member in(select distinct issued_member_id from issued_status where issued_id >= current_date - interval '2 month');
select * from active_member;
	
/*Task 17: Find Employees with the Most Book Issues Processed
Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.*/
select 
	e.emp_name,
	count(ist.issued_id) as no_book_issued
from issued_status as ist 
join employees as e
on e.emp_id = ist.issued_emp_id
join branch as b
on e.branch_id = b.branch_id
group by e.emp_name;

select * from books;
select * from branch;
select * from employees;
select * from issued_status;
select * from return_status;
select * from members;



/*Task 18: Identify Members Issuing High-Risk Books
Write a query to identify members who have issued books more than twice with the status "damaged" in the books table.
Display the member name, book title, and the number of times they've issued damaged books.*/
create table high_risk_books
as select 
	b.book_title,
	m.member_name,
	count(*) as times_issued_damaged
from issued_status as ist 
join members as m
on m.member_id = ist.issued_member_id
join books as b
on b.isbn = ist.issued_book_isbn
group by b.book_title,
	m.member_name
having count(*) > 2 ;

select * from high_risk_books

/*Task 19: Stored Procedure Objective: Create a stored procedure to manage the status of books in a library system. 
Description: 
Write a stored procedure that updates the status of a book in the library based on its issuance. 

The procedure should function as follows: The stored procedure should take the book_id as an input parameter. 

The procedure should first check if the book is available (status = 'yes'). 

If the book is available, it should be issued, and the status in the books table should be updated to 'no'. 

If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.
*/


CREATE OR REPLACE PROCEDURE issue_book (
    p_issued_id VARCHAR(10),
    p_issued_member_id VARCHAR(30),
    p_issued_book_isbn VARCHAR(50),
    p_issued_emp_id VARCHAR(10)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_status VARCHAR(10);
BEGIN
    -- check the book availability
    SELECT status
    INTO v_status
    FROM books
    WHERE isbn = p_issued_book_isbn;

    IF v_status = 'yes' THEN
        -- insert to issued_status
        INSERT INTO issued_status (
            issued_id, issued_member_id, issued_emp_id, issued_date, issued_book_isbn
        )
        VALUES (
            p_issued_id, p_issued_member_id, p_issued_emp_id, CURRENT_DATE, p_issued_book_isbn
        );

        --Update the book status
        UPDATE books
        SET status = 'no'
        WHERE isbn = p_issued_book_isbn;

        RAISE NOTICE 'Book records added successfully for book isbn: %', p_issued_book_isbn;
    ELSE 
        RAISE NOTICE 'Sorry but this book is not available: %', p_issued_book_isbn;
    END IF;
END;
$$;

