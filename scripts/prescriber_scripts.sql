-- 1. 
--     a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

SELECT prescription.npi, SUM(prescription.total_claim_count)
FROM prescription
GROUP BY prescription.npi
ORDER BY SUM(total_claim_count) DESC
LIMIT 1;

-- Answer: 1881634483	99707


--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

SELECT prescriber.nppes_provider_first_name, prescriber.nppes_provider_last_org_name, prescriber.specialty_description, SUM(prescription.total_claim_count) as rxcount
FROM prescriber
	JOIN prescription
	ON prescriber.npi = prescription.npi
GROUP BY prescriber.nppes_provider_first_name, prescriber.nppes_provider_last_org_name, prescriber.specialty_description
ORDER BY rxcount DESC
LIMIT 1;

--Answer: "BRUCE"	"PENDLEY"	"Family Practice"	99707


-- 2. 
--     a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT DISTINCT(prescriber.specialty_description), SUM(prescription.total_claim_count) as claimcount
FROM prescriber
	JOIN prescription 
	ON prescriber.npi = prescription.npi
GROUP BY DISTINCT(prescriber.specialty_description)
ORDER BY claimcount DESC;

-- Answer: Family Practice, 9752347 claims

--     b. Which specialty had the most total number of claims for opioids?

SELECT prescriber.specialty_description, SUM(total_claim_count) AS totalclaim
FROM prescriber
	JOIN prescription 
	ON prescriber.npi = prescription.npi
	JOIN drug 
	ON prescription.drug_name = drug.drug_name
WHERE drug.opioid_drug_flag = 'Y'
GROUP BY prescriber.specialty_description
ORDER BY totalclaim DESC

-- Answer: Nurse Practicioner, 900845

--     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT prescriber.specialty_description, COUNT(prescription.drug_name) AS drug_name
FROM prescriber
	LEFT JOIN prescription 
	ON prescriber.npi = prescription.npi
GROUP BY prescriber.specialty_description
ORDER BY drug_name ASC;


-- Answer: Yes, there are 15 specialties that have no associated prescriptions.

--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

-- 3. 
--     a. Which drug (generic_name) had the highest total drug cost?

SELECT drug.generic_name, SUM(prescription.total_drug_cost) AS totalcost
FROM drug
	INNER JOIN prescription
	ON drug.drug_name = prescription.drug_name
GROUP BY drug.generic_name
ORDER BY totalcost DESC

-- Answer: "INSULIN GLARGINE,HUM.REC.ANLOG"	104264066.35

--     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT drug.generic_name, ROUND(SUM(prescription.total_drug_cost)/SUM(prescription.total_day_supply),2) AS cost_per_day
FROM drug
	JOIN prescription
	ON drug.drug_name = prescription.drug_name
GROUP BY drug.generic_name
ORDER BY cost_per_day DESC

-- Answer: "C1 ESTERASE INHIBITOR"	3495.22


-- 4. 
--     a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.

SELECT drug.drug_name,
	CASE
		WHEN drug.opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN drug.antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither' END AS drug_type
FROM drug

--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT
	ROUND(SUM(prescription.total_drug_cost),2),
	(CASE 
		WHEN drug.opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN drug.antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		END) AS drug_type
FROM prescription
JOIN DRUG
ON prescription.drug_name = drug.drug_name
GROUP BY drug_type

--Answer: More was spent on opioids, $105,080,626.37 versus $38,435,121.26 on antibiotics.

-- 5. 
--     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

SELECT COUNT(DISTINCT cbsaname)
FROM cbsa
WHERE cbsaname LIKE '%TN%'

-- Answer: 10 CBSAs are in Tennessee

--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT DISTINCT cbsa.cbsaname, SUM(population.population) AS totalpopulation
FROM cbsa
INNER JOIN zip_fips
ON cbsa.fipscounty=zip_fips.fipscounty
INNER JOIN population
ON zip_fips.fipscounty=population.fipscounty
GROUP BY cbsa.cbsaname
ORDER BY totalpopulation DESC

--Answer: The largest population is Memphis, TN-MS-AR with 67870189, the smallest is Morristown, TN with 1163520.
--******THIS IS NOT THE RIGHT ANSWER, SHOULD BE NASHVILLE FIRST?

--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT DISTINCT(fips_county.county) AS county, SUM(population.population) AS total_population
FROM fips_county 
JOIN population
ON fips_county.fipscounty=population.fipscounty
WHERE fips_county.fipscounty NOT IN 
	(SELECT fipscounty
	FROM cbsa)
AND population.population IS NOT NULL
GROUP BY county
ORDER BY total_population DESC

--Answer: Sevier County, 95523

-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000

--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT prescription.drug_name, total_claim_count,
	(SELECT 
		CASE WHEN drug.opioid_drug_flag = 'Y' THEN 'opioid' 
	 ELSE 'not opioid' END) AS drug_type
FROM prescription
LEFT JOIN drug
ON prescription.drug_name = drug.drug_name
WHERE total_claim_count >= 3000;


--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT prescription.drug_name, total_claim_count,
	(SELECT 
		CASE WHEN drug.opioid_drug_flag = 'Y' THEN 'opioid' 
	 ELSE 'not opioid' END) AS drug_type, prescriber.nppes_provider_first_name, prescriber.nppes_provider_last_org_name
FROM prescription
JOIN prescriber
ON prescription.npi=prescriber.npi
LEFT JOIN drug
ON prescription.drug_name = drug.drug_name
WHERE total_claim_count >= 3000;

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT prescriber.npi, drug.drug_name,
	(CASE WHEN drug.opioid_drug_flag = 'Y' THEN 'opioid' ELSE 'not opioid' END) AS drug_type
FROM prescriber
CROSS JOIN drug
WHERE prescriber.nppes_provider_city = 'NASHVILLE'
AND prescriber.specialty_description= 'Pain Management'
AND (CASE WHEN drug.opioid_drug_flag = 'Y' THEN 'opioid' ELSE 'not opioid' END) = 'opioid'
ORDER BY npi;

--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

SELECT prescriber.npi, drug.drug_name, prescription.total_claim_count
FROM prescriber
	CROSS JOIN drug
	FULL JOIN prescription
	ON drug.drug_name=prescription.drug_name
	AND prescription.npi=prescriber.npi
WHERE prescriber.nppes_provider_city = 'NASHVILLE'
AND specialty_description = 'Pain Management'
AND drug.opioid_drug_flag = 'Y'
GROUP BY prescriber.npi, drug.drug_name, prescription.total_claim_count
ORDER BY npi;


--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

SELECT prescriber.npi, drug.drug_name, COALESCE(prescription.total_claim_count,0) AS total_claim_count
FROM prescriber
	CROSS JOIN drug
	FULL JOIN prescription
	ON drug.drug_name=prescription.drug_name
	AND prescription.npi=prescriber.npi
WHERE prescriber.nppes_provider_city = 'NASHVILLE'
AND specialty_description = 'Pain Management'
AND drug.opioid_drug_flag = 'Y'
ORDER BY prescriber.npi;

--BONUSES

-- 1. How many npi numbers appear in the prescriber table but not in the prescription table?

SELECT COUNT(prescriber.npi) AS drcount, COUNT(prescription.npi) AS rxcount
FROM prescriber
LEFT JOIN prescription
ON prescriber.npi=prescription.npi

--Answer: 660516-656058= 4458 npi numbers

-- 2.
--     a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.

SELECT generic_name, SUM(prescription.total_claim_count) AS rxcount
FROM drug
RIGHT JOIN prescription 
ON drug.drug_name=prescription.drug_name
LEFT JOIN prescriber
ON prescription.npi=prescriber.npi
WHERE specialty_description='Family Practice'
AND total_claim_count IS NOT NULL
GROUP BY generic_name
ORDER BY rxcount DESC
LIMIT 5;

--Answer: "LEVOTHYROXINE SODIUM", "LISINOPRIL", "ATORVASTATIN CALCIUM", "AMLODIPINE BESYLATE", "OMEPRAZOLE"

--     b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.

SELECT generic_name, SUM(prescription.total_claim_count) AS rxcount
FROM drug
CROSS JOIN prescriber
JOIN prescription
ON prescription.npi=prescriber.npi
AND drug.drug_name=prescription.drug_name
WHERE specialty_description='Cardiology'
AND total_claim_count IS NOT NULL
GROUP BY generic_name
ORDER BY  rxcount DESC
LIMIT 5;

--Answer ""ATORVASTATIN CALCIUM", "CARVEDILOL", "METOPROLOL TARTRATE", "CLOPIDOGREL BISULFATE", "AMLODIPINE BESYLATE"

--     c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.

SELECT generic_name, SUM(prescription.total_claim_count) AS totalcount
FROM drug
CROSS JOIN prescriber
JOIN prescription
ON prescription.npi=prescriber.npi
AND drug.drug_name=prescription.drug_name
WHERE specialty_description IN ('Family Practice','Cardiology')
AND total_claim_count IS NOT NULL
GROUP BY generic_name
ORDER BY totalcount DESC
LIMIT 5;

--Answer: "ATORVASTATIN CALCIUM", "LEVOTHYROXINE SODIUM", "AMLODIPINE BESYLATE", "LISINOPRIL", "FUROSEMIDE"

-- 3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
--     a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.

SELECT prescriber.npi, SUM(prescription.total_claim_count) AS rxcount, prescriber.nppes_provider_city
FROM prescriber
LEFT JOIN prescription
ON prescriber.npi=prescription.npi
WHERE prescription.total_claim_count IS NOT NULL
AND prescriber.nppes_provider_city = 'NASHVILLE'
GROUP BY prescriber.npi, prescriber.nppes_provider_city
ORDER BY rxcount DESC;

  
--     b. Now, report the same for Memphis.
    
--     c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.

-- 4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.

-- 5.
--     a. Write a query that finds the total population of Tennessee.
    
--     b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.

