#!/opt/local/bin/python
import numpy, re, sys

file = open(sys.argv[1], "r")
ranks = int(sys.argv[2])
runs = int(sys.argv[3])

detect = [[] for r in range(ranks)]
revoke = [[] for r in range(ranks)]
shrink = [[] for r in range(ranks)]
spawn = [[] for r in range(ranks)]
rollback = [[] for r in range(ranks)]
merge = [[] for r in range(ranks)]
total = [[] for r in range(ranks)]

lines = file.readlines()

def average(seq, ranks, i):
    sum = 0.0
    num = 0;
    for r in range(ranks):
        if( r < len(seq) and i < len(seq[r]) ):
            num += 1
            sum += float( seq[r][i] )
    return sum/float(num)

def bestofaverage(seq, ranks, runs):
    best = -1.0
    besti = -1
    for i in range(runs):
        sum = 0.0
        num = 0
        for r in range(ranks):
            if( r < len(seq) and i < len(seq[r]) ):
                num += 1
                sum += float( seq[r][i] )
        if( best == -1.0 or sum/float(num) < best ):
            best = sum/float(num)
            besti = i
    return besti

for line in lines:
    values = line.split()
    if len(values) == 0 or values[0].startswith("#"):
        continue

    run = runs - int(values[0])
    rank = int(values[1])

    if run > runs:
        run = runs
        break

    detect[rank].append(float(values[2]))
    revoke[rank].append(float(values[3]))
    shrink[rank].append(float(values[4]))
    spawn[rank].append(float(values[5]))
    rollback[rank].append(float(values[6]))
    merge[rank].append(float(values[7]))
    t = 0.0
    for i in range(2, 7):
        t += float(values[i])
    total[rank].append(float(t))


# Plot the average amount of time spent in each phase
#print("#RUNS: " + str(run))
#for i in range(run):
#    print(  str(i)                          + "\t" + 
#            str(average(detect, ranks, i))   + "\t" +
#            str(average(revoke, ranks, i))   + "\t" + 
#            str(average(shrink, ranks, i))   + "\t" + 
#            str(average(spawn, ranks, i))    + "\t" +
#            str(average(rollback, ranks, i)) + "\t" +
#            str(average(merge, ranks, i)))

# Plot the amount of time spent in each phase on all ranks
i = bestofaverage(total, ranks, runs)
print(  "#using iteration number " + str(i) )
print(  str(ranks)                       + "\t" + 
        str(average(detect, ranks, i))   + "\t" +
        str(average(revoke, ranks, i))   + "\t" + 
        str(average(shrink, ranks, i))   + "\t" + 
        str(average(spawn, ranks, i))    + "\t" +
        str(average(rollback, ranks, i)) + "\t" +
        str(average(merge, ranks, i)))

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
