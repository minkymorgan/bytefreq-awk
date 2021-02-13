# ByteFreq Data Profiler

Author: Andrew J Morgan  
Company: 6point6.co.uk  
Provenance: forked from https://github.com/minkymorgan/bytefreq  
License: GPLv3  

Main programs:

bytefreq_v1.05.awk  
charfreq.awk  
fieldprofiler.awk


## Introduction
*bytefreq*, short for "byte frequency" is a data quality toolkit for data profiling, written in the portable awk language. The library implements a number of data transformations and reports helping you do data quality studies using Mask-Based Data Profiling techniques.

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

    awk - as available as standard in MacOS
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

#### Installation for a Mac
    # to install on macOS:
     
    > brew install gawk
    > brew install mawk

    # to install goawk, an recent implemenation writen in go
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
    
There is a timer.log file in the repo - that has a comparison of the performance of these tools. mawk is the fastest. 
At some point I will do a performance analysis. Also to do - try compiling a version with GRAALVM and testing that.

Note - this code can also be converted to ansi-c and then compiled using awka, a recently updated version is here: https://github.com/noyesno/awka
Once convereted to c, a choice of compilers via LLVM may target your environment better. 


# Usage

The code has only a few simple configuration options carefully chosen to meet the needs of many. The three main output choices 
configurable are:

-v report ="0" -- (0) produce profile metrics data, directly loadable to a database or data quality rules engine
-v report ="1" -- (1) produce profile metrics text reports, in a format easily printed 
-v report ="2" -- (2) produce a modified copy of your input data, having additional columns containing the calculated profile 
strings that can be loaded directly to a database or fed into a data quality rules engine.

Option Notes:

For option (0), the profiler will generate a metrics file having 4 column tab delimited file having the following delimited 
file layout:

<filename><column_identifier><count><pattern>

where the column names specified in the header are prefixed with .col_<column_id>_. 

For option (1) the report output includes these same fields but formatted into a more readable layout as seen in the example
given in the .What it does. section.
For option (2), the file will output the original data alongside new columns holding the calculated profiles. This is a critical 
output, as when a profile is found that needs investigation, this output can be used to find the matching raw data records of 
interest. The simplest was to do this is using filters in excel, but more sophisticated options are also available.


#### Command Line Options
The program can be called from the command line as follows in this example:

    awk -F"\t" -f bytefreq_v1.05.awk -v header="1" -v report="1" -v grain="L" testdata/testdata.tab

##### Usage:

    -F"\t"        Use the native -F option in AWK to set your input data file delimiter, also known as it's Field Separator, FS. Notice there is no space between -F and the delimiter.
    
The example above shows the setting for a tab delimited file, but there are many advanced field and record separator 
choices available if you read the AWK documentation. Common delimiters are:   
     
     -F"\t"   # tab delimited
     -F"|"    # pipe delimited
     -F","    # flat comma delimited - does not meet csv parsing standards -- use python pre-parsing. See *parsers*

Other options to set are:

    -f bytefreq_v1.05.awk        The -f option tells awk to run the profiler code. Be sure to include a fully qualified file path 
                                 to the code if your working directory is not where the code is sitting. 


    -v header="1"        The command line option to set the row to use to pick up the headers in the file. 
                         If you set this value to row 1, it will use the first row as the header row. If you set it to X, the code 
                         will use the Xth row to pick up headers and ignore all proceeding lines in the file, a feature that can 
                         occasionally be very handy. The default value of this setting, if not explicitly set on the command 
                         line is "0", meaning, no header record.
    -v report="0"        Sets the output to a machine readable profile frequency dataset.
    -v report="1"        Sets the output to a human readable profile frequency report.
    -v report="2"        Sets the output to raw + profiled full volume data in a machine readable format.
    -v grain="L"         Set the Less granular level of pattern formats in the output
    -v grain="H"         Set the Highly granular level of pattern formats in the output


    input.data          The file you wish to examine. Note if the working directory doesn't hold the file, you need to set this 
                        value to being the fully qualified path and file name.


    > output.report.txt        This is the standard unix notation meaning 'redirect the output to a file', which if not set 
                               means the profiler will output it's metrics to STDOUT (standard out) be sure to use a fully qualified
                               name if you wish the output to be written to a different folder.


#### NOTES ON PARALLEL RUNNING

Should you wish, you can run this program on chunks of data using parallel, using a handy tool found at http://www.gnu.org/software/parallel

    An example of the syntax is:
     
     # create a second test file, we'll try to run these two files in parallel
     cat testdata.tab > testdata2.tab
      
     # pass a file glob to parallel, and run the profiler over the files in parallel. Fold output into single report. 
     ls *.tab | parallel -q gawk -F"\t" -f bytefreq_v1.04.awk -v report="0" -v header="1" -v grain="H" ::: | gawk -F"\t" 'NF==6 {print $0}' > output.rpt

Parallel should be cited if used in acedemic work.

    @article{Tange2011a,
        title = {GNU Parallel - The Command-Line Power Tool},
        author = {O. Tange},
        address = {Frederiksberg, Denmark},
        journal = {;login: The USENIX Magazine},
        month = {Feb},
        number = {1},
        volume = {36},
        url = {http://www.gnu.org/s/parallel},
        year = {2011},
        pages = {42-47},
        doi = {10.5281/zenodo.16303}
        }


