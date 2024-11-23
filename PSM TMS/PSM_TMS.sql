use tms;

-- Views
CREATE VIEW vw_TourBookingDetails AS
SELECT 
    t.Name AS TourName,
    t.Start_Date,
    t.End_Date,
    COUNT(b.Booking_ID) AS TotalBookings,
    SUM(b.Total_Cost) AS TotalRevenue,
    AVG(b.Total_Cost) AS AverageBookingCost
FROM Tour t
LEFT JOIN Booking b ON t.Tour_ID = b.Tour_ID
GROUP BY t.Name, t.Start_Date, t.End_Date;


SELECT * FROM vw_TourBookingDetails;



CREATE VIEW vw_CustomerBookingHistory AS
SELECT 
    c.Name AS CustomerName,
    COUNT(b.Booking_ID) AS TotalBookings,
    SUM(bl.Billing_Amount) AS TotalSpent,
    MAX(b.Booking_Date) AS LastBookingDate
FROM Customer c
LEFT JOIN Booking b ON c.Customer_ID = b.Customer_ID
LEFT JOIN Billing bl ON b.Booking_ID = bl.Booking_ID
GROUP BY c.Name;


SELECT * FROM vw_CustomerBookingHistory;



CREATE VIEW vw_ServicePerformance AS
SELECT 
    s.Service_Name,
    v.Vendor_Name,
    COUNT(bs.Booking_ID) AS TimesBooked,
    SUM(bs.Total_service_cost) AS TotalRevenue,
    AVG(bs.Total_service_cost) AS AverageRevenue
FROM Service s
JOIN Vendor v ON s.Vendor_ID = v.Vendor_ID
LEFT JOIN Booking_Service bs ON s.Service_ID = bs.Service_ID
GROUP BY s.Service_Name, v.Vendor_Name;


SELECT * FROM vw_ServicePerformance;





-- DML Trigger for Booking Audit
CREATE TABLE BookingAudit (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    BookingID INT,
    Action VARCHAR(10),
    ChangeDate DATETIME,
    UserName VARCHAR(100)
);


CREATE TRIGGER trg_BookingAudit
ON Booking
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO BookingAudit (BookingID, Action, ChangeDate, UserName)
    SELECT i.Booking_ID, 'INSERT', GETDATE(), SYSTEM_USER
    FROM inserted i
    UNION ALL
    SELECT d.Booking_ID, 'DELETE', GETDATE(), SYSTEM_USER
    FROM deleted d
    WHERE NOT EXISTS (SELECT 1 FROM inserted WHERE Booking_ID = d.Booking_ID)
    UNION ALL
    SELECT i.Booking_ID, 'UPDATE', GETDATE(), SYSTEM_USER
    FROM inserted i
    INNER JOIN deleted d ON i.Booking_ID = d.Booking_ID;
END;




-- 3. Test the trigger with INSERT
INSERT INTO Booking (Employee_ID, Customer_ID, Tour_ID, Booking_Date, Total_Cost)
VALUES (1, 1, 1, GETDATE(), 1500.00);



-- 4. Test the trigger with UPDATE
UPDATE Booking
SET Total_Cost = Total_Cost + 100
WHERE Booking_ID = (SELECT MAX(Booking_ID) FROM Booking);



-- 5. Test the trigger with DELETE
DELETE FROM Booking
WHERE Booking_ID = (SELECT MAX(Booking_ID) FROM Booking);


-- 6. View the audit results
SELECT * FROM BookingAudit ORDER BY ChangeDate DESC;


-- 7. More detailed view of audit results with booking details
SELECT 
    ba.AuditID,
    ba.BookingID,
    ba.Action,
    ba.ChangeDate,
    ba.UserName,
    b.Employee_ID,
    b.Customer_ID,
    b.Tour_ID,
    b.Total_Cost
FROM BookingAudit ba
LEFT JOIN Booking b ON ba.BookingID = b.Booking_ID
ORDER BY ba.ChangeDate DESC;


-- To see all triggers in the database:
SELECT * FROM sys.triggers WHERE parent_class = 1; -- 1 means table-level triggers




