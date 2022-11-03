# ByteFreq Data Profiler

Author: Andrew J Morgan  
Company: 6point6.co.uk  
Provenance: forked from https://github.com/minkymorgan/bytefreq  
License: GPLv3  

Main programs:

*bytefreq_v1.05.awk*  
*charfreq.awk*  
*fieldprofiler.awk*


## Introduction
*bytefreq* is a data quality and data profiling toolkit.    

It can be used to:    
    
    1) profile the bytes (characters) in a file, using charfreq.awk 
    2) verify parsing of columns correct, using fieldprofiler.awk
    3) generate Mask-Based data profiling reports, with choice of mask
    4) generate profiled datasets for data quality remediation engines

It is written in the portable awk language. The library implements a number of data transformations and reports helping you do data quality studies using Mask-Based Data Profiling techniques.

The software enables several outputs, each necessary for a different part of the data quality process. They can be used for data quality inspections, or to preprocess your data to construct an automated data quality monitoring and cleansing engines in downstream tools. 

To interpret the output, an understanding of how the program generalises data into the pattern-string is useful. Below is a description of the two available algorithms you can select from when studying your data, the first resulting in a granular study of your data, and the second a more generalised study of your data. Note the default setting is to produce more granular output.

### bytefreq's Masks

In data profiling a mask is a transformation function that produces a data quality feature, which when summarised reveals insights into data quality.
bytefreq includes 2 important "masks" commonly used under the hood in high end data profiling tools, shown below.

    1) High Grain	(implemented)
    2) Low Grain	(implemented)
    3) DataType Grain	(TODO)
    4) IsPop Grain	(TODO)

Mask rules are defined below:

#### 'H' Highly Granular Pattern Construction:

    For all data content, apply the following character level translation:
    1) Translate all upper case characters in the data [A-Z] to becoming an "A"
    2) Translate all lower case characters in the data [a-z] to an "a"
    3) Translate all numbers in the data [0-9] to a "9"
    4) Translate all tab marks to a "T"
    5) Leave all remaining whitespace and high ASCII and punctuation as is 
    
    
    For example, a field called Address, may contain raw data such as:

        John Smith, 33 High Street, Townford, Countyshire, UK, TC2 03R

    which after transformation becomes:

        Aaaa Aaaaa, 99 Aaaa Aaaaaa, Aaaaaaaa, Aaaaaaaaaaa, AA, AA9 99A


#### 'L' Less Granular Pattern Construction

    For all data content items, apply the following character level translation:
    1) Translate all repeating occurrences of upper case characters [A-Z]+ to becoming an "A"
    2) Translate all repeating occurrences of lower case characters [a-z]+ to an "a"
    3) Translate all sequences of numbers in the data [0-9]+ to a "9"
    4) Translate all tab marks to a "T"
    5) Leave all remaining whitespace, high ASCII, and punctuation as is 
    
    
    For example, a field called Address, may contain raw data such as:

        John Smith, 33 High Street, Townford, Countyshire, UK, TC2 03R
    
    which after transformation becomes:
    
        Aa Aa, 9 Aa Aa, Aa, Aa, AA, A9 9A

    Notice that the profile is more general using this rule, so the profiles match more occurances.  
    This greatly helps to summarise high cardinality data.
*The low cardinality grain="L" parameter should be your default for the first pass of a new dataset*


## Technology and Installation

The profiler is written in awk language. Why AWK? It is extremely portable, trusted and reliable. It is POSIX compliant and here to stay. 

*awk* the tool, not the language, is a core part of the unstripped unix kernal, and as such, is both robust and ubiquitous in all types of computing environments. This means the profiler can be introduced to highly locked down production systems - and can be run without installing new software. This is very useful - allowing one to retrofit data quality monitoring into production ETL systems with minimal governance overhead, and minimal risk to the existing services hosted apart from processing load. 

In addition to code being able to run on any unix system, it can also be run on windows systems. There is a compiled 64-bit version of awk released here: https://github.com/p-j-miller/wmawk2 Also - there are some linux emulators such as MKS (a 64-bit closed-source unix emulator for windows) or cygwin (a 32-bit open-source unix emulator for windows), both of which are common in enterprise production environments.

The later versions of the code have been tested with several implementations of the awk language:

    awk - available as standard in MacOS
    gawk - the GNU version of AWK, available for every 'nix system you can imagine.
    goawk - the implementation of AWK in the language go
    mawk - a high performance version of awk, optimised for speed

The test scripts can be used to run a performance test on a large file.
The results I got using the companies house dataset on my mac was:

| Command | Mean [s] | Min [s] | Max [s] | Relative |
|:---|---:|---:|---:|---:|
| `. test2.sh mawk` | 36.838 ± 1.661 | 33.435 | 38.606 | 1.00 |
| `. test2.sh goawk` | 70.097 ± 0.969 | 68.094 | 71.559 | 1.90 ± 0.09 |
| `. test2.sh gawk` | 110.419 ± 7.839 | 100.522 | 119.452 | 3.00 ± 0.25 |
| `. test2.sh awk` | 103.201 ± 3.506 | 100.074 | 111.921 | 2.80 ± 0.16 |

*it's worth noting GAWK would be faster if we used it's native sorting function, excluded for portability in this code*   

To performance tune on your system and data, check out hyperfine    
https://github.com/sharkdp/hyperfine/tree/master/doc


#### Installation for a Mac

    # to install on macOS:
     
    > brew install gawk
    > brew install mawk

install of goawk:

    # to install goawk, an excellent implemenation writen in go
    > brew install go
     
    # now link your paths:
    > thisaccount=`who | sed 's/ .*//g' | head -1`
    > echo 'export GOPATH="/Users/${thisaccount}/go"' >> ~/.bash_profile
    > echo 'PATH=$PATH:$GOPATH/bin' >> ~/.bash_profile
    
    # rerun your bash profile
    > ~/.bash_profile
    
    # now use the go package manager to install it in a one-liner
    $ go get github.com/benhoyt/goawk
    
    # now test it works!
    > goawk 'BEGIN { print "foo", 42 }'
      

Note - this code can also be converted to ansi-c and then compiled using awka, a recently updated version is here: https://github.com/noyesno/awka
Once convereted to c, a choice of compilers via LLVM may target your environment better. 


# Usage - bytefreq 

Run the data profiler example:

    awk -F"\t" -f bytefreq_v1.05.awk -v header="1" -v report="1" -v grain="L" testdata/testdata.tab

    awk -F"\t" -f bytefreq_v1.05.awk -v header="1" -v report="1" -v grain="H" testdata/testdata.tab


The example above shows the setting for a tab delimited file, but there are many advanced field and record separator 
choices available if you read the AWK documentation.    
     
Commandline options to set are:

    -f bytefreq_v1.05.awk        The -f option tells awk to run the profiler code. Be sure to include a fully qualified file path 
                                 to the code if your working directory is not where the code is sitting. 
 
     -F"\t"              # tab delimited
     -F"|"               # pipe delimited
     -F","               # flat comma delimited - does not meet csv parsing standards. See *parsers*

    -v header="1"        The command line option to set the row to use to pick up the headers in the file. 
                         If you set this value to row 1, it will use the first row as the header row. If you set it to X, the code 
                         will use the Xth row to pick up headers and ignore all proceeding lines in the file, a feature that can 
                         occasionally be very handy. The default value of this setting, if not explicitly set on the command 
                         line is "0", meaning, no header record.

    -v report="0"        Sets the output to a machine readable profile frequency dataset.
    -v report="1"        Sets the output to a human readable profile frequency report.
    -v report="2"        Sets the output to raw + profiled full volume data in a machine readable format.
    -v report="3"        Produces a key/val long format data (incl profiles and raw) for automated DQ remediation tooling. 

    -v grain="L"         Set the Less granular level of pattern formats in the output
    -v grain="H"         Set the Highly granular level of pattern formats in the output


    input.data           The file you wish to examine. Note if the working directory doesn't hold the file, you need to set this 
                         value to being the fully qualified path and file name. Can be a file glob. Skip header applied per file.


    > output.report.txt        This is the standard unix notation meaning 'redirect the output to a file', which if not set 
                               means the profiler will output it's metrics to STDOUT (standard out) be sure to use a fully qualified
                               name if you wish the output to be written to a different folder.


There is a test.sh script available to run. It has examples that are worth examining.

# Usage - charfreq

This program relies on the unix command "od" and turns each byte in the file into an octet.      

The awk program then reports frequencies of these in a human readable format.        
Use it to understand how to configure parsers for your data, and to do deeper investigations into issues.     

Do you set linefeed, or carriage returns, or both? Is the data in ASCII or EBCDIC? Are there odd binary characters in the file? Are there diacrit marks to accommodate?    
example:

     od -cb testdata/testdata.tab | awk -f charfreq.awk | sort -n

# Usage - fieldprofile.awk

This program helps to prove your parsers worked. It counts the fields per row, and reports on them.    
If your parsers failed, you will see there are some rows with the wrong number of fields.     
(These rows can be silently dropped by many programs - best to handle them explicity)

    awk -F"\t" -f fieldprofiler.awk testdata/*.tab | column -t -s $'\t'

example output:    

    filename                RowCount  NumFieldsSeen
    testdata/testdata.tab   1         0
    testdata/testdata.tab   1         12
    testdata/testdata.tab   1         5
    testdata/testdata.tab   49        16
    testdata/testdata2.tab  1         0
    testdata/testdata2.tab  1         12
    testdata/testdata2.tab  1         5
    testdata/testdata2.tab  49        16
    testdata/testdata3.tab  1         0
    testdata/testdata3.tab  1         12
    testdata/testdata3.tab  1         5
    testdata/testdata3.tab  49        16


# Example

In the UK, the postcode is a codified string constructed from an Incode and an Outcode. During manual data entry many mistakes can creep in.
The UK Companies House file in our test scripts, holds official registration details for the legal companies in the UK. Ideally, the postcodes would be correct.
Are they?

The repo includes a comprehensive *test.sh* script that will download the real data, and run the analysis for you. Try it out.

     # run it with your implementation preference, as a parameter:
     . test.sh gawk

It will fetch the data, unzip it, parse it, profile it, and report on it in the /out directory. 

Below is an example you can regenerate yourself, of a Low grain pass of the profiler on the PostCode field:

    > head -15 out/UkCompanySample.rpt1.txt; cat out/UkCompanySample.rpt1.txt | grep -i postcode 

which produces:

     
     
     
     		----------------------------------------------------------------           
     		 bytefreq: portable mask based data profiling for data quality 			
     		----------------------------------------------------------------			
     
     
     Data Profiling Report: 2021-02-11 22:23:11
     Name of file: testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip
     Examined rows: 592242

     column					count   pattern   	example
     =============================		=====   =======   	=======
     col_00010_RegAddress.PostCode		533108	A9 9A		RM10 9RJ
     col_00010_RegAddress.PostCode		47398	A9A 9A		WC1B 3SR
     col_00010_RegAddress.PostCode		11437	<<null>>		
     col_00010_RegAddress.PostCode		81	A9A		NP443FQ
     col_00010_RegAddress.PostCode		35	9		8603
     col_00010_RegAddress.PostCode		28	A9		M22
     col_00010_RegAddress.PostCode		23	A 9A		CRO 2LX
     col_00010_RegAddress.PostCode		22	A9   9A		M2   2EE
     col_00010_RegAddress.PostCode		14	9 9		100 8055
     col_00010_RegAddress.PostCode		14	A9 9 A		ST4 8 SP
     col_00010_RegAddress.PostCode		11	A9 A		PL6 SWR
     col_00010_RegAddress.PostCode		7	A 9		CH 1211
     col_00010_RegAddress.PostCode		6	A9 9A.		GL17 9XZ.
     col_00010_RegAddress.PostCode		6	A9A  9A		W1K  3JZ
     col_00010_RegAddress.PostCode		5	9A9 9A		0L6 9SJ
     col_00010_RegAddress.PostCode		5	A 9 9A		BB 9 7JU
     col_00010_RegAddress.PostCode		5	A9  9A		M5  4PF
     col_00010_RegAddress.PostCode		4	A9 A9A		SW1 P2AJ
     col_00010_RegAddress.PostCode		3	A		SHROPSHIRE
     col_00010_RegAddress.PostCode		3	A9 A9		A67 Y437
     col_00010_RegAddress.PostCode		3	A9-9		KY1-1003
     col_00010_RegAddress.PostCode		2	9A		1017BT
     col_00010_RegAddress.PostCode		2	A9 9		NJ07 666
     col_00010_RegAddress.PostCode		2	A9 9A9		N7 6A6
     col_00010_RegAddress.PostCode		2	A9 A 9A		SW1 W 0LS
     col_00010_RegAddress.PostCode		2	A9A 9 A		SW1E 6 DY
     col_00010_RegAddress.PostCode		2	A9A 9A.		EC1V 9EE.
     col_00010_RegAddress.PostCode		2	A9A 9A9		H3C 2N6
     col_00010_RegAddress.PostCode		2	A9A9A		SW1E5NE
     col_00010_RegAddress.PostCode		1	9A A		2L ONE
     col_00010_RegAddress.PostCode		1	A 9A9		WC 2R2
     col_00010_RegAddress.PostCode		1	A A		XXX XXX
     col_00010_RegAddress.PostCode		1	A-9		LT-44248
     col_00010_RegAddress.PostCode		1	A-9 9		CH-1 211
     col_00010_RegAddress.PostCode		1	A9 9A ...	M6 5PW ...
     col_00010_RegAddress.PostCode		1	A9 9A9 9A	BR3 4RHSE26 6SH
     col_00010_RegAddress.PostCode		1	A9.9A		W13.9ED
     col_00010_RegAddress.PostCode		1	A;A9 9A		L;N9 6NE
 
From this snippet of the report - notice we have summarised nearly 600,000 data point values into a short list to review that puts emphasis squarely on the long tail of poor quality records.
Our inspection teaches us that the majority of postcodes fall into two formats: "A9 9A" and "A9A 9A", and there is a tail of dubious non-conforming records we should examine.   
If we were to double check the long tail, we would quickly understand if these are exceptions, mistakes, or a mix, and could create remediation strategies.

To find the exact datapoints having the bad postcodes, we can run the following to find the first 30 real examples:

     # this line will read all datapoints for the postcode column, and exclude all "good" postcode formats. I've taken the top 30 bad records, and formatted them for inspection:

     cat out/UkCompanySample.raw3.txt | grep "RowNum\|col_00010_RegAddress.PostCode" | grep -v "\tA9 9A\t\|\tA9A 9A\t\|<<null>>" | head -30 |column -t -s $'\t' 

     report_date          filename                                              RowNum  colname                        grain  profile  rawval
     2021-02-11 23:32:31  testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip  2058    col_00010_RegAddress.PostCode  L      A9A      NG235ED
     2021-02-11 23:32:31  testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip  7519    col_00010_RegAddress.PostCode  L      A9A      TW89LF
     2021-02-11 23:32:31  testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip  8027    col_00010_RegAddress.PostCode  L      9        8022
     2021-02-11 23:32:31  testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip  11826   col_00010_RegAddress.PostCode  L      A9 A     IP1 JJ
     2021-02-11 23:32:31  testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip  13338   col_00010_RegAddress.PostCode  L      A9A      GU478QN
     2021-02-11 23:32:31  testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip  17969   col_00010_RegAddress.PostCode  L      A9A      NE349PE
     2021-02-11 23:32:31  testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip  19350   col_00010_RegAddress.PostCode  L      A9A 9 A  EC1V 1 NR
     2021-02-11 23:32:31  testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip  20925   col_00010_RegAddress.PostCode  L      A9 9A.   BR5 3RX.
     2021-02-11 23:32:31  testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip  27013   col_00010_RegAddress.PostCode  L      A9 9 A   SW18 4 UH
     2021-02-11 23:32:31  testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip  27746   col_00010_RegAddress.PostCode  L      A9 A     BA14 HHD
     2021-02-11 23:32:31  testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip  30151   col_00010_RegAddress.PostCode  L      A9       BB14006
     2021-02-11 23:32:31  testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip  31997   col_00010_RegAddress.PostCode  L      A9A      DE248UQ
     2021-02-11 23:32:31  testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip  40692   col_00010_RegAddress.PostCode  L      A9A9A    EC1V2NX
     2021-02-11 23:32:31  testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip  40803   col_00010_RegAddress.PostCode  L      A 9      BLOCK 3
     2021-02-11 23:32:31  testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip  44375   col_00010_RegAddress.PostCode  L      A9A      NP79BT
     2021-02-11 23:32:31  testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip  44648   col_00010_RegAddress.PostCode  L      A9A      CO92NU
     2021-02-11 23:32:31  testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip  45701   col_00010_RegAddress.PostCode  L      A 9A     CRO 9XP
     2021-02-11 23:32:31  testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip  48052   col_00010_RegAddress.PostCode  L      9 9      20 052
     2021-02-11 23:32:31  testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip  49938   col_00010_RegAddress.PostCode  L      A9A      BS164QG
     2021-02-11 23:32:31  testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip  50668   col_00010_RegAddress.PostCode  L      A;A9 9A  L;N9 6NE
     2021-02-11 23:32:31  testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip  51579   col_00010_RegAddress.PostCode  L      A9 9 A   WR9 9 AY
     2021-02-11 23:32:31  testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip  59153   col_00010_RegAddress.PostCode  L      A9   9A  M2   2EE
     2021-02-11 23:32:31  testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip  59916   col_00010_RegAddress.PostCode  L      A9A  9A  W1K  3JZ
     2021-02-11 23:32:31  testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip  60279   col_00010_RegAddress.PostCode  L      A9A      SK104NY
     2021-02-11 23:32:31  testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip  60897   col_00010_RegAddress.PostCode  L      9        0255
     2021-02-11 23:32:31  testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip  64723   col_00010_RegAddress.PostCode  L      9        94596
     2021-02-11 23:32:31  testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip  64946   col_00010_RegAddress.PostCode  L      A9A      YO152QD
     2021-02-11 23:32:31  testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip  67080   col_00010_RegAddress.PostCode  L      A9       SW1
     2021-02-11 23:32:31  testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip  68410   col_00010_RegAddress.PostCode  L      9A A     2L ONE


