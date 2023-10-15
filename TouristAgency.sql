
CREATE TABLE Countries(
Id INT PRIMARY KEY IDENTITY NOT NULL,
[Name] NVARCHAR(50) NOT NULL
)

CREATE TABLE Destinations(
Id INT PRIMARY KEY IDENTITY NOT NULL,
[Name] VARCHAR(50) NOT NULL,
CountryId INT FOREIGN KEY REFERENCES Countries(Id) NOT NULL
)

CREATE TABLE Rooms(
Id INT PRIMARY KEY IDENTITY NOT NULL,
[Type] VARCHAR(40) NOT NULL,
Price DECIMAL (18,2) NOT NULL,
BedCount INT CHECK (BedCount > 0 AND BedCount <= 10) NOT NULL
)

CREATE TABLE Hotels(
Id INT PRIMARY KEY IDENTITY NOT NULL,
[Name] VARCHAR(50) NOT NULL,
DestinationId INT FOREIGN KEY REFERENCES Destinations(Id) NOT NULL
)

CREATE TABLE Tourists(
Id INT PRIMARY KEY IDENTITY NOT NULL,
[Name] NVARCHAR(80) NOT NULL,
PhoneNumber VARCHAR(20) NOT NULL,
Email VARCHAR(80),
CountryId INT FOREIGN KEY REFERENCES Countries(Id)
)

CREATE TABLE Bookings(
Id INT PRIMARY KEY IDENTITY NOT NULL,
ArrivalDate DATETIME2 NOT NULL,
DepartureDate DATETIME2 NOT NULL,
AdultsCount INT CHECK (AdultsCount > 0 AND AdultsCount <= 10) NOT NULL,
ChildrenCount INT CHECK (ChildrenCount >= 0 AND ChildrenCount <= 9) NOT NULL,
TouristId INT FOREIGN KEY REFERENCES Tourists(Id) NOT NULL,
HotelId INT FOREIGN KEY REFERENCES Hotels(Id) NOT NULL,
RoomId INT FOREIGN KEY REFERENCES Rooms(Id) NOT NULL
)

CREATE TABLE HotelsRooms(
HotelId INT FOREIGN KEY REFERENCES Hotels(Id) NOT NULL,
RoomId INT FOREIGN KEY REFERENCES Rooms(Id) NOT NULL,
PRIMARY KEY (HotelId, RoomId)
)
GO

INSERT INTO Tourists ([Name], PhoneNumber, Email, CountryId)
	 VALUES
     ('John Rivers', '653-551-1555', 'john.rivers@example.com', 6),
     ('Adeline Aglaé', '122-654-8726', 'adeline.aglae@example.com', 2),
     ('Sergio Ramirez', '233-465-2876', 's.ramirez@example.com', 3),
     ('Johan Müller', '322-876-9826', 'j.muller@example.com', 7),
     ('Eden Smith', '551-874-2234', 'eden.smith@example.com', 6);

INSERT INTO Bookings (ArrivalDate, DepartureDate, AdultsCount, ChildrenCount, TouristId, HotelId, RoomId)
	 VALUES
     ('2024-03-01', '2024-03-11', 1, 0, 21, 3, 5),
     ('2023-12-28', '2024-01-06', 2, 1, 22, 13, 3),
     ('2023-11-15', '2023-11-20', 1, 2, 23, 19, 7),
     ('2023-12-05', '2023-12-09', 4, 0, 24, 6, 4),
     ('2024-05-01', '2024-05-07', 6, 0, 25, 14, 6);
GO

UPDATE Bookings
SET DepartureDate = DATEADD(day, 1, DepartureDate)
WHERE ArrivalDate >= '2023-12-01' AND ArrivalDate <= '2023-12-31';

UPDATE Tourists
SET Email = NULL
WHERE Name LIKE '%MA%';
GO

DELETE 
  FROM Bookings
 WHERE TouristId IN (SELECT Id 
					   FROM Tourists AS t
					  WHERE [Name] LIKE '%Smith%')

DELETE 
  FROM Tourists
 WHERE Id IN (SELECT Id 
				FROM Tourists 
			   WHERE [Name] LIKE '%Smith%');
GO

    SELECT FORMAT(ArrivalDate, 'yyyy-MM-dd') AS ArrivalDate, AdultsCount, ChildrenCount
      FROM Bookings
      JOIN Rooms ON Bookings.RoomId = Rooms.Id
  ORDER BY Rooms.Price DESC, ArrivalDate;
GO

  SELECT Hotels.Id, Hotels.[Name]
    FROM Hotels
    JOIN HotelsRooms ON Hotels.Id = HotelsRooms.HotelId
    JOIN Rooms ON HotelsRooms.RoomId = Rooms.Id
    JOIN Bookings ON Hotels.Id = Bookings.HotelId
   WHERE Rooms.[Type] = 'VIP Apartment' OR Rooms.[Type] IS NULL
GROUP BY Hotels.Id, Hotels.[Name]
ORDER BY COUNT(Bookings.Id) DESC;
GO

  SELECT Id, [Name], PhoneNumber
    FROM Tourists
   WHERE Id NOT IN (SELECT TouristId FROM Bookings)
ORDER BY [Name] ASC;
GO

SELECT TOP 10
	Hotels.[Name] AS HotelName,
    Destinations.[Name] AS DestinationName,
    Countries.[Name] AS CountryName
FROM
    Bookings
    INNER JOIN Hotels ON Bookings.HotelId = Hotels.Id
    INNER JOIN Destinations ON Hotels.DestinationId = Destinations.Id
    INNER JOIN Countries ON Destinations.CountryId = Countries.Id
WHERE
    Bookings.ArrivalDate < '2023-12-31'
    AND Hotels.Id % 2 = 1
ORDER BY
    Countries.[Name],
    Bookings.ArrivalDate;
GO

  SELECT Hotels.[Name] AS HotelName, Rooms.Price AS RoomPrice
    FROM Tourists
    JOIN Bookings ON Tourists.Id = Bookings.TouristId
    JOIN Hotels ON Bookings.HotelId = Hotels .Id
    JOIN Rooms ON Bookings.RoomId = Rooms.Id
   WHERE Tourists.[Name] NOT LIKE '%EZ'
ORDER BY Rooms.Price DESC;
GO

  SELECT Hotels.[Name], 
		 SUM(Rooms.Price * DATEDIFF(DAY, Bookings.ArrivalDate, Bookings.DepartureDate)) AS HotelRevenue
	FROM Bookings
	JOIN Hotels ON Bookings.HotelId = Hotels.Id
    JOIN Rooms ON Bookings.RoomId = Rooms.Id
GROUP BY Hotels.[Name]
ORDER BY HotelRevenue DESC; --Try with TotalRevenue
GO

CREATE FUNCTION udf_RoomsWithTourists(@roomType VARCHAR(40)) RETURNS INT
BEGIN
	 DECLARE @TotalTourists INT;
      SELECT @TotalTourists = SUM(Bookings.AdultsCount + Bookings.ChildrenCount)
        FROM Bookings
        JOIN Rooms ON Bookings.RoomId = Rooms.Id
       WHERE Rooms.[Type] = @roomType;
          IF @TotalTourists IS NULL --necessary
         SET @TotalTourists = 0; --outcomes check?
      RETURN @TotalTourists;
END;

SELECT dbo.udf_RoomsWithTourists('Double Room');
GO

CREATE PROC usp_SearchByCountry (@country NVARCHAR(50)) AS
BEGIN
       SELECT Tourists.[Name], Tourists.PhoneNumber, Tourists.Email, COUNT(Bookings.Id) AS Bookings
         FROM Tourists
         JOIN Countries ON Tourists.CountryId = Countries.Id
         JOIN Bookings ON Tourists.Id = Bookings.TouristId
        WHERE Countries.[Name] = @country
     GROUP BY Tourists.[Name], Tourists.PhoneNumber, Tourists.Email
     ORDER BY Tourists.[Name], Bookings DESC;
END;

EXEC usp_SearchByCountry 'Greece';
GO