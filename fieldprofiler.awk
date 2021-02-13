
# FieldProfiler.awk
# This little script will profile the number of fields per record
# helping to check the integrity of your data parsing's output schema

# USAGE
#
#     Here is an example of how to double check your data has consistent fields per row:
#
#     awk -F"\t" -f fieldprofiler.awk testdata/*.tab | sort -rn | column -t -s $'\t'
#
#

BEGIN{

     OFS="\t"

} #endBegin
 
{ #loop

     # for each row, tabulate the count of rows, indexed by the number of fields found in them

     # uncomment to access raw data for file, field number 
     # print FILENAME, NF

     filerowcount[FILENAME, NF]++
  
} #endloop


# with the final array, output a report detailing the findings
END {

     # print header
     print("filename", "RowCount", "NumFieldsSeen")

     # sort our array by rowcounts
     for (key in filerowcount) {

         split(key, vals, SUBSEP)
         namedfile = vals[1]
         numfields = vals[2]
         rowcount = filerowcount[namedfile, numfields]

     print (namedfile, rowcount, numfields) | " sort -n"

     } #endFor

} #endEnd
