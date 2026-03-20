# Data Dictionary – API-Pop (filtered rumor cases)

| Field Name             | Data Type     | Format / Size                          | Description     
|------------------------|---------------|----------------------------------------|-----------------------------------------------------------|
| `suspected_diagnosis`  | TEXT          | -                                      | Free text of suspected diagnosis
| `symptom_description`  | TEXT          | -                                      | Free text description of symptoms  
| `symptom_onset_date`   | DATE          | `YYYY-MM-DD`                           | Date when symptoms began                    
| `residence_country`    | VARCHAR(100)  | -                                      | Country of residence
| `residence_province`   | VARCHAR(100)  | -                                      | Province/state of residence 
| `residence_department` | VARCHAR(100)  | -                                      | Department of residence
| `censal_fraction`      | VARCHAR(100)  | -                                      | Censal Fraction of residence
| `sex`                  | CHAR(1)       | `M` / `F` / `Other` / `Rather not say` | Biological sex of the individual   
| `birth_date`           | DATE          | `YYYY-MM-DD`                           | Date of birth        

   
             


---

**Note:** All fields are pulled from the `rumor_reports` table in MySQL.
