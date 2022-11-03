
############ 
############ 
############ bytefreq DQ TEST Script, also useful for USER TRAINING
############ author: Andrew Morgan
############ license GPLv3 
############ 
############ 

runtime=$1
echo "running this script with ${runtime}"

# this tests if we have an argument on the command line that overrides gawk, to say goawk or mawk.

# now run a timed execution of the file

echo  "${runtime}: GENERATE HUMAN READABLE REPORT - popular eyeball inspection report"

time ${runtime} -F"|" -f bytefreq_v1.05.awk -v header="1" -v report="1" -v grain="L" testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip >out/UkCompanySample.${runtime}.rpt1.txt 2>>timer.logs




