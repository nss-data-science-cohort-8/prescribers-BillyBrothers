-- ## Prescribers Database

-- For this exericse, you'll be working with a database derived from the [Medicare Part D Prescriber Public Use File](https://www.hhs.gov/guidance/document/medicare-provider-utilization-and-payment-data-part-d-prescriber-0). More information about the data is contained in the Methodology PDF file. See also the included entity-relationship diagram.

-- 1. 
--     a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.


SELECT nppes_provider_first_name, npi, SUM(total_claim_count) AS max_claim_count
FROM prescriber
INNER JOIN prescription
USING(npi)
WHERE total_claim_count IS NOT NULL  
GROUP BY nppes_provider_first_name, npi
ORDER BY max_claim_count DESC;
    
--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

SELECT nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, npi, SUM(total_claim_count) AS max_claim_count
FROM prescriber
INNER JOIN prescription
USING(npi)
GROUP BY nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, npi
ORDER BY max_claim_count DESC;

-- 2. 
--     a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT specialty_description, SUM(total_claim_count) AS max_claim_count
FROM prescriber
INNER JOIN prescription
USING(npi)
WHERE total_claim_count IS NOT NULL  
GROUP BY specialty_description
ORDER BY max_claim_count DESC;


--     b. Which specialty had the most total number of claims for opioids?

SELECT specialty_description, SUM(total_claim_count) AS max_claim_count
FROM prescriber
INNER JOIN prescription
USING(npi)
WHERE total_claim_count IS NOT NULL 
AND drug_name IN(
SELECT drug_name
FROM drug
WHERE opioid_drug_flag = 'Y'
)
GROUP BY specialty_description
ORDER BY max_claim_count DESC;


--     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?4

--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

-- 3. 
--     a. Which drug (generic_name) had the highest total drug cost?

SELECT generic_name, SUM(total_drug_cost) AS TOTAL
FROM prescription
INNER JOIN drug
USING(drug_name)
GROUP BY generic_name
ORDER BY TOTAL DESC;


--     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**


SELECT generic_name, ROUND(SUM(total_drug_cost)/SUM(total_day_supply), 2) AS total_cost_per_day
FROM prescription
INNER JOIN drug
USING(drug_name)
GROUP BY generic_name
ORDER BY total_cost_per_day DESC;

-- 4. 
--     a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. **Hint:** You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/

SELECT drug_name, 
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		 ELSE 'Neither' END AS drug_type
FROM drug;




--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.




SELECT drug_type, SUM(total_drug_cost::money) AS drug_cost
FROM prescription
INNER JOIN (
SELECT drug_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		 ELSE 'Neither' END AS drug_type
		 FROM drug)
		 AS drug2 
USING(drug_name)
WHERE
	drug2.drug_type IN ('opioid', 'antibiotic')
GROUP BY drug2.drug_type
ORDER BY drug_cost DESC;


-- 5. 
--     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

SELECT COUNT(DISTINCT cbsaname)
FROM cbsa 
WHERE cbsaname LIKE '%TN%';

--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
 

*largest*
SELECT SUM(population) as sum_pop, cbsaname
FROM cbsa
INNER JOIN population
USING(fipscounty)
GROUP BY cbsa, cbsaname
ORDER BY sum_pop DESC;
LIMIT 1;

*smallest*
SELECT SUM(population) as sum_pop, cbsaname
FROM cbsa
INNER JOIN population
USING(fipscounty)
GROUP BY cbsa, cbsaname
ORDER BY sum_pop;
LIMIT 1;


--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT *
FROM cbsa
FULL JOIN fips_county
USING(fipscounty)
FULL JOIN population
USING(fipscounty)
WHERE population IS NOT NULL
	AND cbsaname IS NULL
ORDER BY population DESC
LIMIT 1;

-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT drug_name, total_claim_count
FROM prescription
GROUP BY drug_name, total_claim_count
HAVING total_claim_count >= 3000;

--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT
	drug_name, total_claim_count,
	CASE WHEN drug_name IN(
	SELECT drug_name
	FROM prescriber
	INNER JOIN prescription
	USING(npi)
	INNER JOIN drug
	USING(drug_name)
	WHERE opioid_drug_flag = 'Y'
	) THEN 'opioid' ELSE 'not' END AS is_opioid
FROM prescription
INNER JOIN prescriber
USING(npi)
GROUP BY drug_name, total_claim_count
HAVING total_claim_count >= 3000;

--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT
	drug_name, 
	total_claim_count,
	nppes_provider_first_name || ' ' || nppes_provider_last_org_name AS provider_name,
	CASE WHEN drug_name IN(
	SELECT drug_name
	FROM prescriber
	INNER JOIN prescription
	USING(npi)
	INNER JOIN drug
	USING(drug_name)
	WHERE opioid_drug_flag = 'Y'
	) THEN 'opioid' ELSE 'not' END AS is_opioid
FROM prescription
INNER JOIN prescriber
USING(npi)
GROUP BY drug_name, total_claim_count, nppes_provider_first_name, 
HAVING total_claim_count >= 3000;


-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT npi, drug_name AS drug
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y';



--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).


SELECT npi, D.drug_name, SUM(total_claim_count)
FROM prescriber
INNER JOIN prescription
USING(npi)
CROSS JOIN drug AS D
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
GROUP BY npi, D.drug_name
ORDER BY npi DESC;

--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.


SELECT npi, 
	D.drug_name, 
	COALESCE(SUM(total_claim_count), 0) AS total_claim_count
FROM prescriber
INNER JOIN prescription
USING(npi)
CROSS JOIN drug AS D
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
GROUP BY npi, D.drug_name
ORDER BY npi DESC;
