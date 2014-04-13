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
# ByteFreq_1.0.4 Data Profiling Software
#
#
# Instructions for use
#
# on the commandline, you call the profiler as a gawk script: 
#
# gawk -F"\t" -f bytefreq_v1.02.awk -v header="1" -v report="1" -v grain="H" yourfile.tab
#
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
#
#      -v grain="H"    is the option to have granular reports, "L" is the option for simplified profiles
#
################################################################################################################# 



################################################################################################################
# inititalize code

BEGIN {
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
        else {
	   report=1
	}# end of the else and if

if ( grain == "L" ){
           grain="L"
        }
        else {
           grain="H"
        } # end of the else and if


} #end of BEGIN

################################################################################################################
# calculate and count formats

NR == header {

# note here I add in the column numbers to the col names.
# that needs doing through adding it to a large number so the non-numeric sortation is correct in awk

  hout = ""
  gsub(/ /,"",$0)
  gsub(/_/,"",$0)
  gsub(/\t/,"",$0)
  gsub(/|/,"",$0)

  for (field = 1; field <= NF ; field++) {

  	 if (field >1) {hout = hout FS}	

	 if (report == 2){
		hout = hout clean FS "DQ_" $(field) 
	 } else {
		names[field]="##column_"(100000000+field)"_"$(field)	
	 }

  } # this is the end of the field loop 

  # if we are outputting raw with profiles data, print the header now while we've calc'd it

  if (report == 2){
	print hout
  }


} # end header 



NR > header { 
 # notice we only profile data in the rows AFTER the header, so this can help to skip headers on data produced in reports
 # I've changed this to do the find and replace on each field, as nulls were playing up if you didn't specify delim

  out = ""
  for (field = 1; field <= NF ; field++) {

		prof = $(field);

		# if the report is type 2, the doubled raw +format data, add delim here
		if (field >1) {out = out FS}

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
  if (report != 2) {

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
		# sort the lineitmes now, which can be done using an alpha sort, because of my trick with 100000000000 
	        # note that not all awk implementations support asort. gawk should do if the version is newish		
		reportitems = asort(lineitems)

#####################################################################################################
# print output

		# This section prints the output, either a report or a datafile as specified on the command line.
		# A license notice is printed on all output as this is an evaluation copy.

		if ( report == 1 ){
		print("\n\n")
		}
		prev_finalcolname ="X"

		for (line = 1; line <= reportitems; line++) {

			# now split the line to remove my internal sort key, that's the 100000000 - count thing.
			split(lineitems[line], linefield, "|")

			# Don't forget to clean off the sort key from unheadered field names
                        finalcolname = linefield[2]
			#gsub(/##column_1000/,"col_",finalcolname) 
			
			
			# print off the final sorted report line items

			if ( report == 0 ){
				print(linefield[1]"\t"finalcolname"\t"linefield[4]"\t"linefield[5])	 
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
	
					print("\n"fhead"\t"fcol"\t\tcount\tpattern")

					gsub(/./,"=",fhead)
				 	gsub(/./,"=",fcol)
					print(fhead"\t"fcol"\t\t=====\t=======")

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

print("\n Copyright Andrew Morgan, 2010.")
print(" EVALUATION COPY of the ByteFreq Data Profiler. No Production Use Permitted.")

} # end of END





