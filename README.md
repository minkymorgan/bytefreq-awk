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


There is a test.sh script available to run. It will check if you have a test file sourced from the UK Companies House website, and if not fetch it with wget, and then step by step run a full size example of the tools included in this repo.    

     # run it with your implementation preference, as a parameter:
     . test.sh gawk

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

Here is an example output of a Low grain pass of the profiler:

    > head -15 out/UkCompanySample.rpt1.txt; cat out/UkCompanySample.rpt1.txt | grep -i postcode 

which produces:

     
     
     
     		----------------------------------------------------------------           
     		 bytefreq: portable mask based data profiling for data quality 			
     		----------------------------------------------------------------			
     
     
     Data Profiling Report: 2021-02-11 22:23:11
     Name of file: testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip
     Examined rows: 592242
     
     
     file                                                	column               			count	pattern		example
     ====================================================	=====================			=====	=======		=======
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		533108	A9 9A		RM10 9RJ
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		47398	A9A 9A		WC1B 3SR
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		11437	<<null>>		
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		81	A9A		NP443FQ
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		35	9		8603
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		28	A9		M22
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		23	A 9A		CRO 2LX
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		22	A9   9A		M2   2EE
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		14	9 9		100 8055
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		14	A9 9 A		ST4 8 SP
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		11	A9 A		PL6 SWR
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		7	A 9		CH 1211
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		6	A9 9A.		GL17 9XZ.
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		6	A9A  9A		W1K  3JZ
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		5	9A9 9A		0L6 9SJ
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		5	A 9 9A		BB 9 7JU
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		5	A9  9A		M5  4PF
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		4	A9 A9A		SW1 P2AJ
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		3	A		SHROPSHIRE
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		3	A9 A9		A67 Y437
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		3	A9-9		KY1-1003
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		2	9A		1017BT
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		2	A9 9		NJ07 666
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		2	A9 9A9		N7 6A6
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		2	A9 A 9A		SW1 W 0LS
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		2	A9A 9 A		SW1E 6 DY
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		2	A9A 9A.		EC1V 9EE.
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		2	A9A 9A9		H3C 2N6
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		2	A9A9A		SW1E5NE
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		1	9A A		2L ONE
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		1	A 9A9		WC 2R2
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		1	A A		XXX XXX
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		1	A-9		LT-44248
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		1	A-9 9		CH-1 211
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		1	A9 9A ...		M6 5PW ...
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		1	A9 9A9 9A		BR3 4RHSE26 6SH
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		1	A9.9A		W13.9ED
     testdata/BasicCompanyData-2021-02-01-part6_6.csv.pip	col_00010_RegAddress.PostCode		1	A;A9 9A		L;N9 6NE


From this snippet of the report - notice we have summarised nearly 100k of values into a short list that puts emphasis on the long tail of poor quality records.
Our inspection teaches us that the majority of postcodes fall into two formats: "A9 9A" and "A9A 9A", and there is a tail of dubious non-conforming records we should examine.   
If we were to double check the long tail, we would quickly understand if these are exceptions, mistakes, or a mix, and could create remediation strategies.










 
