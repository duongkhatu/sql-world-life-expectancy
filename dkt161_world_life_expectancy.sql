# Data cleaning TASK 1: Handling missing values
# Check for null values
SELECT Row_ID
FROM worldlifexpectancy
WHERE Country IS NULL OR Year IS NULL OR Status IS NULL
    OR Lifeexpectancy IS NULL OR AdultMortality IS NULL OR infantdeaths IS NULL
    OR percentageexpenditure IS NULL OR Measles IS NULL OR BMI IS NULL   
    OR `under-fivedeaths` IS NULL OR Polio IS NULL OR Diphtheria IS NULL
    OR HIVAIDS IS NULL OR GDP IS NULL OR `thinness1-19years` IS NULL
    OR `thinness5-9years` IS NULL OR Schooling IS NULL OR Row_ID IS NULL; # Result: no nulls.

# Check for blank or zero values
# Status
SELECT Country FROM worldlifexpectancy
WHERE Status = ''; # 8 blank values
SELECT Country, Status FROM worldlifexpectancy
GROUP BY Country, Status;

UPDATE worldlifexpectancy
SET Status = CASE
	WHEN Country IN ('Afghanistan', 'Albania', 'Georgia', 'Vanuatu', 'Zambia') THEN 'Developing'
    WHEN Country = 'United States of America' THEN 'Developed'
    END
WHERE Status = '';

# Delete countries that have only one record
SELECT Country, COUNT(*)
FROM worldlifexpectancy
GROUP BY Country HAVING COUNT(*) = 1;
DELETE FROM worldlifexpectancy
WHERE Country IN ('Cook Islands','Dominica','Marshall Islands','Monaco','Nauru','Niue','Palau','Saint Kitts and Nevis','San Marino','Tuvalu');

# Lifeexpectancy
SELECT * FROM worldlifexpectancy
WHERE Lifeexpectancy = 0; # 2 blanks
# Populate the column with the average value of two surrounding years of the corresponding country
WITH w2 AS (SELECT Country, Year, Lifeexpectancy FROM worldlifexpectancy)
UPDATE worldlifexpectancy
SET Lifeexpectancy = CASE
	WHEN Country = 'Afghanistan' THEN (
		SELECT AVG(Lifeexpectancy) FROM w2
		WHERE Year IN (2017, 2019) GROUP BY Country HAVING Country = 'Afghanistan')
	WHEN Country = 'Albania' THEN (
		SELECT AVG(Lifeexpectancy) FROM w2
		WHERE Year IN (2017, 2019) GROUP BY Country HAVING Country = 'Albania')
    END
WHERE Lifeexpectancy = '';  
  
# AdultMortality
SELECT * FROM worldlifexpectancy
WHERE AdultMortality = ''; # No zeros

# infantdeaths
SELECT Country, COUNT(*) FROM worldlifexpectancy
WHERE infantdeaths = ''
GROUP BY Country; # 839 zeros

WITH w2 AS (SELECT Country, AVG(infantdeaths) AS avg_inf FROM worldlifexpectancy WHERE infantdeaths <> '' GROUP BY Country)
UPDATE worldlifexpectancy w
SET infantdeaths = ROUND((SELECT avg_inf FROM w2 WHERE w.Country = w2.Country), 0) # Populate by the average of the corresponding country
WHERE infantdeaths = '';

# percentageexpenditure
SELECT * FROM worldlifexpectancy
WHERE percentageexpenditure = ''; # 607 zeros
# => These are missing values, not true zeros. It's impossible that governments spend zero cents on healthcare.

SELECT Country, COUNT(*), MIN(Year), MAX(Year)
FROM worldlifexpectancy
WHERE percentageexpenditure = '' GROUP BY Country;

# Below are the countries that cannot be filled in by their average because the whole period's values are missing
SELECT Country FROM worldlifexpectancy
WHERE percentageexpenditure = '' GROUP BY Country HAVING COUNT(*) = 16;
# Copy the result for reference below since using a subquery there throws an error:

WITH w2 AS (SELECT Country, AVG(percentageexpenditure) AS avg_pct FROM worldlifexpectancy WHERE percentageexpenditure <> '' GROUP BY Country)
UPDATE worldlifexpectancy w
SET percentageexpenditure = ROUND((SELECT avg_pct FROM w2 WHERE w.Country = w2.Country), 1)
WHERE percentageexpenditure = '' AND Country NOT IN ('Bahamas','Bolivia (Plurinational State of)','Côte d\'Ivoire','Congo','Czechia','Democratic People\'s Republic of Korea','Democratic Republic of the Congo','Egypt','Gambia','Iran (Islamic Republic of)','Kyrgyzstan','Lao People\'s Democratic Republic','Micronesia (Federated States of)','Republic of Korea','Republic of Moldova','Saint Lucia','Saint Vincent and the Grenadines','Slovakia','Somalia','The former Yugoslav republic of Macedonia','United Kingdom of Great Britain and Northern Ireland','United Republic of Tanzania','United States of America','Venezuela (Bolivarian Republic of)','Viet Nam','Yemen');
# Change the other zeros to NULL
UPDATE worldlifexpectancy
SET percentageexpenditure = NULL WHERE percentageexpenditure = '';

# BMI
SELECT * FROM worldlifexpectancy
WHERE BMI = ''; # 32 zeros. South Sudan, Sudan's values are completely missing. These cannot be populated
UPDATE worldlifexpectancy
SET BMI = NULL WHERE BMI = '';

# Under-five deaths: I think it's impossible to have zero deaths of children under five per 1000 live births in a whole year. So I'm gonna change the zeros to 1 if the country is developed and to NULL if the country is developing
UPDATE worldlifexpectancy
SET `under-fivedeaths` = CASE
	WHEN Status = 'Developed' THEN 1
    ELSE NULL
    END
WHERE `under-fivedeaths` = '';

SELECT Country, Year, `under-fivedeaths`
FROM worldlifexpectancy;

# HVIAIDS
SELECT * FROM worldlifexpectancy
WHERE HIVAIDS = ''; # No blanks or zeros

# GDP
SELECT Country, COUNT(*), MIN(Year), MAX(Year) FROM worldlifexpectancy
WHERE GDP = '' GROUP BY Country
; # 448 zeros in total. Most countries have blank GDP in all Years.
SELECT Country, COUNT(*), MIN(Year), MAX(Year) FROM worldlifexpectancy
GROUP BY Country; # For comparison with the previous query

# => Eritrea (19-22), Iraq (07-10), Libya (19-22), Somalia (07-19), South Sudan (07-14), Syrian Arab Republic (15-22) can be populated
WITH w2 AS (SELECT Country, Year, GDP FROM worldlifexpectancy)
UPDATE worldlifexpectancy
SET GDP = CASE
	WHEN Country = 'Eritrea' THEN (SELECT GDP FROM w2 WHERE Country = 'Eritrea' AND Year = 2018)
    WHEN Country = 'Iraq' THEN (SELECT GDP FROM w2 WHERE Country = 'Iraq' AND Year = 2011)
    WHEN Country = 'Libya' THEN (SELECT GDP FROM w2 WHERE Country = 'Libya' AND Year = 2018)
    WHEN Country = 'Somalia' THEN (SELECT GDP FROM w2 WHERE Country = 'Somalia' AND Year = 2020)
    WHEN Country = 'South Sudan' THEN (SELECT GDP FROM w2 WHERE Country = 'South Sudan' AND Year = 2015)
    WHEN Country = 'Syrian Arab Republic' THEN (SELECT GDP FROM w2 WHERE Country = 'Syrian Arab Republic' AND Year = 2014)
    ELSE GDP
    END
WHERE GDP = '';

# Idk why the two below cannot be populated by the query above, so I did it separately (filled in by the closest year's GDP):
UPDATE worldlifexpectancy SET GDP = 510 WHERE Country = 'Sao Tome and Principe' AND Year = 2007;
UPDATE worldlifexpectancy SET GDP = 2183 WHERE Country = 'Papua New Guinea' AND Year = 2022;

UPDATE worldlifexpectancy SET GDP = NULL WHERE GDP = '';

# thinness => can't be populated
SELECT * FROM worldlifexpectancy
WHERE `thinness1-19years` = ''; # 32 zeros. South Sudan, Sudan's values are completely missing
SELECT * FROM worldlifexpectancy
WHERE `thinness5-9years` = ''; # Same as above

UPDATE worldlifexpectancy SET `thinness1-19years` = NULL WHERE `thinness1-19years` = '';
UPDATE worldlifexpectancy SET `thinness5-9years` = NULL WHERE `thinness5-9years` = '';

# Schooling
SELECT Country, COUNT(*), MIN(Year), MAX(Year) FROM worldlifexpectancy
WHERE Schooling = ''
GROUP BY Country; # 191 zeros

# Antigua and Barbuda (07-12), Bosnia and Herzegovina (07), Equatorial Guinea (07), Micronesia (Federated States of) (07), Montenegro (07-10), South Sudan (07-17), Timor-Leste (07), Turkmenistan (07) can be populated
WITH w2 AS (SELECT Country, Year, Schooling FROM worldlifexpectancy)
UPDATE worldlifexpectancy
SET Schooling = CASE
	WHEN Country = 'Antigua and Barbuda' THEN (SELECT Schooling FROM w2 WHERE Country = 'Antigua and Barbuda' AND Year = 2013)
    WHEN Country = 'Bosnia and Herzegovina' THEN (SELECT Schooling FROM w2 WHERE Country = 'Bosnia and Herzegovina' AND Year = 2008)
    WHEN Country = 'Equatorial Guinea' THEN (SELECT Schooling FROM w2 WHERE Country = 'Equatorial Guinea' AND Year = 2008)
    WHEN Country = 'Micronesia (Federated States of)' THEN (SELECT Schooling FROM w2 WHERE Country = 'Micronesia (Federated States of)' AND Year = 2008)
    WHEN Country = 'Montenegro' THEN (SELECT Schooling FROM w2 WHERE Country = 'Montenegro' AND Year = 2011)
    WHEN Country = 'South Sudan' THEN (SELECT Schooling FROM w2 WHERE Country = 'South Sudan' AND Year = 2018)
    WHEN Country = 'Timor-Leste' THEN (SELECT Schooling FROM w2 WHERE Country = 'Timor-Leste' AND Year = 2008)
    WHEN Country = 'Turkmenistan' THEN (SELECT Schooling FROM w2 WHERE Country = 'Turkmenistan' AND Year = 2008)
    ELSE Schooling
    END
WHERE Schooling = '';

UPDATE worldlifexpectancy SET Schooling = NULL WHERE Schooling = '';

# Data cleaning TASK 2: Data consistency
SELECT DISTINCT Country
FROM worldlifexpectancy;
SELECT DISTINCT Status
FROM worldlifexpectancy;
# => No leading or trailing spaces that need to be trimmed, no wrong values

SELECT Country, Status, ROW_NUMBER() OVER(PARTITION BY Country) AS row_num
FROM worldlifexpectancy
GROUP BY Country, Status; # Status seems to be consistent among countries

# Infant deaths vs. Under-five deaths
SELECT Country, Year, `under-fivedeaths`, infantdeaths
FROM worldlifexpectancy
WHERE infantdeaths > `under-fivedeaths`; # No inconsistency here

# Data cleaning TASK 3: Removing duplicates
SELECT Country, COUNT(*) FROM worldlifexpectancy GROUP BY Country HAVING COUNT(*) > 16;
# Ireland, Senegal and Zimbabwe seem to have duplicates

DELETE FROM worldlifexpectancy
WHERE EXISTS (SELECT 1 FROM (SELECT Country, Year, Row_ID FROM worldlifexpectancy) AS w2
	WHERE worldlifexpectancy.Country = w2.Country AND worldlifexpectancy.Year = w2.Year AND worldlifexpectancy.Row_ID > w2.Row_ID);

# Data cleaning TASK 4: Handling outliers
# GDP
# I assume GDP to be an outlier when it's much smaller than a benchmark within the group of country (which I chose Max GDP to represent). Each of them seems to be missing a zero or something, so I'll multiply them by 10 or 100 depending on the difference between them and Max GDP.
WITH w2 AS (SELECT Country, MAX(GDP) AS max_gdp FROM worldlifexpectancy GROUP BY Country)
UPDATE worldlifexpectancy w
SET GDP = CASE
	WHEN GDP < (SELECT max_gdp FROM w2 WHERE w.Country = w2.Country)/8 THEN GDP * 10
    WHEN GDP < (SELECT max_gdp FROM w2 WHERE w.Country = w2.Country)/80 THEN GDP * 100
    ELSE GDP
    END;

# There are still some incorrect ones left so I fixed them manually ;-;
UPDATE worldlifexpectancy SET GDP = GDP/10
WHERE (Country = 'Angola' AND Year IN (2007, 2008))
	OR (Country = 'China' AND Year IN (2007, 2009))
	OR (Country = 'Equatorial Guinea' AND Year IN (2007, 2008, 2009))
    OR (Country = 'Kazakhstan' AND Year IN (2007, 2008, 2009))
    OR (Country = 'Myanmar' AND Year IN (2009, 2008))
    OR (Country = 'Tajikistan' AND Year = 2007)
    OR (Country = 'Russian Federation' AND Year = 2007);

UPDATE worldlifexpectancy SET GDP = GDP*10
WHERE (Country = 'Bangladesh' AND Year = 2021)
	OR (Country = 'Cambodia' AND Year = 2021)
	OR (Country = 'Costa Rica' AND Year IN (2020, 2021))
	OR (Country = 'Iceland' AND Year = 2018)
    OR (Country = 'Italy' AND Year = 2008)
    OR (Country = 'Malaysia' AND Year IN (2020, 2019, 2018))
    OR (Country = 'Mauritius' AND Year = 2017)
    OR (Country = 'Nicaragua' AND Year = 2022)
    OR (Country = 'Syrian Arab Republic' AND Year IN (2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022))
    OR (Country = 'Solomon Islands' AND Year = 2021)
    OR (Country = 'Senegal' AND Year IN (2016, 2018, 2019, 2020, 2021))
    OR (Country = 'Philippines' AND Year = 2009);

# BMI
WITH w2 AS (SELECT Country, MAX(BMI) AS max_bmi FROM worldlifexpectancy GROUP BY Country)
UPDATE worldlifexpectancy w
SET BMI = CASE
	WHEN BMI < (SELECT max_bmi FROM w2 WHERE w.Country = w2.Country)/8 THEN BMI * 10
    ELSE BMI
    END;
    
# Lifeexpectancy
SELECT Country, Year, ROUND(Lifeexpectancy, 1) AS life_expectancy
FROM worldlifexpectancy WHERE Lifeexpectancy < 40 OR Lifeexpectancy > 90;

SELECT Country, Year, ROUND(Lifeexpectancy, 1) AS life_expectancy
FROM worldlifexpectancy WHERE Country IN ('Haiti', 'Sierra Leone'); # Only Haiti's value seem to be an incorrect one
# I assume the two digits were typed in the wrong order (36.3 => 63.3)
UPDATE worldlifexpectancy SET Lifeexpectancy = 63.3 WHERE Country = 'Haiti' AND Year = 2017;

# AdultMortality
# Similar to GDP, but I'm too tired to check if there are any (seemingly) incorrect records left
WITH w2 AS (SELECT Country, MAX(AdultMortality) AS max_am FROM worldlifexpectancy GROUP BY Country)
UPDATE worldlifexpectancy w
SET AdultMortality = CASE
	WHEN AdultMortality < (SELECT max_am FROM w2 WHERE w.Country = w2.Country)/8 THEN AdultMortality * 10
    WHEN AdultMortality < (SELECT max_am FROM w2 WHERE w.Country = w2.Country)/80 THEN AdultMortality * 100
    ELSE AdultMortality
    END;

# EDA TASK 1:
SELECT Country, ROUND(AVG(Lifeexpectancy),1) AS avg_le, MIN(Lifeexpectancy) AS min_le, MAX(Lifeexpectancy) AS max_le
FROM worldlifexpectancy
GROUP BY Country;

SET @row_index := -1;
SELECT AVG(w.Lifeexpectancy) AS median
FROM (SELECT @row_index:=@row_index+1 AS row_index,
	worldlifexpectancy.Lifeexpectancy AS Lifeexpectancy
    FROM worldlifexpectancy
    ORDER BY worldlifexpectancy.Lifeexpectancy) AS w
WHERE w.row_index IN (FLOOR(@row_index / 2), CEIL(@row_index / 2)); # Median = 72.1

# EDA TASK 2:
SELECT Country, Year, Lifeexpectancy
FROM worldlifexpectancy
WHERE Country = 'Viet Nam' ORDER BY Year;
# => Vietnamese people's life expectancy was steadily increasing over the years.

# EDA TASK 3:
SELECT Status, AVG(Lifeexpectancy)
FROM worldlifexpectancy
WHERE Year = 2022
GROUP BY Status;
# => Developed countries have significantly higher life expectancy than developing countries

# EDA TASK 4:
# Calculate the correlation coefficient by using the raw formula
SELECT SUM((AdultMortality - (SELECT AVG(AdultMortality) FROM worldlifexpectancy))*
	(Lifeexpectancy - (SELECT AVG(Lifeexpectancy) FROM worldlifexpectancy))) /
	SQRT(NULLIF(SUM(POWER(AdultMortality - (SELECT AVG(AdultMortality) FROM worldlifexpectancy), 2)) *
		SUM(POWER(Lifeexpectancy - (SELECT AVG(Lifeexpectancy) FROM worldlifexpectancy), 2)), 0)) AS corr
FROM worldlifexpectancy;
# => corr = -0.8923, a very high negative correlation.

# EDA TASK 5:  
SELECT ROUND(AVG(GDP),1) AS avg_gdp, MIN(GDP) AS min_gdp, MAX(GDP) AS max_gdp
FROM worldlifexpectancy;

SELECT * FROM (
	SELECT GDP, PERCENT_RANK() OVER(ORDER BY GDP) AS perc
	FROM worldlifexpectancy) AS percentile
WHERE ROUND(perc,3) IN (0.250, 0.500, 0.750);
# => Approximately 25th percentile = 512, median = 2647 ,5th percentile = 9387

# Defining GDP categories: Very low, low, medium, high
SELECT gdp_tags, ROUND(AVG(Lifeexpectancy),1)
FROM (
	SELECT Lifeexpectancy, CASE
		WHEN ROUND(GDP, 0) < 512 THEN 'Very low'
        WHEN ROUND(GDP, 0) < 2647 THEN 'Low'
        WHEN ROUND(GDP, 0) < 9387 THEN 'Medium'
        ELSE 'High'
        END AS gdp_tags
    FROM worldlifexpectancy) AS categorized
GROUP BY gdp_tags ORDER BY AVG(Lifeexpectancy);
# => Groups with higher GDP have higher Life expectancy

# EDA TASK 6:
SELECT AVG(Measles), AVG(Polio)
FROM worldlifexpectancy; # AVG Measles = 2428, AVG Polio = 82

SELECT measles_tags, AVG(Lifeexpectancy)
FROM (
	SELECT Lifeexpectancy, CASE
		WHEN ROUND(Measles, 0) < 2428 THEN 'Below average'
        ELSE 'Above average'
        END AS measles_tags
    FROM worldlifexpectancy) AS categorized
GROUP BY measles_tags ORDER BY AVG(Lifeexpectancy);

SELECT polio_tags, AVG(Lifeexpectancy)
FROM (
	SELECT Lifeexpectancy, CASE
		WHEN ROUND(Polio, 0) < 82 THEN 'Below average'
        ELSE 'Above average'
        END AS polio_tags
    FROM worldlifexpectancy) AS categorized
GROUP BY polio_tags ORDER BY AVG(Lifeexpectancy);
# => It's clear that higher cases of Measles and Polio tend to lead to lower Life expectancy

# EDA TASK 7:
SELECT Country, Schooling, AVG(Lifeexpectancy)
FROM worldlifexpectancy
WHERE Schooling = (SELECT MIN(Schooling) FROM worldlifexpectancy)
	OR Schooling = (SELECT MAX(Schooling) FROM worldlifexpectancy)
GROUP BY Country, Schooling;
# => The country with the highest Schooling has a Life expectancy of 1.76 times longer than the country with the lowest Schooling

# EDA TASK 8:
SELECT Country, Year, BMI
FROM worldlifexpectancy
WHERE Country = 'Viet Nam'
ORDER BY Year;
# Overall, Vietnam's BMI has an upward trend. It increased slightly, steadily from 2007 to 2022.

# EDA TASK 9:
# Countries with highest life expectancy
SELECT Country, ROUND(AVG(infantdeaths),0), ROUND(AVG(`under-fivedeaths`),0)
FROM worldlifexpectancy
WHERE Country IN (SELECT Country FROM worldlifexpectancy
	WHERE Lifeexpectancy = (SELECT MAX(Lifeexpectancy) FROM worldlifexpectancy))
GROUP BY Country;

# Countries with lowest life expectancy
SELECT Country, ROUND(AVG(infantdeaths),0), ROUND(AVG(`under-fivedeaths`),0)
FROM worldlifexpectancy
WHERE Country IN (SELECT Country FROM worldlifexpectancy
	WHERE Lifeexpectancy = (SELECT MIN(Lifeexpectancy) FROM worldlifexpectancy))
GROUP BY Country;
# => Sierra Leone has much more child deaths than the group of countries above

# EDA TASK 10
SELECT Country, Year, AVG(AdultMortality) OVER(PARTITION BY Country ORDER BY Year) AS rolling_avg
FROM worldlifexpectancy
WHERE Year BETWEEN 2018 AND 2022;
# => Adult mortality has been steadily decreasing during the 2018-2022 period in most countries

# EDA TASK 11
# Calculate the correlation coefficient
SELECT SUM((percentageexpenditure - (SELECT AVG(percentageexpenditure) FROM worldlifexpectancy))*
	(Lifeexpectancy - (SELECT AVG(Lifeexpectancy) FROM worldlifexpectancy))) /
	SQRT(NULLIF(SUM(POWER(percentageexpenditure - (SELECT AVG(percentageexpenditure) FROM worldlifexpectancy), 2)) *
		SUM(POWER(Lifeexpectancy - (SELECT AVG(Lifeexpectancy) FROM worldlifexpectancy), 2)), 0)) AS corr
FROM worldlifexpectancy;
# corr = 0.4056, indicating a positive relationship between the two variables.

# EDA TASK 12:
SELECT SUM((BMI - (SELECT AVG(BMI) FROM worldlifexpectancy))*
	(Lifeexpectancy - (SELECT AVG(Lifeexpectancy) FROM worldlifexpectancy))) /
	SQRT(NULLIF(SUM(POWER(BMI - (SELECT AVG(BMI) FROM worldlifexpectancy), 2)) *
		SUM(POWER(Lifeexpectancy - (SELECT AVG(Lifeexpectancy) FROM worldlifexpectancy), 2)), 0)) AS corr
FROM worldlifexpectancy;      
# corr = 0.7194, indicating a strong positive correlation. As BMI increases, Life expectancy also tends to go up.       
 
# EDA TASK 13:
SELECT gdp_groups, ROUND(AVG(Lifeexpectancy),1), ROUND(AVG(AdultMortality),1), ROUND(AVG(infantdeaths),1)
FROM (
	SELECT Lifeexpectancy, AdultMortality, infantdeaths, CASE
		WHEN ROUND(GDP, 0) < (SELECT AVG(GDP) FROM worldlifexpectancy) THEN 'Low GDP'
        ELSE 'High GDP'
        END AS gdp_groups
    FROM worldlifexpectancy) AS categorized
GROUP BY gdp_groups;
# => The low GDP group has lower Life expectancy, significantly higher Adult mortality and infant mortality

# EDA TASK 14:
# Create a table of continents
CREATE TABLE `continent` (
  `Country` VARCHAR(60),
  `Continent` VARCHAR(20));
INSERT INTO `continent` (`Country`,`Continent`)
VALUES
('Afghanistan','Asia'), ('Albania','Europe'), ('Algeria','Africa'), ('Angola','Africa'),
('Antigua and Barbuda','North America'), ('Argentina','South America'), ('Armenia','Europe'),
('Australia','Oceania'), ('Austria','Europe'), ('Azerbaijan','Europe'),
('Bahamas','North America'), ('Bahrain','Asia'), ('Bangladesh','Asia'),
('Barbados','North America'), ('Belarus','Europe'), ('Belgium','Europe'),
('Belize','North America'), ('Benin','Africa'), ('Bhutan','Asia'),
('Bolivia (Plurinational State of)','South America'), ('Bosnia and Herzegovina','Europe'),
('Botswana','Africa'), ('Brazil','South America'), ('Brunei Darussalam','Asia'),
('Bulgaria','Europe'), ('Burkina Faso','Africa'), ('Burundi','Africa'),
('Cabo Verde','Africa'), ('Cambodia','Asia'), ('Cameroon','Africa'),
('Canada','North America'), ('Central African Republic','Africa'), ('Chad','Africa'),
('Chile','South America'), ('China','Asia'), ('Colombia','South America'),
('Comoros','Africa'), ('Congo','Africa'), ('Costa Rica','North America'),
('Côte d''Ivoire','Africa'), ('Croatia','Europe'),('Cuba','North America'),
('Cyprus','Europe'),('Czechia','Europe'),('Democratic People''s Republic of Korea','Asia'),
('Democratic Republic of the Congo','Africa'),('Denmark','Europe'),('Djibouti','Africa'),
('Dominican Republic','North America'),('Ecuador','South America'),('Egypt','Africa'),
('El Salvador','North America'),('Equatorial Guinea','Africa'),('Eritrea','Africa'),
('Estonia','Europe'),('Ethiopia','Africa'),('Fiji','Oceania'),('Finland','Europe'),
('France','Europe'),('Gabon','Africa'),('Gambia','Africa'),('Georgia','Europe'),
('Germany','Europe'),('Ghana','Africa'),('Greece','Europe'),('Grenada','North America'),
('Guatemala','North America'),('Guinea','Africa'),('Guinea-Bissau','Africa'),
('Guyana','South America'),('Haiti','North America'),('Honduras','North America'),
('Hungary','Europe'),('Iceland','Europe'),('India','Asia'),('Indonesia','Asia'),
('Iran (Islamic Republic of)','Asia'),('Iraq','Asia'),('Ireland','Europe'),
('Israel','Asia'),('Italy','Europe'),('Jamaica','North America'),('Japan','Asia'),
('Jordan','Asia'),('Kazakhstan','Asia'),('Kenya','Africa'),('Kiribati','Oceania'),
('Kuwait','Asia'),('Kyrgyzstan','Asia'),('Lao People''s Democratic Republic','Asia'),
('Latvia','Europe'),('Lebanon','Asia'),('Lesotho','Africa'),('Liberia','Africa'),
('Libya','Africa'),('Lithuania','Europe'),('Luxembourg','Europe'),('Madagascar','Africa'),
('Malawi','Africa'),('Malaysia','Asia'),('Maldives','Asia'),('Mali','Africa'),
('Malta','Europe'),('Mauritania','Africa'),('Mauritius','Africa'),('Mexico','North America'),
('Micronesia (Federated States of)','Oceania'),('Mongolia','Asia'),('Montenegro','Europe'),
('Morocco','Africa'),('Mozambique','Africa'),('Myanmar','Asia'),('Namibia','Africa'),
('Nepal','Asia'),('Netherlands','Europe'),('New Zealand','Oceania'),('Nicaragua','North America'),
('Niger','Africa'),('Nigeria','Africa'),('Norway','Europe'),('Oman','Asia'),
('Pakistan','Asia'),('Panama','North America'),('Papua New Guinea','Oceania'),
('Paraguay','South America'),('Peru','South America'),('Philippines','Asia'),('Poland','Europe'),
('Portugal','Europe'),('Qatar','Asia'),('Republic of Korea','Asia'),('Republic of Moldova','Europe'),
('Romania','Europe'),('Russian Federation','Asia'),('Rwanda','Africa'),('Saint Lucia','North America'),
('Saint Vincent and the Grenadines','North America'),('Samoa','Oceania'),('Sao Tome and Principe','Africa'),
('Saudi Arabia','Asia'),('Senegal','Africa'),('Serbia','Europe'),('Seychelles','Africa'),
('Sierra Leone','Africa'),('Singapore','Asia'),('Slovakia','Europe'),('Slovenia','Europe'),
('Solomon Islands','Oceania'),('Somalia','Africa'),('South Africa','Africa'),('South Sudan','Africa'),
('Spain','Europe'),('Sri Lanka','Asia'),('Sudan','Africa'),('Suriname','South America'),
('Swaziland','Africa'),('Sweden','Europe'),('Switzerland','Europe'),('Syrian Arab Republic','Asia'),
('Tajikistan','Asia'),('Thailand','Asia'),('The former Yugoslav republic of Macedonia','Europe'),
('Timor-Leste','Asia'),('Togo','Africa'),('Tonga','Oceania'),('Trinidad and Tobago','North America'),
('Tunisia','Africa'),('Turkey','Europe'),('Turkmenistan','Asia'),('Uganda','Africa'),
('Ukraine','Europe'),('United Arab Emirates','Asia'),('United Kingdom of Great Britain and Northern Ireland','Europe'),
('United Republic of Tanzania','Africa'),('United States of America','North America'),('Uruguay','South America'),
('Uzbekistan','Asia'),('Vanuatu','Oceania'),('Venezuela (Bolivarian Republic of)','South America'),
('Viet Nam','Asia'),('Yemen','Asia'),('Zambia','Africa'),('Zimbabwe','Africa');

SELECT Continent, ROUND(AVG(Lifeexpectancy),1)
FROM worldlifexpectancy w
JOIN continent c ON w.Country = c.Country
GROUP BY Continent;
# => European people have the highest average life expectancy. All continents have an average life expectancy of above 70, except Africa.
# African people's average life expectancy is remarkably lower than other continent. This indicates a serious issue of health disparity between them and the rest of the world.