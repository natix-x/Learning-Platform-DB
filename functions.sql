CREATE FUNCTION [dbo].[GetMeetingAttendanceList] (@MeetingId INT)
RETURNS TABLE
AS
RETURN
(
    SELECT student_id
    FROM meeting_presence
    WHERE meeting_id = @MeetingId and is_present=1
);
GO
CREATE FUNCTION [dbo].[GetTranslatorLanguages] (@TranslatorId INT)
RETURNS TABLE
AS
RETURN
(
    SELECT language
    FROM translator_languages
    WHERE translator_id = @TranslatorId
);
GO