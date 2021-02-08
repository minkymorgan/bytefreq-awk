#!/usr/local/bin/gawk
#
#----------------------------------------------------------------#
#
#             
#              |       |     
#              |--\  /-|-.-.             .
#              |__/\/  | \/_            . :.
#               ___/__  __ __  __   ___/ . .
#              / ._|| | | || \/  \ / _ \ . : .: 
#              \_  \| |_| || | | || [_] | .. 
#              \___/|____/||_|_|_| \___/ ..
#                                  / . ..  .:
#                                   .: .  .:  
#                
#
# Data Strategy | Data Architecture | Data Science & Engineering 
#----------------------------------------------------------------#
#
# ByteFreq_1.0.5 Data Profiling Software
# Copyright ByteSumo Limited, 2014-2021. All rights reserved.
# License: GPLv3
#
# Instructions for use
# 
# DEPENDECIES:
# Install or upgrade gawk. On a mac, "brew install gawk". I suggest you also get gsed. "brew install gsed"
#
# USAGE:
# on the commandline, you call the profiler as a gawk script, here are some examples, which is also the test suite data:
#
#     #GENERATE HUMAN READABLE REPORT - popular eyeball inspection report
#     gawk -F"\t" -f bytefreq_v1.05.awk -v header="1" -v report="1" -v grain="L" testdata/UKCompanySample.pip > UkCompanySample.rpt1.txt
# 
#     #GENERATE DATABASE LOADABLE REPORT SUMMARY OUTPUTS - for automation, used for drift in quality analysis 
#     gawk -F"|" -f bytefreq_v1.05.awk -v header="1" -v report="0" -v grain="L" testdata/UKCompanySample.pip > UkCompanySample.rpt0.txt 
#
#     #GENERATE DATABASE LOADABLE RAW+PROFILED DATA - for manual cleansing, find bad datapoints and fix them
#     gawk -F"|" -f bytefreq_v1.05.awk -v header="1" -v report="2" -v grain="L" testdata/UKCompanySample.pip > UkCompanySample.raw2.txt
#
#     #GENERATE DATABASE LOADABLE LONGFORMAT RAW DATA - for automated remediation
#     gawk -F"|" -f bytefreq_v1.05.awk -v header="1" -v report="3" -v grain="L" testdata/UKCompanySample.pip > UkCompanySample.raw3.txt
#
# The options on the command line are: 
#      use standard awk -F option in Awk to set your delimiter for the file
#      use standard awk -v option to set global variables from the command line:
#
#      -v header="0"   indicates your input data has not got a header row.
#      -v header="1"   indicates your input data has a header in row 1, which is recommended.
#
#      -v report="0"   outputs profile frequency reports, loadable as data 
#      -v report="1"   outputs profile frequency reports, human readable and printable 
#      -v report="2"   outputs your raw input data alongside formated profile strings. doubles your columns
#      -v report="3"   outputs your raw + profile data stacked in a long format, suitable for clikhouse reporting
#                      ** note this does not aggregate the data. You get row*column outputs. Aggregate it in a proper database.
#      -v grain="H"    is the option to have granular reports, "L" is the option for simplified profiles
#      -v grain="L"    is the option to have Low Grain reports - best for high 
#      -v awk="awk"    experimental: override to allow using old versions of awk that can't do asort
#                      ** note the override only works well on non-human readable reports
#                       
################################################################################################################# 
#  included as only GAWK has asort - you can define your own array sorting function here, or comment this out if you wish for gawk:
############### I have inlined the module from runawk below
#  
# Written by Aleksey Cheusov <vle@gmx.net>, public domain
#
# This awk module is a part of RunAWK distribution,
#        http://sourceforge.net/projects/runawk
#
############################################################

# =head2 quicksort.awk
#
# =over 2
#
# =item I<quicksort (src_array, dest_remap, start, end)>
#
# The content of `src_array' is sorted using awk's rules for
# comparing values. Values with indices in range [start, end] are
# sorted.  `src_array' array is not changed.
# Instead dest_remap array is generated such that
#
#   Result:
#     src_array [dest_remap [start]] <=
#        <= src_array [dest_remap [start+1]] <=
#        <= src_array [dest_remap [start+2]] <= ... <=
#        <= src_array [dest_remap [end]]
#
# `quicksort' algorithm is used.
# Examples: see demo_quicksort and demo_quicksort2 executables
#
# =item I<quicksort_values (src_hash, dest_remap)>
#
# The same as `quicksort' described above, but hash values are sorted.
#
#   Result: 
#     src_hash [dest_remap [1]] <=
#        <= src_hash [dest_remap [2]] <=
#        <= src_hash [dest_remap [3]] <= ... <=
#        <= src_hash [dest_remap [count]]
#
# `count', a number of elements in `src_hash', is a return value.
# Examples: see demo_quicksort* executables.
#
# =item I<quicksort_indices (src_hash, dest_remap)>
#
# The same as `quicksort' described above, but hash indices are sorted.
#
#   Result:
#     dest_remap [1] <=
#        <= dest_remap [2] <=
#        <= dest_remap [3] <= ... <=
#        <= dest_remap [count]
#
# `count', a number of elements in `src_hash', is a return value.
#
# =back
#

function __quicksort (array, index_remap, start, end,
       MedIdx,Med,v,i,storeIdx)
{
	if ((end - start) <= 0)
		return

	MedIdx = int((start+end)/2)
	Med = array [index_remap [MedIdx]]

	v = index_remap [end]
	index_remap [end] = index_remap [MedIdx]
	index_remap [MedIdx] = v

	storeIdx = start
	for (i=start; i < end; ++i){
		if (array [index_remap [i]] < Med){
			v = index_remap [i]
			index_remap [i] = index_remap [storeIdx]
			index_remap [storeIdx] = v

			++storeIdx
		}
	}

	v = index_remap [storeIdx]
	index_remap [storeIdx] = index_remap [end]
	index_remap [end] = v

	__quicksort(array, index_remap, start, storeIdx-1)
	__quicksort(array, index_remap, storeIdx+1, end)
}

function quicksort (array, index_remap, start, end,             i)
{
	for (i=start; i <= end; ++i)
		index_remap [i] = i

	__quicksort(array, index_remap, start, end)
}

function quicksort_values (hash, remap_idx,
   array, remap, i, j, cnt)
{
	cnt = 0
	for (i in hash) {
		++cnt
		array [cnt] = hash [i]
		remap [cnt] = i
	}

	quicksort(array, remap_idx, 1, cnt)

	for (i=1; i <= cnt; ++i) {
		remap_idx [i] = remap [remap_idx [i]]
	}

	return cnt
}

function quicksort_indices (hash, remap_idx,
   array, i, cnt)
{
	cnt = 0
	for (i in hash) {
		++cnt
		array [cnt] = i
	}

	quicksort(array, remap_idx, 1, cnt)

	for (i=1; i <= cnt; ++i) {
		remap_idx [i] = array [remap_idx [i]]
	}

	return cnt
}
#use "quicksort.awk"
############# and below is how to use the sort functions
# This demo sorts the input lines as strings and outputs them to stdout
#
# Input files for this demo: examples/demo_quicksort.in
#
#{
#	array [++count] = $0
#}
#
#END {
#	quicksort(array, remap, 1, count)
#
#	for (i=1; i <= count; ++i){
#		print array [remap [i]]
#	}
#}

################################################################################################################
# inititalize code

BEGIN {

##### sort #### add this in to support our homebrew_asort function
current_index = 1


# this section processes the command line options for headers, and output style
if ( header == 1 ){
	   header=1
        }
        else { 
           header=0
        } # end of the else and if
if ( report == 0 ){
           report=0
        }
        else if (report == 2) {
           report=2
        }
        else if (report == 3){
           report=3
	   tabsep = "\t"
	} 
        else {
	   report=1
	}# end of the else and if

if ( grain == "L" ){
           grain="L"
        }
        else {
           grain="H"
        } # end of the else and if


       # retrieve the current date and minute
       "date \"+%Y-%m-%d %H:%M:%S\" " | getline today
       # the above line sets the value of the variable today with the date as retrived from the command line program date. Works on nix.

} #end of BEGIN

################################################################################################################
# calculate and count formats

NR == header {

# note here I add in the column numbers to the col names.
# that needs doing through adding it to a large number so the non-numeric sortation is correct in awk

  hout = ""


  for (field = 1; field <= NF ; field++) {

     clean_colname = $(field)

	  gsub(/ /,"",clean_colname)
	  gsub(/_/,"",clean_colname)
	  gsub(/\t/,"",clean_colname)
	  # gsub(/|/,"",clean_colname)

  	 if (field >1) {hout = hout FS}	

	 if (report == 2){
		hout = hout clean_colname FS "DQ_"clean_colname 
	 } else {

	    zcoln = "col_"(100000+field)
	    gsub(/^col_1/,"col_",zcoln)
		names[field]=zcoln"_"clean_colname	
	 }

  } # this is the end of the field loop 

  # if we are outputting raw with profiles data, print the header now while we've calc'd it

  if (report == 2){
	print hout
  } else if (report == 3) {
        print "report_date" tabsep "filename" tabsep "colname" tabsep "RowNum" tabsep "grain" tabsep "profile" tabsep "rawval" 
  }


} # end header 



NR > header { 
 # notice we only profile data in the rows AFTER the header, so this can help to skip headers on data produced in reports
 # I've changed this to do the find and replace on each field, as nulls were playing up if you didn't specify delim

  out = ""
  for (field = 1; field <= NF ; field++) {

		prof = $(field);

		# if the report is type 2, the doubled raw +format data, we need to add a delimiter here just after field 2
		if (field > 1) {out = out FS}

		if ( grain == "H" ){
			gsub(/[[:lower:]]/,"a",prof)
 			gsub(/[[:upper:]]/,"A",prof)
 			gsub(/[[:digit:]]/,"9",prof)
			gsub(/\t/,"T",prof)
		}
		else {
			gsub(/[[:lower:]]+/,"a",prof)
			gsub(/[[:upper:]]+/,"A",prof)
			gsub(/[[:digit:]]+/,"9",prof)	
	                gsub(/\t/,"T",prof)	
		}

 		# save the formatted string and increment the count in a big multidimensional array 
		
		# note, here we swap out null values for <null> so it works properly

		pattern=prof
		if ( pattern == "" ){
       			pattern="<<null>>"
        	} #end of if statement


		# here, if I'm counting the frequency I add the data to the arrary, or if a report=3, print it.
      		

		if (report == 2) {
	       		out = out $(field) FS pattern

  		} else if (report == 3) {
                        temp_colname = 100000 + field
			gsub(/^./, "" ,temp_colname)			
			
			if (names[field] != "" ) {
				temp_colname = names[field]
			} else {
				temp_colname = "col_"temp_colname
 			}
                        # below we print out a line of data for each field in this row 
			print today tabsep FILENAME tabsep NR tabsep temp_colname tabsep grain tabsep pattern tabsep $(field)

		} else { 
        		allcolumns[field, pattern]++ 
			allpatterns[field, pattern] = $(field)
		}


  } # end of for field loop


# we are are not counting the formats, then just output the row
if (report == 2) {
   print out 
}


} # end of main loop

###########################################################################################################
# process the counts

END {

  # only do this post analysis where we count.  
  if (report < 2 ) {

	# loop through the number of fields I have, inspect every value in the multidimensional arrary to copy out the field
        # values into a new array that I can sort then print out.

		j=1	
		for( string in allcolumns) {
			split(string, separate, SUBSEP)

			# now I can separate my bits of info: field, arrayID, frm_string, count, num 
			# with my separated items, retrieve the count for this pattern	

			countval = allcolumns[separate[1], separate[2]]
			example = allpatterns[string]

			# print(FILENAME" "names[separate[1]]" "(1000000000000 - countval),"\t\t"countval, "\t\t"separate[2])
				
			# copy over the report line items into a new array indexed with a sequence number

			# add in a bit here to force column names if no header, to being field_001, field_002 etc


			if(names[separate[1]] == "" ) {
				printnames[separate[1]]="##column_"(100000000+separate[1])
			} else {
				printnames[separate[1]]=names[separate[1]]
			} # end of field name check

			linetext=FILENAME"|"printnames[separate[1]]"|"(1000000000000 - countval)"|"countval"|"separate[2]"\t\t"example
			lineitems[j]=linetext
	
		j++		
		} # end of loop through allcolumns

######################################################################################################
# sort output
# I have implemented a sort function in this script to make it portable to many awk implementations

    for( i in lineitems) countof_reportitems++
    print("#### TEST :lineitems count is: "countof_reportitems) 

    quicksort(lineitems, reportitems_idx, 1, countof_reportitems)


    
#####################################################################################################

# print output

		# This section prints the output, either a report or a datafile as specified on the command line.
		#

		if ( report == 1 ){
		print("\n\n")

		print "		----------------------------------------------------------------           "	
		print "		 bytefreq: portable mask based data profiling for data quality 			"
		print "		----------------------------------------------------------------			"
		print ""
		#print "Author: Andrew Morgan"
		print ""
		print("Data Profiling Report: "today) 
		print ""

		}
		prev_finalcolname ="X"

		for (line = 1; line <= countof_reportitems; line++) {

			# now split the line to remove my internal sort key, that's the 100000000 - count thing.
			# below we retrive the line via the sorted re-index
			currline = lineitems[reportitems_idx[line]]

			split(currline, linefield, "|")

			# Don't forget to clean off the sort key from unheadered field names
                        finalcolname = linefield[2]
			#gsub(/##column_1000/,"col_",finalcolname) 
			
			
			# print off the final sorted report line items

			if ( report == 0 ){
				print(today"\t"linefield[1]"\t"finalcolname"\t"grain"\t"linefield[4]"\t"linefield[5])	 
				prev_finalcolname=finalcolname	
			}
        		else {
				# if we hit a new column, print header, and then record 
				if (prev_finalcolname != finalcolname){
					fhead=linefield[1]
					fcol=finalcolname	
					fpatt=linefield[5]
					gsub(/./," ",fhead)
					gsub(/^..../,"file",fhead)
					gsub(/./," ",fcol)
					gsub(/^....../,"column",fcol)
	
					print("\n"fhead"\t"fcol"\t\tcount\tpattern\t\texample")

					gsub(/./,"=",fhead)
				 	gsub(/./,"=",fcol)
					print(fhead"\t"fcol"\t\t=====\t=======\t\t=======")

					print(linefield[1]"\t"finalcolname"\t\t"linefield[4]"\t"linefield[5])		
					prev_finalcolname=finalcolname	
				} 
				else {
					print(linefield[1]"\t"finalcolname"\t\t"linefield[4]"\t"linefield[5])
					prev_finalcolname=finalcolname	
				}

		        } # end of the main reporting  if/else


		} # end of loop through sorted report lines 

  } # end of the report !=2 to check we print analysis  
} # end of END





