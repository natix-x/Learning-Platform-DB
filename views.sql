GO
CREATE VIEW [dbo].[AttendanceList] AS
SELECT 
    mp.student_id, 
    u.first_name, 
    u.last_name, 
    m.start_time AS meeting_date, 
    mp.is_present
FROM 
    meeting_presence mp
INNER JOIN 
    students s ON mp.student_id = s.user_id
INNER JOIN 
    users u ON s.user_id = u.user_id
INNER JOIN 
    meetings m ON mp.meeting_id = m.meeting_id;
GO

GO
CREATE VIEW [dbo].[Debtors] AS
SELECT 
    u.user_id,
    u.first_name,
    u.last_name,
    SUM(od.price) AS total_due
FROM 
    orders o
INNER JOIN order_details od ON o.order_id = od.order_id
INNER JOIN products p ON od.product_id = p.product_id
INNER JOIN users u ON o.user_id = u.user_id
LEFT JOIN payments py ON o.order_id = py.order_id
WHERE 
    py.status_id IS NULL -- Nieop³acono
    OR py.status_id <> (SELECT TOP 1 status_id FROM payment_statuses WHERE status_name = 'completed') -- Payment not completed
GROUP BY 
    u.user_id, u.first_name, u.last_name;
GO

GO
CREATE VIEW [dbo].[EventAttendance] AS
SELECT 
    a.activity_id,
    a.description AS activity_name,
    COUNT(DISTINCT mp.student_id) AS total_present,
    (SELECT COUNT(DISTINCT student_id) FROM meeting_presence mp2 
     JOIN meetings m2 ON mp2.meeting_id = m2.meeting_id 
     WHERE m2.activity_id = a.activity_id) - COUNT(DISTINCT mp.student_id) AS total_absent
FROM 
    activities a
JOIN 
    meetings m ON a.activity_id = m.activity_id
LEFT JOIN 
    meeting_presence mp ON m.meeting_id = mp.meeting_id AND mp.is_present = 1
WHERE 
    m.end_time < GETDATE()
GROUP BY 
    a.activity_id, a.description;
GO

GO
CREATE VIEW [dbo].[FinancialReport] AS
SELECT 
    a.activity_id,
    a.description AS activity_name,
    SUM(od.price) AS total_income,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM 
    activities a
INNER JOIN products p ON a.activity_id = p.product_id
INNER JOIN order_details od ON p.product_id = od.product_id
INNER JOIN orders o ON od.order_id = o.order_id
GROUP BY 
    a.activity_id, a.description;
GO


GO
CREATE VIEW [dbo].[OrderDetails] AS
SELECT 
    o.order_id,
    o.user_id,
    o.order_date,
    od.product_id,
    od.price,
    os.status_name AS status
FROM orders o
INNER JOIN order_details od ON o.order_id = od.order_id
INNER JOIN order_statuses os ON o.status_id = os.status_id;
GO

GO
CREATE VIEW [dbo].[OrdersByStudent] AS
SELECT 
    o.order_id,
    o.user_id,
    u.first_name,
    u.last_name,
    o.order_date,
    od.product_id,
    od.price,
    os.status_name AS status
FROM orders o
INNER JOIN users u ON o.user_id = u.user_id
INNER JOIN order_details od ON o.order_id = od.order_id
INNER JOIN order_statuses os ON o.status_id = os.status_id;
GO

GO
CREATE VIEW [dbo].[StudyModules] AS
SELECT 
    sm.module_id, 
    sm.study_id,
    a.description AS activity_name
FROM 
    study_modules sm
INNER JOIN 
    activities a ON sm.module_id = a.activity_id;
GO

GO
CREATE VIEW [dbo].[TimeCollisions] AS
SELECT DISTINCT
    mp1.student_id,
    u.first_name,
    u.last_name,
    m1.start_time AS event_1_start,
    m1.end_time AS event_1_end,
    m2.start_time AS event_2_start,
    m2.end_time AS event_2_end
FROM 
    meeting_presence mp1
INNER JOIN meeting_presence mp2 
    ON mp1.student_id = mp2.student_id 
    AND mp1.meeting_id < mp2.meeting_id -- Unikaj duplikatów
INNER JOIN meetings m1 ON mp1.meeting_id = m1.meeting_id
INNER JOIN meetings m2 ON mp2.meeting_id = m2.meeting_id
INNER JOIN users u ON mp1.student_id = u.user_id
WHERE 
    m1.start_time < m2.end_time -- Sprawdzenie, czy koliduj¹ czasowo
    AND m1.end_time > m2.start_time
    AND m1.start_time > GETDATE(); -- Tylko przysz³e wydarzenia
GO