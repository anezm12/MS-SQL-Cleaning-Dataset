/*

Cleaning Data with SQL Query 

*/ 

select * from [dbo].[Nashville]
go
--- Creating a view to have a snapshot before and after

create view ViewNashville as
select * from [dbo].[Nashville]
go

select * from ViewNashville

---------------------------------------------

/* Standardize Date Format*/


select SaleDate from Nashville

update Nashville
set SaleDate = CONVERT(date, SaleDate)
go

---------------------------------------------

/* Populate Property Address data */

select * from Nashville


select 
	a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, 
	isnull(a.PropertyAddress, b.PropertyAddress) as NewPropertyAddress
from Nashville a 
join Nashville b
	on a.ParcelID = b.ParcelID
	and a.UniqueID <> b.UniqueID
where a.PropertyAddress is null

update a
set PropertyAddress = isnull(a.PropertyAddress, b.PropertyAddress)
from Nashville a 
join Nashville b
	on a.ParcelID = b.ParcelID
	and a.UniqueID <> b.UniqueID
where a.PropertyAddress is null

------------------------------------------------------------------------------------------

/* Breaking out address into individual columns (Address, city, state)*/

select PropertyAddress from Nashville

select 
	substring(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address,
	substring(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, len(PropertyAddress)) as City
from Nashville
go

alter table [dbo].[Nashville]
add PropertySplitAddress nvarchar(250)

alter table [dbo].[Nashville]
add PropertySplitCity nvarchar(250)

update Nashville
set PropertySplitAddress = substring(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)
go

update Nashville
set PropertySplitCity = substring(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, len(PropertyAddress))
go

alter table Nashville
drop column PropertyAddress


-------- Here is another approach to do the same 

select * from Nashville

select [OwnerAddress]
from [dbo].[Nashville]

select
-- parsename divide a string separate by . since with have , separator with use it in conjunction of replace 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) as address,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) as City, 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) as state
from Nashville
GO

alter table Nashville
add OwnerCity nvarchar(250)

update Nashville
set OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
go

alter table Nashville
add OwnerState nvarchar(250)

update Nashville
set OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
go

alter table Nashville
add OwnderAddressSplit nvarchar(250)

update Nashville
set OwnderAddressSplit = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
go

select OwnderAddressSplit, OwnerCity, OwnerState from Nashville

------------------------------------------------------------------------------------------

/* Change 0 and 1 in SoId as Vacant field*/
select SoldAsVacant from Nashville

select distinct ([SoldAsVacant]), count(SoldAsVacant) 
from Nashville
group by SoldAsVacant

select SoldAsVacant, 
case when SoldAsVacant = 0 then 'Yes'
	else 'No'
	end
from Nashville

alter table Nashville
add SoldStatus nvarchar(3)

update Nashville
set SoldStatus = case when SoldAsVacant = 0 then 'Yes'
	else 'No'
	end

select distinct (SoldStatus), count(SoldStatus) 
from Nashville
group by SoldStatus
go

------------------------------------------------------------------------------------------

/* Remove Duplicates */

select * from Nashville

with RowNumCTE as(
select *, 
	ROW_NUMBER() over(partition by ParcelID, PropertyAddress, LegalReference, SaleDate order by UniqueID) row_num
from Nashville )
/*
delete
from RowNumCTE
where row_num > 1
*/
select COUNT(row_num)
from RowNumCTE
where row_num > 1
group by row_num

------------------------------------------------------------------------------------------

/* Delete Unuseed Column */
select * from Nashville


alter table [dbo].[Nashville]
drop column [OwnerAddress], [PropertyAddress], [TaxDistrict]