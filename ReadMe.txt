This read me document describes the structure of some of the data files used in the "Inputs, Incentives, and Complementarities in Education: Experimental Evidence from Tanzania" publish in the  Quarterly Journal of Economics. 

Only those files that may need explanation are described here.

To run these analysis files all you need to is to unzip the file. 
The required folder and sub folders will automatically be created. 
The only extra step is to open STATA and download the necessary pacgakes if needed.
Then open the master do file (00_Master.do in the Codes folder) and change the working directory. This file calls all the other do-file.
All the other do files are named after the table/figure they replicate

Note that the bootstrap routines (for the confidence intervals for Figure A1) can take a long time to run and so you may want to change the number of repetitions from 10000 to 10 before running the files.

CODES

00_Master: Is the master do file. It sets up the working directory, some global variable lists (e.g., outcome and control variables), and calls every other do file.

Every other do file is named after the table/figure it replicates.

DATA SETS

All datasets use the following nomeclature. 
T1 refers to data collected by the research team at the beginning of 2013 school year
T2 to data collected by the research team in the middle of 2013 school year
T3 to data collected by the research team at the end of 2013 school year
T4 to data collected by TWAWEZA the end of 2013 school year (i.e., the test data used to pay teacher incentives)
T5 refers to data collected by the research team at the beginning of 2014 school year
T6 to data collected by the research team in the middle of 2014 school year
T7 to data collected by the research team at the end of 2014 school year
T8 to data collected by TWAWEZA the end of 2014 school year (i.e., the test data used to pay teacher incentives)


1. Student_School_House_Teacher_Char.dta

This is the main file used for replication. It has the student level panel data set, and attached to it school, teacher, and household characteristics. 
Some of the key variables here are:
 -The normalized test scores. Z_kiswahili_XX Z_kiingereza_XX Z_hisabati_XX Z_sayansi_XX Z_ScoreKisawMath_XX Z_ScoreFocal_XX, where XX is the date in which the test score was collected. kiingereza is English in Kiswahili, and Hisabati is math. Sayansi is science. ScoreFocal is a composite scored created using a PCA index betwen the score in math, english, and kisawhili. ScoreKisawMath is created using a PCA index between math and kisawhili.
 -LagZ_hisabati LagZ_kiswahili LagZ_kiingereza LagZ_ScoreFocal  is the test score collected at the beginning of the school year before the intervention began.

2. Teacher.dta and School.dta
These are teacher and school level panels.

3. Student_PSLE_2013.dta, Student_PSLE_2014.dta, School_PSLE_2013.dta, and School_PSLE_2014.dta
These are data sets from the nationwide standarized assesment (PSLE) for grade 7th students. 

4. TwaTestData2013 and TwaTestData2014
These have the high-stakes test score data for 2013 and 2014

5. R_EL_schools_noPII
Has the treatment status of each school

6. TAttendace
Has data on teacher attendance collected during T2 and T6

7. R4Grade_noPII
Has data on grade-level enrollment during T5

8. Household_Baseline2013
Has household level data collected during T1


OUTPUT

The output from the table do files are .tex that are meant to be read by the original tex file and therefore do not have table headers or notes. 

