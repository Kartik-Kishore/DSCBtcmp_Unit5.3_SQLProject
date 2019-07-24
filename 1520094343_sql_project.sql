/* Welcome to the SQL mini project. For this project, you will use
Springboard' online SQL platform, which you can log into through the
following link:

https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

Note that, if you need to, you can also download these tables locally.

In the mini project, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */



 
/* Q1: Some of the facilities charge a fee to members, but some do not.
Please list the names of the facilities that do. */

SELECT * FROM Facilities WHERE membercost=0.0;

/*---
Answer: Badminton Court, Table Tennis, Snooker Table, Pool Tables
---*/

/* Q2: How many facilities do not charge a fee to members? */

SELECT count(*) AS TOTAL /* COUNT function counts all rows from the SELECTION, pre-filtered by WHERE, thus returning the number of facilities that have a 0 member cost */

FROM Facilities 

WHERE membercost=0.0;

/*--- Answer: 4 ---*/
 
/* Q3: How can you produce a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost?
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */

SELECT facid,name,membercost,monthlymaintenance 

FROM `Facilities` 

/*

The WHERE clause filters the selection by calling membercost and checking if it less than 20% of monthly maintenance

*/

WHERE membercost < 0.20*monthlymaintenance ;

/* Q4: How can you retrieve the details of facilities with ID 1 and 5?
Write the query without using the OR operator. */

SELECT * FROM `Facilities` WHERE facid IN (1,5); /* create list for filtering facid*/

/* Q5: How can you produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100? Return the name and monthly maintenance of the facilities
in question. */

SELECT name, monthlymaintenance, 

/* 
The following CASE statement that returns a new column that says ‘expensive’ if the monthly maintenance is greater than 1000 and ‘cheap’ if the monthly maintenance is less than or equal to 1000
*/

CASE 
	WHEN monthlymaintenance > 1000 THEN 'expensive'
	ELSE 'cheap'
END AS Cheap_or_Expensive

FROM Facilities ;


/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Do not use the LIMIT clause for your solution. */

/* 
The following query uses a subquery to calculate the maximum joindate. In the uppermost query (the “non-subquery” query), the subquery is joined with the Members table ON those rows in members where the joindate is equal to the max joindate calculated, thus only the last member(s) to sign up are selected. The uppermost query selects all rows from the subquery(max joindate) and creates a new column that concatenates the firstname and surname from the Member table.
*/

SELECT sub . * , CONCAT( mem.firstname,  ' ', mem.surname ) /* Concate first and last name from Members*/

FROM (

	SELECT MAX( joindate ) AS max_joindate  /* Subquery returns maximum joindate*/
	FROM Members
    
)sub

JOIN Members mem ON mem.joindate = sub.max_joindate  /* Query returns only those rows in Members that have the max joindate*/ ;



/* Q7: How can you produce a list of all members who have used a tennis court?
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */

/*
The following query uses two subquery, so I will refer to …

1. the “non-subquery” query as the  `uppermost query`
2. the subquery defined in the uppermost query’s FROM  statement as the `second level query`
3. the inner most nested query as the `innermost query`

The innermost query returns to the second level query the member id and faculty name for all bookings that use a tennis court. This is done by joining the Bookings table with the Facilities table to get the name of the facilities and filtering the results of Bookings by those bookings with a facid of 0 or 1 ( Tennis court 1 and 2 respectively).

Now that we have the member ids and the name of the court for all bookings that booked a tennis court, the second level query returns to the uppermost query  two columns: one with the name of the person on every booking of a tennis court and a the other with the court booked for said bookings This is done by joining the results of the innermost query with the Members table, thereby allowing the concatenation of the first name and last name in Members that corresponds to each row returned from the innermost query
, and returning the facility name from the innermost query to the uppermost query.

Now have the name of the person and the court they  used for every booking of a tennis court, all the uppermost query does is selects rows with distinct person name and facility used pairs and orders by the same.
*/

SELECT DISTINCT sub_ii.MemberName AS MemberName, sub_ii.Court AS Court /* Filters distinct rows from second level query*/

FROM (

	SELECT CONCAT( mem.firstname,  ' ', mem.surname ) AS MemberName, sub.FacName AS Court /* Returns to the uppermost query, the name of the person and the court they used for all rows of the innermost query (which has filtered out bookings that don’t book a tennis court)*/
    
	FROM (

		SELECT bks.memid AS memid, fac.name AS FacName /* returning the member id and facility used (meaning court used) for every booking with a tennis court as done in the WHERE Clause */
		
        FROM Bookings bks
		
        JOIN Facilities fac ON bks.facid = fac.facid /* facid for Bookings and Facilities are the same */
		
        WHERE bks.facid <2 /*This is where the filtering out of bookings of non-tennis court facilities happens. facid 0 and 1 correspond to Tennis courts */
        
	)sub
    
	JOIN Members mem ON sub.memid = mem.memid /* memid for the innermost query and the Members table is the same*/
    
)sub_ii

ORDER BY sub_ii.MemberName, sub_ii.Court; /* Uppermost query: orderly Member name and Court ( meaning Court 1 is first) */


/* Q8: How can you produce a list of bookings on the dsay of 2012-09-14 which
will cost the member (or guest) more than $30? Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

/*
To Answer Question: The query joins Bookings with the Member table and the Facilities table. The cost is calculated twice once in the SELECT clause to create the Cost column and once in the WHERE clause to filter out rows with costs lower than 30 look at COST CALCULATION NOTE for more details. The WHERE clause also filters start time to September 14, 2012. The SELECT statement also creates a Name column by concatenating the first and last name from the Member table and shows the start time for verification that the booking was made in the specified date.

COST CALCULATION NOTE: bks.slots*IF(bks.memid=0,fac.guestcost,fac.membercost) calculates the cost. The basic formula for cost is number of slots booked (bks.slots) times either guestcost if the user is a guest or member cost if the user is a member. The IF statement determines this. It does so by checking if bks.memid is 0 and returning the corresponding cost of the user. That is: if the user is a guest (bks.slot=0) the IF statement returns guestcost, else the user is a member and IF returns membercost. 
*/

SELECT bks.slots*IF(bks.memid=0,fac.guestcost,fac.membercost) AS Cost,/* Calculates cost of user and show in column Cost, look at COST CALCULATION NOTE in comment preceeding query for more details */
	
	CONCAT(mem.firstname,' ',mem.surname) AS Name, 

	bks.starttime AS StartTime
	

FROM Bookings bks

JOIN Members mem ON bks.memid=mem.memid

JOIN Facilities fac ON bks.facid=fac.facid

WHERE starttime>='2012-09-14' AND starttime<'2012-09-15' 

	AND bks.slots*IF(bks.memid=0,fac.guestcost,fac.membercost) >30 /* checks to see if Cost is greater than 30, look at COST CALCULATION NOTE in comment precceding the query for details */

ORDER BY Cost DESC;

/* Q9: This time, produce ththe same result as in Q8, but using a subquery. */
/* 
To Answer Question: This query uses a subquery that joins Books with Members and Facilities to calculate the Cost ( see COST CALCULATION NOTE for details), concatenate the first and last name from Members into Name, return to the StartTime to the upper query and filter rows that do not fall on 09-14-2012 in the WHERE clause.  The upper query then selects all rows from the sub query where the Cost is greater than 30 and orders by Cost.

COST CALCULATION NOTE: bks.slots*IF(bks.memid=0,fac.guestcost,fac.membercost) calculates the cost. The basic formula for cost is number of slots booked (bks.slots) times either guestcost if the user is a guest or member cost if the user is a member. The IF statement determines this. It does so by checking if bks.memid is 0 and returning the corresponding cost of the user. That is: if the user is a guest (bks.slot=0) the IF statement returns guestcost, else the user is a member and IF returns membercost.
*/
SELECT sub.*

FROM (
    
    SELECT bks.slots*IF(bks.memid=0,fac.guestcost,fac.membercost) AS Cost,  /* look at COST CALCULATION NOTE to see details of calculation */
	
	CONCAT(mem.firstname,' ',mem.surname) AS Name, 

	bks.starttime AS StartTime
	

	FROM Bookings bks

	JOIN Members mem ON bks.memid=mem.memid

	JOIN Facilities fac ON bks.facid=fac.facid

	WHERE starttime>='2012-09-14' AND starttime<'2012-09-15' 

    
    )sub /* subquery filters starttime, concats name, returns start time and calculates cost */

WHERE sub.Cost>30

ORDER BY sub.Cost DESC;


/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */

/* 
To Answer Question: In the subquery, Bookings is joined to Members and Facilities. The subquery returns the name of the facility and the Total Revenue. To calculate the total revenue per facility, the subquery groups the row by facility name and sums over the Cost of each row in the group (See COST CALCULATION NOTES for details on cost calculation). The upper query then filters  out the rows with a revenue lower than 1000 in the WHERE clause and orders by Total Revenue (ascending).
*/


SELECT sub.*

FROM (

	SELECT fac.name AS Name, SUM(bks.slots*IF(bks.memid=0,fac.guestcost,fac.membercost)) AS Total_Revenue /* calculating total revenue by summing costs to users over a single facility /* Look at GROUPBY and COST CALCULATION NOTES for details*/
    
	FROM Bookings bks

	JOIN Members mem ON bks.memid=mem.memid

	JOIN Facilities fac ON bks.facid=fac.facid

	GROUP BY name /*facility name*/

    )sub

WHERE sub.Total_Revenue<1000 /*Filtering total revenue*/

ORDER BY sub.Total_Revenue; /* Ordering results*/

/*Answer:
  	  Name 		Total_Revenue 
	Table Tennis 		    180.0 
	Snooker Table 	    240.0 
	Pool Table 		    270.0
*/
