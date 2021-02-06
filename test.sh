
############ 
############ 
############ bytefreq DQ TEST Script, also useful for USER TRAINING
############ author: Andrew Morgan
############ license GPLv3 
############ 
############ 

# This is the test files to generate each of the report types for 100k of companies house data, from the UK. Which has issues.
# It also walks through the process of examining data quality on a new file.

## Prepare and reset the test suite
echo "## Reset test files and directories"

rm testdata/*.csv
rm testdata/*.pip
rm out/*

## Download the companies house data which is provided in csv + enclosures format, like excel produces. (CSV is ALWAYS a terrible mistake - pls avoid). 

echo "checking if you have the test data from companies house, if not we'll download it"

# if the file doesn't exist, if it doesn't go get it
if [ ! -f "testdata/BasicCompanyData-part6.zip" ]
then
   echo "## Fetching the companies house data using wget"
   wget http://download.companieshouse.gov.uk/BasicCompanyData-part6.zip
   mv BasicCompanyData-part6.zip testdata/.
fi

## Unzip the data. 
echo "## unzipping the data"
cd testdata
unzip BasicCompanyData-part6.zip
cd ..

## User charfreq to find out what is in the file. Is it all extended ascii? Maybe not!

echo "## use charfreq to study the whole raw file before we parse it. Could take a minute or two" 
echo "## what can we learn?"

od -cb testdata/BasicCompanyData-2021-02-01-part6_6.csv | gawk -f charfreq.awk | sort -n > charfreq.rpt.txt

echo ""
echo "==============================================================================="
echo "here is the final character frequency analysis report"
echo "==============================================================================="

cat charfreq.rpt.txt

echo ""
echo ""
echo "======================================================"
echo "Let's examine key areas of it to make conclusions:    "
echo "======================================================"
echo ""
echo "Is this file LF, or CR, LF/CR delimited? anything odd?"
cat charfreq.rpt.txt | grep "0x0A\|0x0D"
echo ""
echo "======================================================"
echo "Check below matching numbers for opening/closing chars"
cat charfreq.rpt.txt | grep -i "left\|right"

echo ""
echo "======================================================"
echo "Check below for potential enclosure issues, preparser "


cat charfreq.rpt.txt | grep -i quo

echo ""
echo "======================================================"
echo "check below for things having pairs... matched?       "

cat charfreq.rpt.txt | grep -i "left\|right"

## Use charfreq to suggest a good alternative delimiter. I suggest Pipe "|" delimited data is easy, clean, best. Does charfreq prove this?
echo ""
echo "======================================================"
echo "## Any good delimiter choices not in the raw data?    "

cat charfreq.rpt.txt | grep -i "vertical bar\|Record Separator\|Inverted exclamation mark\|Horizontal Tab"

echo ""
echo "===end of review==============================================================="

## if wanted you can downsample the file - a random ~100k will be fine. Do this using "1 in N" records is easiest/effective with cap at 100k. 
## 
# gawk 'NR%5==0' testdata/BasicCompanyData-2021-02-01-part6_6.csv | head -100000 > testdata/downsample.csv


echo ""
echo "Now start to parse the raw csv file using python into pipe delimited"
echo "(there are some helper python scripts in the parser directory you can edit to make your own)"
echo ""

# Becuase we DO NOT TRUST PARSING the csv data - we need to profile the data AFTER the parsing.

# So we prepare our data into PARSED data to test things - As we want to read the data later using python, we will convert it using python.

python3 parsers/csv2pipe.py testdata/BasicCompanyData-2021-02-01-part6_6.csv

# Finally we do the data profiling - to test the quality of the data, as processed by our python PARSER.
# Do it by reading in the file and generating the profiling data.


echo  "GENERATE HUMAN READABLE REPORT - popular eyeball inspection report"
time gawk -F"|" -f bytefreq_v1.05.awk -v header="1" -v report="1" -v grain="L" testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip >out/UkCompanySample.rpt1.txt

echo  "GENERATE DATABASE LOADABLE REPORT SUMMARY OUTPUTS - for automation, used for drift in quality analysis"
time gawk -F"|" -f bytefreq_v1.05.awk -v header="1" -v report="0" -v grain="L" testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip > out/UkCompanySample.rpt0.txt

echo  "#GENERATE DATABASE LOADABLE RAW+PROFILED DATA - for manual cleansing, find bad datapoints and fix them"
time gawk -F"|" -f bytefreq_v1.05.awk -v header="1" -v report="2" -v grain="L" testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip > out/UkCompanySample.raw2.txt

echo  "GENERATE DATABASE LOADABLE LONGFORMAT RAW DATA - for automated remediation"
time gawk -F"|" -f bytefreq_v1.05.awk -v header="1" -v report="3" -v grain="L" testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip > out/UkCompanySample.raw3.txt

echo "SUCCESS !"
# Now you have all the things you need to eyeball the quality, study drift over time, find and propose fixes, to automate correcting bad data points
# all that is left to do, is to use your new understanding to construct automated data quality tools that sit inline the data pipelines

# enjoy
# Andrew





