CREATE TRIGGER [dbo].[SetWebinarAccessEndDate]
ON [dbo].[webinar_access]
AFTER INSERT
AS
BEGIN
    UPDATE wa
    SET wa.access_end_date = DATEADD(DAY, 30, wa.access_start_date)
    FROM webinar_access wa
    INNER JOIN inserted i
        ON wa.webinar_id = i.webinar_id
        AND wa.user_id = i.user_id;
END;