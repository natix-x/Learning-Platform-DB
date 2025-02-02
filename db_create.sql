-- tables
-- Table: activities
CREATE TABLE activities (
    activity_id int  NOT NULL,
    description nvarchar(100)  NULL,
    CONSTRAINT activities_pk PRIMARY KEY  (activity_id)
);

-- Table: addresses
CREATE TABLE addresses (
    student_id int  NOT NULL,
    street nvarchar(100)  NOT NULL,
    zip_code nvarchar(6)  NOT NULL,
    city_id int  NOT NULL,
    CONSTRAINT addresses_pk PRIMARY KEY  (student_id)
);

-- Table: administrators
CREATE TABLE administrators (
    user_id int  NOT NULL,
    is_active bit  NOT NULL DEFAULT 0,
    CONSTRAINT administrators_pk PRIMARY KEY  (user_id)
);

-- Table: apprenticeship_days
CREATE TABLE apprenticeship_days (
    apprenticeship_id int  NOT NULL,
    date datetime  NOT NULL,
    CONSTRAINT apprenticeship_days_pk PRIMARY KEY  (apprenticeship_id,date)
);

-- Table: apprenticeship_presence
CREATE TABLE apprenticeship_presence (
    student_id int  NOT NULL,
    apprenticeship_id int  NOT NULL,
    date datetime  NOT NULL,
    is_present bit  NOT NULL DEFAULT 0,
    CONSTRAINT apprenticeship_presence_pk PRIMARY KEY  (student_id,apprenticeship_id)
);

-- Table: cities
CREATE TABLE cities (
    city_id int  NOT NULL,
    city_name nvarchar(100)  NOT NULL,
    country_id int  NOT NULL,
    CONSTRAINT cities_pk PRIMARY KEY  (city_id)
);

-- Table: countries
CREATE TABLE countries (
    country_id int  NOT NULL,
    country_name nvarchar(100)  NOT NULL,
    CONSTRAINT countries_pk PRIMARY KEY  (country_id)
);

-- Table: course_module_meetings
CREATE TABLE course_module_meetings (
    meeting_id int  NOT NULL,
    module_id int  NOT NULL,
    CONSTRAINT course_module_meetings_pk PRIMARY KEY  (meeting_id,module_id)
);

-- Table: course_modules
CREATE TABLE course_modules (
    module_id int  NOT NULL,
    course_id int  NOT NULL,
    module_name int  NOT NULL,
    CONSTRAINT course_modules_pk PRIMARY KEY  (module_id)
);

-- Table: courses
CREATE TABLE courses (
    activity_id int  NOT NULL,
    coordinator_id int  NOT NULL,
    course_name nvarchar(64)  NOT NULL,
    CONSTRAINT courses_pk PRIMARY KEY  (activity_id)
);

-- Table: diplomas
CREATE TABLE diplomas (
    diploma_id int  NOT NULL,
    student_id int  NOT NULL,
    activity_id int  NOT NULL,
    sent_date datetime  NULL,
    status nvarchar(10)  NOT NULL DEFAULT 'not sent',
    receive_date datetime  NULL,
    CONSTRAINT date CHECK (receive_date IS NULL OR receive_date > sent_date),
    CONSTRAINT diplomas_ck_status CHECK (status IN ('not sent', 'sent', 'received')),
    CONSTRAINT diplomas_pk PRIMARY KEY  (diploma_id)
);

-- Table: meeting_presence
CREATE TABLE meeting_presence (
    meeting_id int  NOT NULL,
    student_id int  NOT NULL,
    is_present bit  NOT NULL DEFAULT 0,
    CONSTRAINT meeting_presence_pk PRIMARY KEY  (meeting_id,student_id)
);

-- Table: meeting_presence_make_up
CREATE TABLE meeting_presence_make_up (
    meeting_id int  NOT NULL,
    student_id int  NOT NULL,
    make_up_meeting_id int  NOT NULL,
    CONSTRAINT meeting_presence_make_up_pk PRIMARY KEY  (meeting_id,student_id)
);

-- Table: meeting_translators
CREATE TABLE meeting_translators (
    meeting_id int  NOT NULL,
    translator_id int  NOT NULL,
    language nvarchar(64)  NOT NULL,
    CONSTRAINT meeting_translators_pk PRIMARY KEY  (meeting_id,translator_id)
);

-- Table: meetings
CREATE TABLE meetings (
    meeting_id int  NOT NULL,
    tutor_id int  NOT NULL,
    language nvarchar(64)  NOT NULL DEFAULT 'polski',
    start_time datetime  NOT NULL,
    end_time datetime  NULL,
    activity_id int  NOT NULL,
    CONSTRAINT end_time_ck CHECK (end_time IS NULL OR end_time > start_time),
    CONSTRAINT meetings_pk PRIMARY KEY  (meeting_id)
);

-- Table: meetings_asynchronous
CREATE TABLE meetings_asynchronous (
    meeting_id int  NOT NULL,
    recording_link nvarchar(200)  NOT NULL,
    CONSTRAINT meetings_asynchronous_pk PRIMARY KEY  (meeting_id)
);

-- Table: meetings_in_person
CREATE TABLE meetings_in_person (
    meeting_id int  NOT NULL,
    room_id int  NOT NULL,
    CONSTRAINT meetings_in_person_pk PRIMARY KEY  (meeting_id)
);

-- Table: meetings_synchronous
CREATE TABLE meetings_synchronous (
    meeting_id int  NOT NULL,
    recording_link nvarchar(200)  NULL,
    meeting_link nvarchar(200)  NOT NULL,
    platform_id int  NOT NULL,
    CONSTRAINT meeting_link_ch CHECK (meeting_link LIKE 'http%'),
    CONSTRAINT recording_link_ch CHECK (recording_link LIKE 'http%'),
    CONSTRAINT meetings_synchronous_pk PRIMARY KEY  (meeting_id)
);

-- Table: online_platforms
CREATE TABLE online_platforms (
    platform_id int  NOT NULL,
    platform_name nvarchar(64)  NOT NULL,
    CONSTRAINT online_platforms_ak_1 UNIQUE (platform_name),
    CONSTRAINT online_platforms_pk PRIMARY KEY  (platform_id)
);

-- Table: order_details
CREATE TABLE order_details (
    order_id int  NOT NULL,
    product_id int  NOT NULL,
    price money  NOT NULL,
    CONSTRAINT price_ck CHECK (price > 0),
    CONSTRAINT order_details_pk PRIMARY KEY  (product_id,order_id)
);

-- Table: order_statuses
CREATE TABLE order_statuses (
    status_id int  NOT NULL,
    status_name nvarchar(64)  NOT NULL,
    CONSTRAINT status_name_ck CHECK (status_name IN (    N'Pending',    N'Paid',     N'Processing',     N'Cancelled',      N'Refunded',      N'Received' ) ),
    CONSTRAINT order_statuses_pk PRIMARY KEY  (status_id)
);

-- Table: orders
CREATE TABLE orders (
    order_id int  NOT NULL,
    user_id int  NOT NULL,
    order_date datetime  NOT NULL,
    status_id int  NOT NULL,
    CONSTRAINT order_id PRIMARY KEY  (order_id)
);

-- Table: payment_statuses
CREATE TABLE payment_statuses (
    status_id int  NOT NULL,
    status_name nvarchar(9)  NOT NULL,
    CONSTRAINT status_options CHECK (status_name IN ('pending', 'completed', 'failed')),
    CONSTRAINT payment_statuses_pk PRIMARY KEY  (status_id)
);

-- Table: payments
CREATE TABLE payments (
    payment_id int  NOT NULL,
    order_id int  NOT NULL,
    currency nvarchar(3)  NOT NULL DEFAULT 'PLN',
    payment_date datetime  NOT NULL,
    amount money  NOT NULL,
    status_id int  NOT NULL,
    CONSTRAINT payments_ak_1 UNIQUE (order_id),
    CONSTRAINT amount_positive CHECK (amount > 0),
    CONSTRAINT currency_options CHECK (currency IN ('PLN', 'EUR')),
    CONSTRAINT payments_pk PRIMARY KEY  (payment_id)
);

-- Table: products
CREATE TABLE products (
    product_id int  NOT NULL,
    price money  NOT NULL CHECK (price>=0),
    CONSTRAINT products_pk PRIMARY KEY  (product_id)
);

-- Table: rooms
CREATE TABLE rooms (
    room_id int  NOT NULL,
    room_name nvarchar(64)  NOT NULL,
    capacity int  NOT NULL,
    CONSTRAINT rooms_ak_1 UNIQUE (room_name),
    CONSTRAINT capacity CHECK (capacity>0),
    CONSTRAINT rooms_pk PRIMARY KEY  (room_id)
);

-- Table: shopping_cart
CREATE TABLE shopping_cart (
    product_id int  NOT NULL,
    user_id int  NOT NULL,
    CONSTRAINT shopping_cart_pk PRIMARY KEY  (product_id)
);

-- Table: students
CREATE TABLE students (
    user_id int  NOT NULL,
    is_active bit  NOT NULL DEFAULT 1,
    CONSTRAINT students_pk PRIMARY KEY (user_id)
);

-- Table: studies
CREATE TABLE studies (
    study_id int  NOT NULL,
    capacity int  NOT NULL,
    coordinator_id int  NOT NULL,
    study_name nvarchar(64)  NOT NULL,
    CONSTRAINT capacity CHECK (capacity>0),
    CONSTRAINT studies_pk PRIMARY KEY  (study_id)
);

-- Table: studies_apprenticeships
CREATE TABLE studies_apprenticeships (
    apprenticeship_id int  NOT NULL,
    study_id int  NOT NULL,
    year int  NOT NULL,
    term nvarchar(6)  NOT NULL,
    CONSTRAINT term_ck CHECK (term IN ('Zimowy', 'Letni')),
    CONSTRAINT year_ck CHECK (year > 2000),
    CONSTRAINT studies_apprenticeships_pk PRIMARY KEY  (apprenticeship_id)
);

-- Table: study_module_meetings
CREATE TABLE study_module_meetings (
    meeting_id int  NOT NULL,
    module_id int  NOT NULL,
    CONSTRAINT study_module_meetings_pk PRIMARY KEY  (meeting_id,module_id)
);

-- Table: study_modules
CREATE TABLE study_modules (
    module_id int  NOT NULL,
    study_id int  NOT NULL,
    capacity int  NOT NULL,
    module_name nvarchar(64)  NOT NULL,
    CONSTRAINT capacity_ck CHECK (capacity > 0),
    CONSTRAINT study_modules_pk PRIMARY KEY  (module_id)
);

-- Table: translator_languages
CREATE TABLE translator_languages (
    translator_id int  NOT NULL,
    language nvarchar(64)  NOT NULL,
    CONSTRAINT translator_languages_pk PRIMARY KEY  (translator_id,language)
);

-- Table: translators
CREATE TABLE translators (
    user_id int  NOT NULL,
    is_active bit  NOT NULL DEFAULT 1,
    CONSTRAINT translators_ak_1 UNIQUE (user_id),
    CONSTRAINT translators_pk PRIMARY KEY  (user_id)
);

-- Table: tutors
CREATE TABLE tutors (
    user_id int  NOT NULL,
    is_active bit  NOT NULL DEFAULT 1,
    CONSTRAINT tutors_pk PRIMARY KEY  (user_id)
);

-- Table: users
CREATE TABLE users (
    user_id int  NOT NULL IDENTITY(1, 1),
    email nvarchar(64)  NOT NULL,
    password nvarchar(64)  NOT NULL,
    first_name nvarchar(64)  NOT NULL,
    last_name nvarchar(64)  NOT NULL,
    phone nvarchar(16)  NOT NULL,
    CONSTRAINT unique_email UNIQUE (email),
    CONSTRAINT unique_phone UNIQUE (phone),
    CONSTRAINT email_format CHECK (email LIKE '%@%'),
    CONSTRAINT users_password_format CHECK (PATINDEX('%[A-Z]%', password) > 0 AND PATINDEX('%[a-z]%', password) > 0 AND PATINDEX('%[0-9]%', password) > 0),
    CONSTRAINT users_password_length CHECK (LEN(password) >= 8),
    CONSTRAINT users_pk PRIMARY KEY  (user_id)
);

-- Table: webinar_access
CREATE TABLE webinar_access (
    webinar_id int  NOT NULL,
    user_id int  NOT NULL,
    access_start_date datetime  NOT NULL,
    access_end_date datetime  NULL,
    CONSTRAINT start_before_end CHECK (access_start_date < access_end_date),
    CONSTRAINT webinar_access_pk PRIMARY KEY  (webinar_id,user_id)
);

-- Table: webinars
CREATE TABLE webinars (
    activity_id int  NOT NULL,
    start_time datetime  NOT NULL,
    end_time datetime  NULL,
    recording_link nvarchar(200)  NOT NULL,
    meeting_link nvarchar(200)  NULL,
    platform_id int  NOT NULL,
    tutor_id int  NOT NULL,
    is_paid bit  NOT NULL,
    CONSTRAINT start_before_end CHECK (end_time IS NULL OR end_time > start_time),
    CONSTRAINT webinars_recording_link_format CHECK (recording_link LIKE 'http%'),
    CONSTRAINT webinars_meeting_link_format CHECK (meeting_link LIKE 'http%'),
    CONSTRAINT webinars_pk PRIMARY KEY  (activity_id)
);

-- foreign keys
-- Reference: activities_course_modules (table: course_modules)
ALTER TABLE course_modules ADD CONSTRAINT activities_course_modules
    FOREIGN KEY (module_id)
    REFERENCES activities (activity_id);

-- Reference: activities_courses (table: courses)
ALTER TABLE courses ADD CONSTRAINT activities_courses
    FOREIGN KEY (activity_id)
    REFERENCES activities (activity_id);

-- Reference: activities_diploma (table: diplomas)
ALTER TABLE diplomas ADD CONSTRAINT activities_diploma
    FOREIGN KEY (activity_id)
    REFERENCES activities (activity_id);

-- Reference: activities_webinars (table: webinars)
ALTER TABLE webinars ADD CONSTRAINT activities_webinars
    FOREIGN KEY (activity_id)
    REFERENCES activities (activity_id);

-- Reference: addresses_cities (table: addresses)
ALTER TABLE addresses ADD CONSTRAINT addresses_cities
    FOREIGN KEY (city_id)
    REFERENCES cities (city_id);

-- Reference: apprenticeship_days_apprenticeship_attendance (table: apprenticeship_presence)
ALTER TABLE apprenticeship_presence ADD CONSTRAINT apprenticeship_days_apprenticeship_attendance
    FOREIGN KEY (apprenticeship_id,date)
    REFERENCES apprenticeship_days (apprenticeship_id,date);

-- Reference: apprenticeship_days_studies_apprenticeships (table: apprenticeship_days)
ALTER TABLE apprenticeship_days ADD CONSTRAINT apprenticeship_days_studies_apprenticeships
    FOREIGN KEY (apprenticeship_id)
    REFERENCES studies_apprenticeships (apprenticeship_id);

-- Reference: cities_countries (table: cities)
ALTER TABLE cities ADD CONSTRAINT cities_countries
    FOREIGN KEY (country_id)
    REFERENCES countries (country_id);

-- Reference: course_modules_courses (table: course_modules)
ALTER TABLE course_modules ADD CONSTRAINT course_modules_courses
    FOREIGN KEY (course_id)
    REFERENCES courses (activity_id);

-- Reference: course_modules_module_meetings (table: course_module_meetings)
ALTER TABLE course_module_meetings ADD CONSTRAINT course_modules_module_meetings
    FOREIGN KEY (module_id)
    REFERENCES course_modules (module_id);

-- Reference: meeting_presence_make_up_meeting_presence (table: meeting_presence_make_up)
ALTER TABLE meeting_presence_make_up ADD CONSTRAINT meeting_presence_make_up_meeting_presence
    FOREIGN KEY (meeting_id,student_id)
    REFERENCES meeting_presence (meeting_id,student_id);

-- Reference: meeting_presence_meetings (table: meeting_presence)
ALTER TABLE meeting_presence ADD CONSTRAINT meeting_presence_meetings
    FOREIGN KEY (meeting_id)
    REFERENCES meetings (meeting_id);

-- Reference: meeting_presence_students (table: meeting_presence)
ALTER TABLE meeting_presence ADD CONSTRAINT meeting_presence_students
    FOREIGN KEY (student_id)
    REFERENCES students (user_id);

-- Reference: meeting_translators_meetings (table: meeting_translators)
ALTER TABLE meeting_translators ADD CONSTRAINT meeting_translators_meetings
    FOREIGN KEY (meeting_id)
    REFERENCES meetings (meeting_id);

-- Reference: meetings_activities (table: meetings)
ALTER TABLE meetings ADD CONSTRAINT meetings_activities
    FOREIGN KEY (activity_id)
    REFERENCES activities (activity_id);

-- Reference: meetings_asynchronous_meetings (table: meetings_asynchronous)
ALTER TABLE meetings_asynchronous ADD CONSTRAINT meetings_asynchronous_meetings
    FOREIGN KEY (meeting_id)
    REFERENCES meetings (meeting_id);

-- Reference: meetings_in_person_meetings (table: meetings_in_person)
ALTER TABLE meetings_in_person ADD CONSTRAINT meetings_in_person_meetings
    FOREIGN KEY (meeting_id)
    REFERENCES meetings (meeting_id);

-- Reference: meetings_meeting_presence_make_up (table: meeting_presence_make_up)
ALTER TABLE meeting_presence_make_up ADD CONSTRAINT meetings_meeting_presence_make_up
    FOREIGN KEY (make_up_meeting_id)
    REFERENCES meetings (meeting_id);

-- Reference: meetings_module_meetings (table: course_module_meetings)
ALTER TABLE course_module_meetings ADD CONSTRAINT meetings_module_meetings
    FOREIGN KEY (meeting_id)
    REFERENCES meetings (meeting_id);

-- Reference: meetings_study_meetings (table: study_module_meetings)
ALTER TABLE study_module_meetings ADD CONSTRAINT meetings_study_meetings
    FOREIGN KEY (meeting_id)
    REFERENCES meetings (meeting_id);

-- Reference: meetings_study_studies_modules (table: study_module_meetings)
ALTER TABLE study_module_meetings ADD CONSTRAINT meetings_study_studies_modules
    FOREIGN KEY (module_id)
    REFERENCES study_modules (module_id);

-- Reference: meetings_synchronous_meetings (table: meetings_synchronous)
ALTER TABLE meetings_synchronous ADD CONSTRAINT meetings_synchronous_meetings
    FOREIGN KEY (meeting_id)
    REFERENCES meetings (meeting_id);

-- Reference: meetings_synchronous_online_platforms (table: meetings_synchronous)
ALTER TABLE meetings_synchronous ADD CONSTRAINT meetings_synchronous_online_platforms
    FOREIGN KEY (platform_id)
    REFERENCES online_platforms (platform_id);

-- Reference: meetings_tutors (table: meetings)
ALTER TABLE meetings ADD CONSTRAINT meetings_tutors
    FOREIGN KEY (tutor_id)
    REFERENCES tutors (user_id);

-- Reference: online_platforms_webinars (table: webinars)
ALTER TABLE webinars ADD CONSTRAINT online_platforms_webinars
    FOREIGN KEY (platform_id)
    REFERENCES online_platforms (platform_id);

-- Reference: order_information_orders (table: order_details)
ALTER TABLE order_details ADD CONSTRAINT order_information_orders
    FOREIGN KEY (order_id)
    REFERENCES orders (order_id);

-- Reference: order_statuses_orders (table: orders)
ALTER TABLE orders ADD CONSTRAINT order_statuses_orders
    FOREIGN KEY (status_id)
    REFERENCES order_statuses (status_id);

-- Reference: orders_users (table: orders)
ALTER TABLE orders ADD CONSTRAINT orders_users
    FOREIGN KEY (user_id)
    REFERENCES users (user_id);

-- Reference: payments_orders (table: payments)
ALTER TABLE payments ADD CONSTRAINT payments_orders
    FOREIGN KEY (order_id)
    REFERENCES orders (order_id);

-- Reference: payments_statuses_payments (table: payments)
ALTER TABLE payments ADD CONSTRAINT payments_statuses_payments
    FOREIGN KEY (status_id)
    REFERENCES payment_statuses (status_id);

-- Reference: products_activities (table: products)
ALTER TABLE products ADD CONSTRAINT products_activities
    FOREIGN KEY (product_id)
    REFERENCES activities (activity_id);

-- Reference: products_order_information (table: order_details)
ALTER TABLE order_details ADD CONSTRAINT products_order_information
    FOREIGN KEY (product_id)
    REFERENCES products (product_id);

-- Reference: rooms_meetings_in_person (table: meetings_in_person)
ALTER TABLE meetings_in_person ADD CONSTRAINT rooms_meetings_in_person
    FOREIGN KEY (room_id)
    REFERENCES rooms (room_id);

-- Reference: shopping_cart_products (table: shopping_cart)
ALTER TABLE shopping_cart ADD CONSTRAINT shopping_cart_products
    FOREIGN KEY (product_id)
    REFERENCES products (product_id);

-- Reference: shopping_cart_users (table: shopping_cart)
ALTER TABLE shopping_cart ADD CONSTRAINT shopping_cart_users
    FOREIGN KEY (user_id)
    REFERENCES users (user_id);

-- Reference: students_addresses (table: addresses)
ALTER TABLE addresses ADD CONSTRAINT students_addresses
    FOREIGN KEY (student_id)
    REFERENCES students (user_id);

-- Reference: students_apprenticeship_attendance (table: apprenticeship_presence)
ALTER TABLE apprenticeship_presence ADD CONSTRAINT students_apprenticeship_attendance
    FOREIGN KEY (student_id)
    REFERENCES students (user_id);

-- Reference: students_diploma (table: diplomas)
ALTER TABLE diplomas ADD CONSTRAINT students_diploma
    FOREIGN KEY (student_id)
    REFERENCES students (user_id);

-- Reference: students_users (table: students)
ALTER TABLE students ADD CONSTRAINT students_users
    FOREIGN KEY (user_id)
    REFERENCES users (user_id);

-- Reference: studies_activities (table: studies)
ALTER TABLE studies ADD CONSTRAINT studies_activities
    FOREIGN KEY (study_id)
    REFERENCES activities (activity_id);

-- Reference: studies_apprenticeships_studies (table: studies_apprenticeships)
ALTER TABLE studies_apprenticeships ADD CONSTRAINT studies_apprenticeships_studies
    FOREIGN KEY (study_id)
    REFERENCES studies (study_id);

-- Reference: studies_modules_activities (table: study_modules)
ALTER TABLE study_modules ADD CONSTRAINT studies_modules_activities
    FOREIGN KEY (module_id)
    REFERENCES activities (activity_id);

-- Reference: studies_modules_studies (table: study_modules)
ALTER TABLE study_modules ADD CONSTRAINT studies_modules_studies
    FOREIGN KEY (study_id)
    REFERENCES studies (study_id);

-- Reference: studies_tutors (table: studies)
ALTER TABLE studies ADD CONSTRAINT studies_tutors
    FOREIGN KEY (coordinator_id)
    REFERENCES tutors (user_id);

-- Reference: translator_languages_translators (table: translator_languages)
ALTER TABLE translator_languages ADD CONSTRAINT translator_languages_translators
    FOREIGN KEY (translator_id)
    REFERENCES translators (user_id);

-- Reference: translators_meeting_translators (table: meeting_translators)
ALTER TABLE meeting_translators ADD CONSTRAINT translators_meeting_translators
    FOREIGN KEY (translator_id)
    REFERENCES translators (user_id);

-- Reference: translators_users (table: translators)
ALTER TABLE translators ADD CONSTRAINT translators_users
    FOREIGN KEY (user_id)
    REFERENCES users (user_id);

-- Reference: tutors_courses (table: courses)
ALTER TABLE courses ADD CONSTRAINT tutors_courses
    FOREIGN KEY (coordinator_id)
    REFERENCES tutors (user_id);

-- Reference: tutors_webinars (table: webinars)
ALTER TABLE webinars ADD CONSTRAINT tutors_webinars
    FOREIGN KEY (tutor_id)
    REFERENCES tutors (user_id);

-- Reference: users_administrators (table: administrators)
ALTER TABLE administrators ADD CONSTRAINT users_administrators
    FOREIGN KEY (user_id)
    REFERENCES users (user_id);

-- Reference: users_tutors (table: tutors)
ALTER TABLE tutors ADD CONSTRAINT users_tutors
    FOREIGN KEY (user_id)
    REFERENCES users (user_id);

-- Reference: users_webinar_access (table: webinar_access)
ALTER TABLE webinar_access ADD CONSTRAINT users_webinar_access
    FOREIGN KEY (user_id)
    REFERENCES users (user_id);

-- Reference: webinar_access_webinars (table: webinar_access)
ALTER TABLE webinar_access ADD CONSTRAINT webinar_access_webinars
    FOREIGN KEY (webinar_id)
    REFERENCES webinars (activity_id);

-- End of file.

