-- 1. 
--     a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

SELECT prescriber.npi, prescription.total_claim_count
FROM prescriber
	JOIN prescription
	ON prescriber.npi = prescription.npi
ORDER BY total_claim_count DESC
LIMIT 1;

-- Answer: NPI 1912011792 had 4538 claims

--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

SELECT prescriber.nppes_provider_first_name, prescriber.nppes_provider_last_org_name, prescriber.specialty_description, prescription.total_claim_count
FROM prescriber
	JOIN prescription
	ON prescriber.npi = prescription.npi
ORDER BY total_claim_count DESC
LIMIT 1;

--Answer: David Coffey, Family Practice, 4538 claims

-- 2. 
--     a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT DISTINCT(prescriber.specialty_description), SUM(prescription.total_claim_count)
FROM prescriber
	JOIN prescription 
	ON prescriber.npi = prescription.npi
GROUP BY DISTINCT(prescriber.specialty_description)
ORDER BY SUM(prescription.total_claim_count) DESC;

-- Answer: Family Practice, 9752347 claims

--     b. Which specialty had the most total number of claims for opioids?

SELECT prescriber.specialty_description, COUNT(drug.opioid_drug_flag)
FROM prescriber
	JOIN prescription 
	ON prescriber.npi = prescription.npi
	JOIN drug 
	ON prescription.drug_name = drug.drug_name
WHERE drug.opioid_drug_flag = 'Y'
GROUP BY prescriber.specialty_description
ORDER BY SUM(prescription.total_claim_count) DESC

-- Answer: Nurse Practicioner, 9551

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

SELECT drug.generic_name, SUM(prescription.total_drug_cost)
FROM drug
	INNER JOIN prescription
	ON drug.drug_name = prescription.drug_name
GROUP BY drug.generic_name
ORDER BY SUM(prescription.total_drug_cost) DESC

-- Answer: "INSULIN GLARGINE,HUM.REC.ANLOG"	104264066.35

--     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT drug.generic_name, ROUND((prescription.total_drug_cost/prescription.total_day_supply),2) AS cost_per_day
FROM drug
	JOIN prescription
	ON drug.drug_name = prescription.drug_name
ORDER BY cost_per_day DESC

-- Answer: "IMMUN GLOB G(IGG)/GLY/IGA OV50"	$7141.11/day

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

SELECT COUNT(cbsaname)
FROM cbsa
WHERE cbsaname LIKE '%TN%'

-- Answer: 56 CBSAs are in Tennessee

--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT DISTINCT(TRIM(cbsa.cbsaname)), SUM(population.population)
FROM cbsa
JOIN zip_fips
ON cbsa.fipscounty=zip_fips.fipscounty
JOIN population
ON zip_fips.fipscounty=population.fipscounty
GROUP BY cbsa.cbsaname
ORDER BY SUM(population) DESC

--Answer: The largest population is Memphis, TN-MS-AR with 67870189, the smallest is Morristown, TN with 1163520.

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
		CASE WHEN drug.opioid_drug_flag = 'Y' THEN 'opioid' ELSE 'not opioid' END) AS drug_type, prescriber.nppes_provider_first_name, prescriber.nppes_provider_last_org_name
FROM prescription
JOIN drug
ON prescription.drug_name = drug.drug_name
JOIN prescriber 
ON prescription.npi = prescriber.npi
WHERE total_claim_count > 3000


-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT prescriber.npi, prescription.drug_name,
	(CASE WHEN drug.opioid_drug_flag = 'Y' THEN 'opioid' ELSE 'not opioid' END) AS drug_type
FROM prescriber
CROSS JOIN prescription
JOIN drug
ON prescription.drug_name=drug.drug_name
WHERE nppes_provider_city = 'NASHVILLE'
AND specialty_description = 'Pain Management'
AND (CASE WHEN drug.opioid_drug_flag = 'Y' THEN 'opioid' ELSE 'not opioid' END) = 'opioid';



--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

SELECT prescriber.npi, prescription.drug_name, prescription.total_claim_count
FROM prescriber
CROSS JOIN prescription
JOIN drug
ON prescription.drug_name=drug.drug_name
WHERE nppes_provider_city = 'NASHVILLE'
AND specialty_description = 'Pain Management'
AND (CASE WHEN drug.opioid_drug_flag = 'Y' THEN 'opioid' ELSE 'not opioid' END) = 'opioid';
    
--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
