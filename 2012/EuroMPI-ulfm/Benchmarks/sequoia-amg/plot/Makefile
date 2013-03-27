overhead.pdf: overhead.eps
	epspdf overhead.eps

overhead.eps: overhead.gnp overhead.dat
	gnuplot overhead.gnp

bargraph.pdf: bargraph.eps
	epspdf bargraph.eps

bargraph.eps: bargraph.gnp ../data/smoky-final-openib-sm.data
	gnuplot bargraph.gnp

clean:
	rm -fr bargraph.pdf bargraph.eps overhead.eps overhead.pdf
