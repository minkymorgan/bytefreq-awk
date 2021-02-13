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
    
    1) profile the bytes (characters) in a file 
    2) profile columns per row in a file (find parser errors)
    3) generate Mask-Based data profiling reports at multiple grains
    4) generate datasets suitable for data quality remediation engines

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

The profiler is written in awk language, and there is a very specific reason for this. It is a "domain specific language" having a POSIX definition, which is stable over time. Code I write today can be run without change for decades to come. The code is also extremely portable. 
 
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


# Usage

Run the example:

    awk -F"\t" -f bytefreq_v1.05.awk -v header="1" -v report="1" -v grain="L" testdata/testdata.tab

    awk -F"\t" -f bytefreq_v1.05.awk -v header="1" -v report="1" -v grain="H" testdata/testdata.tab


The example above shows the setting for a tab delimited file, but there are many advanced field and record separator 
choices available if you read the AWK documentation. Common delimiters are:   
     
     -F"\t"   # tab delimited
     -F"|"    # pipe delimited
     -F","    # flat comma delimited - does not meet csv parsing standards. See *parsers*

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

