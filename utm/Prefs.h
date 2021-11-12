/*
 * Hardwired to WGS84
 */
#define datumParams(datum, ap, esp) \
	    do{ \
		double f = 1.0 / 298.257223563;	/* flattening */ \
		*ap = 6378137.0;		/* semimajor axis */ \
		*esp = 2 * f - f * f;		/* eccentricity^2 */ \
	    }while(0)
