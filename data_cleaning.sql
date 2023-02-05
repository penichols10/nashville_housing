-- Convert datetimes to date
ALTER TABLE Housing
ADD SaleDateConverted Date;

UPDATE Housing
SET SaleDateConverted = CONVERT(Date, SaleDate);

-- Populate Null Addresses
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM dbo.Housing as a
JOIN dbo.Housing as b
ON a.ParcelID = b.ParcelID AND a.[UniqueID ] <> b.[UniqueID ] -- Same ParcelID but different rows
WHERE a.PropertyAddress IS NULL;

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM dbo.Housing as a
JOIN dbo.Housing as b
ON a.ParcelID = b.ParcelID AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;

-- Break out PropertyAddress
SELECT 
	PropertyAddress, 
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) as City
FROM Housing;

ALTER TABLE Housing
ADD 
	PropertyStreet Nvarchar(255),
	PropertyCity Nvarchar(255);

UPDATE Housing
SET 
	PropertyStreet = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1),
	PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress));


-- Break out OwnerAddress
SELECT 
	OwnerAddress, 
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS street,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS city,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS state
FROM Housing;

ALTER TABLE Housing
ADD 
	OwnerStreet Nvarchar(255),
	OwnerCity Nvarchar(255),
	OwnerState Nvarchar(255);

UPDATE Housing
SET
	OwnerStreet = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

-- Split owner first name and last name(s)
ALTER TABLE Housing
ADD
	OwnerFirstNames Nvarchar(255),
	OwnerLastName Nvarchar(255);

UPDATE Housing
	SET OwnerFirstNames = CASE 
		WHEN CHARINDEX(',', OwnerName) = 0 THEN OwnerName
		ELSE SUBSTRING(OwnerName, CHARINDEX(',', OwnerName)+1, LEN(OwnerName))
		END,
	OwnerLastName = CASE 
		WHEN CHARINDEX(',', OwnerName) = 0 THEN OwnerName 
		ELSE SUBSTRING(OwnerName, 1, CHARINDEX(',', OwnerName)-1) 
		END;

-- Change Y and N to Yes and No in SoldAsVacant
SELECT DISTINCT(SoldAsVacant), COUNT(SoldASVacant)
FROM Housing
GROUP BY SoldAsVacant;

SELECT 
	SoldAsVacant,
	CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes' 
		WHEN SoldAsVacant = 'N' THEN 'No'
		Else SoldAsVacant END
FROM Housing;

UPDATE Housing
SET SoldAsVacant = CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes' 
		WHEN SoldAsVacant = 'N' THEN 'No'
		Else SoldAsVacant END;

-- Remove Duplicates
WITH numbered_dups AS(
	SELECT *,
		ROW_NUMBER() OVER(
		PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY ParcelID
		) row_num
	FROM Housing
)
DELETE
FROM numbered_dups
WHERE row_num <> 1;

-- Delete Unused Columns

ALTER TABLE HOUSING
DROP COLUMN SaleDate, OwnerAddress, PropertyAddress;