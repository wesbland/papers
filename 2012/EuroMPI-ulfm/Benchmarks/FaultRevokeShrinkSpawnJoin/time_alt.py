#!/opt/local/bin/python
#import numpy, re, sys
import re, sys

file = open(sys.argv[1], "r")
ranks = int(sys.argv[2])
runs = int(sys.argv[3])

#
# 0 == Display Rank 0 only
# 1 == Display Average over all ranks
display = 0

detect = list()
revoke = list()
shrink = list()
spawn = list()
rollback = list()
merge = list()

for i in range(runs):
    detect.append(0)
    revoke.append(0)
    shrink.append(0)
    spawn.append(0)
    rollback.append(0)
    merge.append(0)

lines = file.readlines()

if display == 0:
    print("#RUNS: " + str(runs))

for line in lines:
    values = line.split()
    if len(values) == 0 or values[0].startswith("#"):
        continue

    run = runs - int(values[0])
    rank = int(values[1])

    if run > runs:
        run = runs
        break

# Display the amount of time spent in each phase on rank 0
    if rank == 0 and display == 0:
        print(  str(run) + "\t" + 
                str(float(values[2])) + "\t" +
                str(float(values[3])) + "\t" +
                str(float(values[4])) + "\t" +
                str(float(values[5])) + "\t" +
                str(float(values[6])) + "\t" +
                str(float(values[7])) );

    detect[run] = detect[run] + float(values[2]);
    revoke[run] = revoke[run] + float(values[2]);
    shrink[run] = shrink[run] + float(values[2]);
    spawn[run]  = spawn[run]  + float(values[2]);
    rollback[run] = rollback[run] + float(values[2]);
    merge[run] = merge[run] + float(values[2]);

# Display the average amount of time spent in each phase by all ranks
if display != 0:
    print("#RUNS: " + str(runs))
    for i in range(runs):
        print(  str(i) + "\t" + 
                str(detect[i] / float(ranks - 1) ) + "\t" +
                str(revoke[i] / float(ranks - 1) ) + "\t" + 
                str(shrink[i] / float(ranks - 1) ) + "\t" + 
                str(spawn[i] / float(ranks - 1) ) + "\t" +
                str(rollback[i] / float(ranks - 1) ) + "\t" +
                str(merge[i] / float(ranks - 1) ))

exit(0)

# Plot the average amount of time spent in each phase on each rank
#print("#RUNS: " + str(run))
#for i in range(ranks):
#    detect[i].remove(min(detect[i]))
#    revoke[i].remove(min(revoke[i]))
#    shrink[i].remove(min(shrink[i]))
#    spawn[i].remove(min(spawn[i]))
#    rollback[i].remove(min(rollback[i]))
#    merge[i].remove(min(merge[i]))
#
#    detect[i].remove(max(detect[i]))
#    revoke[i].remove(max(revoke[i]))
#    shrink[i].remove(max(shrink[i]))
#    spawn[i].remove(max(spawn[i]))
#    rollback[i].remove(max(rollback[i]))
#    merge[i].remove(max(merge[i]))
#
#    print(str(i) + "\t" +
#            str(numpy.average(detect[i])) + "\t" +
#            str(numpy.average(revoke[i])) + "\t" +
#            str(numpy.average(shrink[i])) + "\t" +
#            str(numpy.average(spawn[i])) + "\t" +
#            str(numpy.average(rollback[i])) + "\t" +
#            str(numpy.average(merge[i])))
