#include <stdio.h>
#include <stdlib.h>
#include <math.h>

int calc_failures(double runtime) {
	return runtime / (60 * 60 * 8);
}

double runtime_added(double checkpoint_interval,
					 double checkpoint_overhead,
					 double runtime) {
	double added = ((runtime/checkpoint_interval) * checkpoint_overhead) + 
				   (calc_failures(runtime) * checkpoint_interval);
	
	if (added > checkpoint_interval) {
		fprintf(stderr, "%f + ", added);
		return added + runtime_added(checkpoint_interval, checkpoint_overhead, added);
	} else {
		fprintf(stderr, "0\n");
		return added;
	}
}

double calc_p(double p,
			  double checkpoint_interval,
			  double checkpoint_overhead,
			  double runtime) {
	fprintf(stderr, "RUNTIME: %f + ", runtime);
	
	double added = runtime_added(checkpoint_interval, checkpoint_overhead, runtime);
	
	double old_parallel = p * runtime;
	
	return old_parallel / (runtime + added);
}

double amdahl_improved(double p, 
					   double procs, 
					   double checkpoint_interval,
					   double checkpoint_overhead,
					   double runtime) {
	return 1 / ((1 - calc_p(p, checkpoint_interval,checkpoint_overhead,runtime)) + 
				(calc_p(p, checkpoint_interval,checkpoint_overhead,runtime) / procs));
}

double amdahl(double p, 
			  double n) {
    return 1 / ((1 - p) + (p / n));
}

int main(int argc, char **argv) {
    double p, procs, checkpoint_interval, checkpoint_overhead, runtime;

    if (argc != 6) {
        fprintf(stderr, "Usage: amdahl <p> <procs> <checkpoint_interval> <checkpoint_overhead> <runtime>\n");
        return 1;
    }

    p = strtod(argv[1], NULL);
    procs = strtod(argv[2], NULL);
    checkpoint_interval = strtod(argv[3], NULL);
	checkpoint_overhead = strtod(argv[4], NULL);
	runtime = strtod(argv[5], NULL);
	
	/*
	 fprintf(stderr, "P: %f\nPROCS: %f\nINTERVAL: %f\nOVERHEAD: %f\nRUNTIME: %f\n",
			p,
			procs,
			checkpoint_interval,
			checkpoint_overhead,
			runtime);
	 */
	
	fprintf(stderr, "P: %f\tCALC P: %f\n",
			p,
			calc_p(p, checkpoint_interval, checkpoint_overhead, runtime));

    printf("%f %f %f\n", 
            p,
            amdahl(p, procs), 
            amdahl_improved(p, procs, checkpoint_interval, checkpoint_overhead, runtime));

    return 0;
}
