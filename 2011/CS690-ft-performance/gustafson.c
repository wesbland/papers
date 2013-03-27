#include <stdio.h>
#include <stdlib.h>
#include <math.h>

double nf(double r, double mtbf) {
    long double ret = (long int) ((r / mtbf) * (1 + (r / mtbf)) / 2);

    ret = ((ret * mtbf) / r);

    return ret;
}

double gustafson_improved(double p, double n, double r, double mtbf) {
    return (1 - p) + (p * (n - nf(r, mtbf)));
}

double gustafson(double p, double n) {
    return (1 - p) + (p * n);
}

int main(int argc, char **argv) {
    double p, n, r, mtbf;

    if (argc != 5) {
        fprintf(stderr, "Usage: gustafson <p> <n> <r> <mtbf>\n");
        return 1;
    }

    p = strtod(argv[1], NULL);
    n = strtod(argv[2], NULL);
    r = strtod(argv[3], NULL);
    mtbf = strtod(argv[4], NULL);

    //printf("%f,%f,%f,%f,%f\n", p, n, r, mtbf, gustafson(p, n, r, mtbf));
    
    printf("%f %f %f\n", 
            p, 
            gustafson(p, n), 
            gustafson_improved(p, n, r, mtbf));

    return 0;
}
