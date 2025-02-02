GO
CREATE PROCEDURE [dbo].[AddCourse]
    @CourseName NVARCHAR(64),
    @Description NVARCHAR(100) = NULL,
    @CoordinatorEmail NVARCHAR(64),
	@Price money,
    @Modules NVARCHAR(MAX) = NULL -- Opcjonalna lista modu³ów rozdzielona przecinami
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @ActivityId INT;
        DECLARE @CoordinatorId INT;

        -- Sprawdzenie, czy kurs o podanej nazwie ju¿ istnieje
        IF EXISTS (SELECT 1 FROM courses WHERE course_name = @CourseName)
        BEGIN
            ROLLBACK TRANSACTION;
            PRINT 'Kurs o podanej nazwie ju¿ istnieje.';
            RETURN -1; -- Kod b³êdu: Kurs ju¿ istnieje
        END;

        -- Dodanie aktywnoœci
        INSERT INTO activities (description)
        VALUES (@Description);

        SET @ActivityId = SCOPE_IDENTITY();

        -- Pobranie ID koordynatora
        SELECT @CoordinatorId = user_id
        FROM users
        WHERE email = @CoordinatorEmail;

        IF @CoordinatorId IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            PRINT 'Nie ma u¿ytkownika o takim adresie email.';
            RETURN -1; -- Kod b³êdu: Brak u¿ytkownika
        END;

        -- Sprawdzenie, czy u¿ytkownik jest aktywnym tutorem
        IF NOT EXISTS (SELECT 1 FROM tutors WHERE user_id = @CoordinatorId AND is_active = 1)
        BEGIN
            ROLLBACK TRANSACTION;
            PRINT 'U¿ytkownik nie jest tutorem lub jest nieaktywny.';
            RETURN -2;
        END;

        -- Dodanie kursu
        INSERT INTO courses (activity_id, coordinator_id, course_name)
        VALUES (@ActivityId, @CoordinatorId, @CourseName);

		
		INSERT INTO products (product_id, price)
           VALUES (@ActivityId, @Price);

        -- Przetwarzanie modu³ów, jeœli podano
        IF @Modules IS NOT NULL AND LEN(@Modules) > 0
        BEGIN
            DECLARE @Module NVARCHAR(64);
            DECLARE @Pos INT = 1;
            DECLARE @Len INT;
            DECLARE @CommaPos INT;
			DECLARE @ModuleId INT;

            SET @Len = LEN(@Modules);

            WHILE @Pos <= @Len
            BEGIN
                SET @CommaPos = CHARINDEX(',', @Modules, @Pos);

                IF @CommaPos = 0
                BEGIN
                    SET @Module = SUBSTRING(@Modules, @Pos, @Len - @Pos + 1);
                    SET @Pos = @Len + 1;
                END
                ELSE
                BEGIN
                    SET @Module = SUBSTRING(@Modules, @Pos, @CommaPos - @Pos);
                    SET @Pos = @CommaPos + 1;
                END;

                SET @Module = LTRIM(RTRIM(@Module));

                -- Dodanie modu³u do tabeli activities (jako modu³)
                INSERT INTO activities DEFAULT VALUES;


                SET @ModuleId = SCOPE_IDENTITY();

                -- Dodanie modu³u do tabeli course_modules
                INSERT INTO course_modules (module_id, course_id, module_name)
                VALUES (@ModuleId, @ActivityId, @Module);
            END;
        END;

        COMMIT TRANSACTION;

        RETURN 0;
    END TRY
    BEGIN CATCH
        PRINT 'Wyst¹pi³ b³¹d: ' + ERROR_MESSAGE();
        ROLLBACK TRANSACTION;
        RETURN -3;
    END CATCH;
END;

GO

GO
CREATE PROCEDURE [dbo].[AddCourseModule]
    @ModuleName NVARCHAR(64),
    @ModuleDescription NVARCHAR(100) = NULL,
    @CourseName NVARCHAR(64)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @CourseId INT;
        DECLARE @ModuleId INT;

        SET @CourseName = LTRIM(RTRIM(@CourseName));
        
        -- Sprawdzenie, czy kurs o podanej nazwie istnieje
        SELECT @CourseId = activity_id FROM courses WHERE course_name = @CourseName;

        IF @CourseId IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            PRINT 'Kurs o takiej nazwie nie istnieje.';
            RETURN -1; 
        END

        -- Sprawdzenie, czy modu³ ju¿ istnieje w ramach tego kursu
        IF EXISTS (SELECT 1 FROM course_modules WHERE course_id = @CourseId AND module_name = @ModuleName)
        BEGIN
            ROLLBACK TRANSACTION;
            PRINT 'Modu³ istnieje ju¿ w ramach tego kursu.';
            RETURN -2;
        END

        -- Dodanie modu³u do tabeli activities (jako modu³)
        INSERT INTO activities (description)
        VALUES (@ModuleDescription);

        SET @ModuleId = SCOPE_IDENTITY();

        -- Dodanie modu³u do tabeli course_modules
        INSERT INTO course_modules (course_id, module_id, module_name)
        VALUES (@CourseId, @ModuleId, @ModuleName);

        COMMIT TRANSACTION;
        RETURN 0;

    END TRY
    BEGIN CATCH
        PRINT 'Wyst¹pi³ b³¹d: ' + ERROR_MESSAGE();
        ROLLBACK TRANSACTION;
        RETURN -3;
    END CATCH
END;
GO

GO
CREATE PROCEDURE [dbo].[AddCourseModuleAsynchronousMeeting]
    @ModuleId INT,
    @TutorId INT,
    @Language NVARCHAR(64) = 'polski',
    @StartTime DATETIME,
    @EndTIme DATETIME = NULL,
    @RecordingLink NVARCHAR(200)
AS
BEGIN
    BEGIN TRY
        PRINT 'Rozpoczynam transakcjê...';
        BEGIN TRANSACTION;

        DECLARE @MeetingID INT;

        -- Sprawdzamy, czy modu³ istnieje
        IF NOT EXISTS(SELECT 1 FROM course_modules WHERE module_id = @ModuleId)
        BEGIN
            PRINT 'Modu³ o id ' + CAST(@ModuleId AS NVARCHAR) + ' nie istnieje.';
            ROLLBACK TRANSACTION;
            RETURN -1; -- Modu³ nie istnieje
        END
        
        -- Sprawdzamy, czy tutor jest aktywny
        IF NOT EXISTS(SELECT 1 FROM tutors WHERE user_id = @TutorId AND is_active = 1)
        BEGIN
            PRINT 'Tutor o id ' + CAST(@TutorId AS NVARCHAR) + ' nie jest aktywny.';
            ROLLBACK TRANSACTION;
            RETURN -2; -- Tutor nieaktywny
        END

        PRINT 'Modu³ i tutor znalezieni, przechodzê do wstawiania danych.';

        -- Dodanie spotkania
        INSERT INTO meetings (tutor_id, language, start_time, end_time, activity_id)
        VALUES (@TutorId, @Language, @StartTime, 
                CASE WHEN @EndTIme IS NULL THEN NULL ELSE @EndTIme END, 
                @ModuleId);

        SET @MeetingId = SCOPE_IDENTITY();

        -- Dodanie szczegó³ów spotkania asynchronicznego
        INSERT INTO meetings_asynchronous (meeting_id, recording_link)
        VALUES (@MeetingId, @RecordingLink);

        COMMIT TRANSACTION;
        PRINT 'Transakcja zakoñczona pomyœlnie.';
        RETURN 0; -- Sukces

    END TRY
    BEGIN CATCH
        PRINT 'B³¹d: ' + ERROR_MESSAGE();
        PRINT 'Numer b³êdu: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Stan transakcji: ' + CAST(@@TRANCOUNT AS NVARCHAR);
        
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        RETURN -3; -- B³¹d w trakcie transakcji
    END CATCH
END;
GO
/****** Object:  StoredProcedure [dbo].[AddOrder]    Script Date: 2.02.2025 12:52:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddOrder]
    @UserId INT,               -- Id u¿ytkownika, który tworzy zamówienie
    @OrderDate DATETIME,       -- Data zamówienia
    @Products NVARCHAR(MAX)    -- Lista Id produktów oddzielona przecinkami
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

		DECLARE @OrderStatusId INT;

        -- Sprawdzenie, czy u¿ytkownik istnieje
        IF NOT EXISTS (SELECT 1 FROM users WHERE user_id = @UserId)
        BEGIN
            ROLLBACK TRANSACTION;
            PRINT 'U¿ytkownik o takim ID nie istnieje.';
            RETURN -1;
        END;

        -- Tworzenie zamówienia
        DECLARE @OrderId INT;

		SELECT @OrderStatusId=status_id
		FROM order_statuses
		WHERE status_name = 'Pending'

        INSERT INTO orders (user_id, order_date, status_id)
        VALUES (@UserId, @OrderDate, @OrderStatusId);

        SET @OrderId = SCOPE_IDENTITY();

        -- Przetwarzanie produktów
        IF @Products IS NOT NULL AND LEN(@Products) > 0
        BEGIN
            DECLARE @ProductId INT;
            DECLARE @ProductPos INT = 1;
            DECLARE @CommaPos INT;
            DECLARE @Product NVARCHAR(MAX);
            DECLARE @Price MONEY;

            WHILE @ProductPos <= LEN(@Products)
            BEGIN
                SET @CommaPos = CHARINDEX(',', @Products, @ProductPos);

                IF @CommaPos = 0
                BEGIN
                    SET @Product = SUBSTRING(@Products, @ProductPos, LEN(@Products) - @ProductPos + 1);
                    SET @ProductPos = LEN(@Products) + 1;
                END
                ELSE
                BEGIN
                    SET @Product = SUBSTRING(@Products, @ProductPos, @CommaPos - @ProductPos);
                    SET @ProductPos = @CommaPos + 1;
                END;

                SET @ProductId = CAST(LTRIM(RTRIM(@Product)) AS INT);

                -- Sprawdzenie, czy produkt istnieje
                SELECT @Price = price FROM products WHERE product_id = @ProductId;
				PRINT 'lol'

                IF @Price IS NULL
                BEGIN
                    ROLLBACK TRANSACTION;
                    PRINT 'Produkt o ID ' + CAST(@ProductId AS NVARCHAR) + ' nie istnieje.';
                    RETURN -2;
                END;

                -- Dodanie szczegó³ów zamówienia
                INSERT INTO order_details (order_id, product_id, price)
                VALUES (@OrderId, @ProductId, @Price);
            END;
        END;

        COMMIT TRANSACTION;
        PRINT 'Zamówienie zosta³o pomyœlnie utworzone.';
        RETURN 0;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT 'Wyst¹pi³ b³¹d: ' + ERROR_MESSAGE();
        RETURN -3;
    END CATCH
END;
GO

GO
CREATE PROCEDURE [dbo].[AddStudent]
   @Email nvarchar(64),
   @Password nvarchar(64),
   @FirstName nvarchar(64),
   @LastName nvarchar(64),
   @Phone nvarchar(16),
   @Street nvarchar(100),
   @ZipCode nvarchar(6),
   @CityName nvarchar(100),
   @CountryName nvarchar(100)
AS
BEGIN
   BEGIN TRY
      -- Rozpoczêcie transakcji
      BEGIN TRANSACTION;

      DECLARE @UserId INT;
      DECLARE @CityId INT;
      DECLARE @CountryId INT;

      -- Sprawdzenie, czy u¿ytkownik ju¿ istnieje
      SELECT @UserId = user_id
      FROM users
      WHERE email = @Email AND phone = @Phone;

      IF @UserId IS NOT NULL
      BEGIN
         -- Sprawdzenie, czy u¿ytkownik jest ju¿ studentem
         IF EXISTS (
            SELECT 1
            FROM students
            WHERE user_id = @UserId
         )
         BEGIN
            -- Wycofanie transakcji, jeœli u¿ytkownik jest ju¿ studentem
            ROLLBACK TRANSACTION;
            RETURN -1; -- Kod b³êdu: u¿ytkownik ju¿ istnieje jako student
         END
         -- U¿ytkownik istnieje, ale nie jest studentem; kontynuujemy proces
      END
      ELSE
      BEGIN
         -- Dodanie nowego u¿ytkownika do tabeli users
         INSERT INTO users (email, password, first_name, last_name, phone)
         VALUES (@Email, @Password, @FirstName, @LastName, @Phone);

         SET @UserId = SCOPE_IDENTITY();  -- Pobranie UserId
      END

      -- Sprawdzenie, czy kraj ju¿ istnieje
      SELECT @CountryId = country_id
      FROM countries
      WHERE country_name = @CountryName;

      -- Jeœli kraj nie istnieje, dodajemy go
      IF @CountryId IS NULL
      BEGIN
         INSERT INTO countries (country_name)
         VALUES (@CountryName);

         SET @CountryId = SCOPE_IDENTITY();  -- Pobranie ID dodanego kraju
      END

      -- Sprawdzenie, czy miasto ju¿ istnieje w danym kraju
      SELECT @CityId = city_id
      FROM cities
      WHERE city_name = @CityName AND country_id = @CountryId;

      -- Jeœli miasto nie istnieje, dodajemy je
      IF @CityId IS NULL
      BEGIN
         INSERT INTO cities (city_name, country_id)
         VALUES (@CityName, @CountryId);

         SET @CityId = SCOPE_IDENTITY();  -- Pobranie ID dodanego miasta
      END

      -- Dodanie u¿ytkownika do tabeli students
      INSERT INTO students (user_id)
      VALUES (@UserId);

      -- Dodanie adresu studenta do tabeli addresses (bez IDENTITY)
      INSERT INTO addresses (student_id, street, zip_code, city_id)
      VALUES (@UserId, @Street, @ZipCode, @CityId);

      -- Zatwierdzenie transakcji po poprawnym zakoñczeniu operacji
      COMMIT TRANSACTION;
      RETURN 0;  -- Zwrócenie kodu sukcesu
   END TRY
   BEGIN CATCH
      -- Wycofanie transakcji w przypadku b³êdu
      PRINT 'Wyst¹pi³ b³¹d: ' + ERROR_MESSAGE();
      ROLLBACK TRANSACTION; 
      RETURN -3;  -- Zwrócenie kodu b³êdu w przypadku wyj¹tku
   END CATCH
END;
GO

GO
CREATE PROCEDURE [dbo].[AddStudy]
    @StudyName NVARCHAR(64),
    @Description NVARCHAR(100) = NULL,
    @CoordinatorEmail NVARCHAR(64),
    @Capacity INT,
    @Price MONEY
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @ActivityId INT;
        DECLARE @CoordinatorId INT;
        DECLARE @EmailPattern NVARCHAR(100) = '%_@__%.__%';

        -- Sprawdzenie poprawnoœci adresu e-mail
        IF PATINDEX(@EmailPattern, @CoordinatorEmail) = 0
        BEGIN
            ROLLBACK TRANSACTION;
            PRINT 'Niepoprawny format adresu e-mail.';
            RETURN -5;
        END

        -- Sprawdzenie, czy studium o podanej nazwie ju¿ istnieje
        IF EXISTS (SELECT 1 FROM studies WHERE study_name = @StudyName)
        BEGIN
            ROLLBACK TRANSACTION;
            PRINT 'Studium o podanej nazwie ju¿ istnieje.';
            RETURN -1; 
        END;

        -- Dodanie aktywnoœci
        INSERT INTO activities (description)
        VALUES (@Description);

        SET @ActivityId = SCOPE_IDENTITY();

        -- Pobranie ID koordynatora
        SELECT @CoordinatorId = user_id
        FROM users
        WHERE email = @CoordinatorEmail;

        IF @CoordinatorId IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            PRINT 'Nie ma u¿ytkownika o takim adresie email.';
            RETURN -2; -- Kod b³êdu: Brak u¿ytkownika
        END;

        -- Sprawdzenie, czy u¿ytkownik jest aktywnym tutorem
        IF NOT EXISTS (SELECT 1 FROM tutors WHERE user_id = @CoordinatorId AND is_active = 1)
        BEGIN
            ROLLBACK TRANSACTION;
            PRINT 'U¿ytkownik nie jest tutorem lub jest nieaktywny.';
            RETURN -3;
        END;

        -- Dodanie studium
        INSERT INTO studies (study_id, capacity, coordinator_id, study_name)
        VALUES (@ActivityId, @Capacity, @CoordinatorId, @StudyName);

        -- Dodanie do tabeli products
        INSERT INTO products (product_id, price)
        VALUES (@ActivityId, @Price);

        COMMIT TRANSACTION;
        RETURN 0;

    END TRY
    BEGIN CATCH
        PRINT 'Wyst¹pi³ b³¹d: ' + ERROR_MESSAGE();
        ROLLBACK TRANSACTION;
        RETURN -4;
    END CATCH
END;
GO

GO
CREATE PROCEDURE [dbo].[AddStudyModule] 
	@ModuleName nvarchar(64),
	@ModuleDescription nvarchar(100) = NULL,
	@StudyName nvarchar(64),
	@Price money
AS
BEGIN
	BEGIN TRANSACTION
	DECLARE @StudyId INT;
	DECLARE @ModuleId INT;

	SET @StudyName = LTRIM(RTRIM(@StudyName));
	SELECT @StudyId = study_id FROM studies WHERE study_name = @StudyName;

	IF @StudyId IS NULL
	BEGIN
		ROLLBACK TRANSACTION
		PRINT 'Studium o takiej nazwie nie istnieje.'
		RETURN -1 
	END

	IF EXISTS (SELECT 1 FROM study_modules WHERE study_id = @StudyId AND module_name= @ModuleName)
	BEGIN
		ROLLBACK TRANSACTION
		PRINT 'Modu³ istnieje ju¿ w ramach tego kursu.'
		RETURN -2
	END

		INSERT INTO activities (description)
        VALUES (@ModuleDescription);

		SET @ModuleId = SCOPE_IDENTITY();

		INSERT INTO study_modules(study_id, module_id, module_name)
		VALUES (@StudyId, @ModuleId, @ModuleName)

		INSERT INTO products(product_id, price)
		VALUES(@ModuleId, @Price)

		COMMIT TRANSACTION
		RETURN 0
END
GO

GO
CREATE PROCEDURE [dbo].[AddTranslator]
   @Email nvarchar(64),
   @Password nvarchar(64),
   @FirstName nvarchar(64),
   @LastName nvarchar(64),
   @Phone nvarchar(16),
   @Languages nvarchar(MAX)  -- Lista jêzyków oddzielonych przecinkami
AS
BEGIN
   BEGIN TRY
      -- Rozpoczêcie transakcji
      BEGIN TRANSACTION;
      PRINT 'Transakcja rozpoczêta.';

      DECLARE @UserId INT;

	  SELECT @UserId = user_id
	  FROM users
	  WHERE email= @Email AND phone = @Phone

	  IF @UserId IS NOT NULL
	  BEGIN
		IF EXISTS (SELECT 1 FROM translators WHERE user_id= @UserId)
		BEGIN
			ROLLBACK TRANSACTION
			RETURN -1
		END
	  END
	  ELSE
	  BEGIN
		INSERT INTO users (email, password, first_name, last_name, phone)
      VALUES (@Email, @Password, @FirstName, @LastName, @Phone);
	  SET @UserId = SCOPE_IDENTITY();  -- Pobranie ID u¿ytkownika
	  END
         IF LEN(@Languages) = 0
         BEGIN
            PRINT 'Brak jêzyków do przypisania.';
            ROLLBACK TRANSACTION;
            RETURN -3;  -- Brak jêzyków
         END

         -- Dodanie jêzyków t³umacza do tabeli translator_languages
         DECLARE @Language nvarchar(64);
         DECLARE @Pos INT = 1;
         DECLARE @Len INT;
         DECLARE @CommaPos INT;

         SET @Len = LEN(@Languages);

         -- Pêtla do dodania jêzyków z listy oddzielonej przecinkami
         WHILE @Pos <= @Len
         BEGIN
            SET @CommaPos = CHARINDEX(',', @Languages, @Pos);

            IF @CommaPos = 0
            BEGIN
               SET @Language = SUBSTRING(@Languages, @Pos, @Len - @Pos + 1);
               SET @Pos = @Len + 1;
            END
            ELSE
            BEGIN
               SET @Language = SUBSTRING(@Languages, @Pos, @CommaPos - @Pos);
               SET @Pos = @CommaPos + 1;
            END

            -- Usuwanie nadmiarowych spacji wokó³ jêzyka
            SET @Language = LTRIM(RTRIM(@Language));

            -- Sprawdzenie, czy jêzyk ju¿ istnieje dla t³umacza
            IF NOT EXISTS (SELECT 1 FROM translator_languages WHERE translator_id = @UserId AND language = @Language)
            BEGIN
               -- Dodanie jêzyka do tabeli translator_languages, tylko jeœli nie ma go jeszcze przypisanego
               INSERT INTO translator_languages (translator_id, language)
               VALUES (@UserId, @Language);
            END
         END

      -- Zatwierdzenie transakcji po poprawnym zakoñczeniu operacji
      COMMIT TRANSACTION;
      PRINT 'Transakcja zakoñczona pomyœlnie.';
      RETURN 0;  -- Sukces
   END TRY
   BEGIN CATCH
      -- Logowanie b³êdu w przypadku wyj¹tku
      PRINT 'Wyst¹pi³ b³¹d: ' + ERROR_MESSAGE();
      -- Zatwierdzenie transakcji po b³êdzie
      IF @@TRANCOUNT > 0
         ROLLBACK TRANSACTION;
      RETURN -4;  -- B³¹d w procesie
   END CATCH
END;
GO

GO

CREATE PROCEDURE [dbo].[AddTutor]
   @Email nvarchar(64),
   @Password nvarchar(64),
   @FirstName nvarchar(64),
   @LastName nvarchar(64),
   @Phone nvarchar(16)
AS
BEGIN
   BEGIN TRY
      -- Rozpoczêcie transakcji
      BEGIN TRANSACTION;

      DECLARE @UserId INT;

	  SELECT @UserId = user_id
	  FROM users
	  WHERE email = @Email AND phone = @Phone;

	  IF @UserId IS NOT NULL
	  BEGIN
		IF EXISTS (SELECT 1 FROM tutors WHERE user_id=@UserId)
		BEGIN
			ROLLBACK TRANSACTION
			RETURN -1
		END
	  END
	  ELSE
	  BEGIN
      -- Dodanie u¿ytkownika do tabeli users
      INSERT INTO users (email, password, first_name, last_name, phone)
      VALUES (@Email, @Password, @FirstName, @LastName, @Phone);

      SET @UserId = SCOPE_IDENTITY();
	  END

      -- Dodanie tutora do tabeli tutors
      INSERT INTO tutors (user_id)
      VALUES (@UserId);

      -- Zatwierdzenie transakcji po poprawnym zakoñczeniu operacji
      COMMIT TRANSACTION;
   END TRY
   BEGIN CATCH
      -- Wycofanie transakcji w przypadku b³êdu
      PRINT 'Wyst¹pi³ b³¹d: ' + ERROR_MESSAGE();
      ROLLBACK TRANSACTION;
   END CATCH
END;
GO

GO

CREATE PROCEDURE [dbo].[AddWebinar]
	@WebinarName nvarchar(64),
	@StartTime datetime,
	@EndTime datetime = NULL,
	@RecordingLink nvarchar(200)=NULL,
	@MeetingLink nvarchar(200),
	@PlatformName nvarchar(64),
	@TutorEmail nvarchar(200),
	@WebinarDescription nvarchar(200)=NULL,
	@Price money	
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
		DECLARE @WebinarId INT;
		DECLARE @TutorId INT;
		DECLARE @PlatformId INT;
		DECLARE @IsPaid BIT;

		IF EXISTS(SELECT 1 FROM webinars WHERE webinar_name= @WebinarName)
		BEGIN
			ROLLBACK TRANSACTION
			RETURN -1
		END

		 -- Pobranie ID wyk³adowcy
        SELECT @TutorId = user_id
        FROM users
        WHERE email = @TutorEmail;

        IF @TutorId IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            PRINT 'Nie ma u¿ytkownika o takim adresie email.';
            RETURN -2; -- Kod b³êdu: Brak u¿ytkownika
        END;

        -- Sprawdzenie, czy u¿ytkownik jest aktywnym tutorem
        IF NOT EXISTS (SELECT 1 FROM tutors WHERE user_id = @TutorId AND is_active = 1)
        BEGIN
            ROLLBACK TRANSACTION;
            PRINT 'U¿ytkownik nie jest tutorem lub jest nieaktywny.';
            RETURN -3;
        END;

		 -- Sprawdzenie, czy wpisana platforma ju¿ istnieje
      SELECT @PlatformId = platform_id
      FROM online_platforms
      WHERE platform_name = @PlatformName;

      -- Jeœli platforma nie istnieje, dodajemy j¹
      IF @PlatformId IS NULL
      BEGIN
         INSERT INTO online_platforms(platform_name)
         VALUES (@PlatformName);

         SET @PlatformId = SCOPE_IDENTITY();  -- Pobranie ID platformy
      END

		-- Dodanie aktywnoœci
        INSERT INTO activities (description)
        VALUES (@WebinarDescription);

		SET @WebinarId = SCOPE_IDENTITY()

		IF @Price > 0
		BEGIN
			SET @IsPaid = 1
			INSERT INTO products (product_id, price)
            VALUES (@WebinarId, @Price);
		END
		ELSE
		BEGIN
			SET @IsPaid = 1
		END


		 -- Dodanie webinaru
        INSERT INTO webinars (activity_id, start_time, end_time, recording_link, meeting_link, tutor_id, is_paid, platform_id)
        VALUES (@WebinarId, @StartTime, @EndTime, @RecordingLink, @MeetingLink, @TutorId, @IsPaid, @PlatformId);

		COMMIT TRANSACTION
		RETURN 0;


	END TRY

	BEGIN CATCH
		PRINT 'Wyst¹pi³ b³¹d: ' + ERROR_MESSAGE();
        ROLLBACK TRANSACTION;
        RETURN -4;
	END CATCH
END
GO

GO
CREATE PROCEDURE [dbo].[ChangeStudentStatus]
	-- Przyk³adowe (dla tutora/translatora/administratora mog³oby byæ to samo)
	@StudentEmail nvarchar(64),
	@StatusOfActiveness BIT -- status na jaki ma zostaæ zmieniony
AS

BEGIN
	BEGIN TRY
		BEGIN TRANSACTION

		DECLARE @StudentId INT;

		 -- Pobranie ID studenta
        SELECT @StudentId = user_id
        FROM users
        WHERE email = @StudentEmail;

        IF @StudentId IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            PRINT 'Nie ma u¿ytkownika o takim adresie email.';
            RETURN -1; -- Kod b³êdu: Brak u¿ytkownika
        END;
		UPDATE students
		SET is_active = @StatusOfActiveness
		WHERE user_id = @StudentId;

		COMMIT TRANSACTION

		RETURN 0

	END TRY

	BEGIN CATCH
		-- Wycofanie transakcji w przypadku b³êdu
      PRINT 'Wyst¹pi³ b³¹d: ' + ERROR_MESSAGE();
      ROLLBACK TRANSACTION; 
      RETURN -3;  -- Zwrócenie kodu b³êdu w przypadku wyj¹tku
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[MarkOrderAsPaid]    Script Date: 2.02.2025 12:52:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[MarkOrderAsPaid]
    @OrderId INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @OrderStatusId INT;

        IF NOT EXISTS (SELECT 1 FROM orders WHERE order_id = @OrderId)
        BEGIN
            ROLLBACK TRANSACTION;
            RETURN -1;
        END

        SELECT @OrderStatusId = status_id
        FROM order_statuses
        WHERE status_name = 'Paid';

        UPDATE orders
        SET status_id = @OrderStatusId
        WHERE order_id = @OrderId;

        COMMIT TRANSACTION;
        RETURN 0;

    END TRY
    BEGIN CATCH
        PRINT 'Wyst¹pi³ b³¹d: ' + ERROR_MESSAGE();
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        RETURN -2;
    END CATCH
END;
GO