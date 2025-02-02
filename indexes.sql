CREATE INDEX Meeting_Time
ON meetings (start_time, end_time);

CREATE INDEX Meeting_Time
ON meetings (start_time, end_time);

CREATE INDEX Webinar_Time
ON webinars (start_time, end_time);


CREATE INDEX Product_Price
ON products (price);

CREATE INDEX Studies_Price
ON studies (capacity);

CREATE INDEX MeetingPresence_MeetingID
ON meeting_presence (meeting_id);

CREATE INDEX MeetingPresence_StudentID
ON meeting_presence (student_id);

CREATE INDEX StudyModules_StudyID
ON study_modules (study_id);

CREATE INDEX StudyModules_ModuleID
ON study_modules (module_id);

CREATE INDEX Meetings_TutorID
ON meetings (tutor_id);

CREATE INDEX Meetings_ActivityID
ON meetings (activity_id);

CREATE INDEX OrderDetails_OrderID
ON order_details (order_id);

CREATE INDEX OrderDetails_ProductID
ON order_details (product_id);

CREATE INDEX Orders_UserID
ON orders (user_id);

CREATE INDEX Orders_StatusID
ON orders (status_id);

CREATE INDEX WebinarAccess_WebinarID
ON webinar_access (webinar_id);

CREATE INDEX WebinarAccess_UserID
ON webinar_access (user_id);

CREATE INDEX Addresses_StudentID
ON addresses (student_id);

CREATE INDEX Addresses_CityID
ON addresses (city_id);

CREATE INDEX Students_UserID
ON students (user_id);

CREATE INDEX Diplomas_StudentID
ON diplomas (student_id);

CREATE INDEX Diplomas_ActivityID
ON diplomas (activity_id);

CREATE INDEX MeetingsSynchronous_PlatformID
ON meetings_synchronous (platform_id);