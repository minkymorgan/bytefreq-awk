
# this speed tests the different awk implementations


time . test2.sh awk > timer.log 2>&1
time . test2.sh awk >> timer.log 2>&1
time . test2.sh awk >> timer.log 2>&1

time . test2.sh gawk >> timer.log 2>&1
time . test2.sh gawk >> timer.log 2>&1
time . test2.sh gawk >> timer.log 2>&1

time . test2.sh goawk >> timer.log 2>&1
time . test2.sh goawk >> timer.log 2>&1
time . test2.sh goawk >> timer.log 2>&1

time . test2.sh mawk >> timer.log 2>&1
time . test2.sh mawk >> timer.log 2>&1
time . test2.sh mawk >> timer.log 2>&1


