/****************************************************************************/
/*                                                                          */
/* ./gps/tm.c   -   Convert to selected datum                               */
/*                                                                          */
/* This file is part of gpstrans - a program to communicate with garmin gps */
/* Parts are taken from John F. Waers (jfwaers@csn.net) program MacGPS.     */
/*                                                                          */
/*                                                                          */
/*    Copyright (c) 1995 by Carsten Tschach (tschach@zedat.fu-berlin.de)    */
/*                                                                          */
/*                                                                          */
/* This program is free software; you can redistribute it and/or            */
/* modify it under the terms of the GNU General Public License              */
/* as published by the Free Software Foundation; either version 2           */
/* of the License, or (at your option) any later version.                   */
/*                                                                          */
/* This program is distributed in the hope that it will be useful,          */
/* but WITHOUT ANY WARRANTY; without even the implied warranty of           */
/* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            */
/* GNU General Public License for more details.                             */
/*                                                                          */
/* You should have received a copy of the GNU General Public License        */
/* along with this program; if not, write to the Free Software              */
/* Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307,   */
/* USA.                                                                     */
/****************************************************************************/

#include "Prefs.h"
#include <math.h>


/****************************************************************************/
/* Equations from "Map Projections -- A Working Manual", USGS Professional  */
/* Paper 1395                                                               */
/****************************************************************************/


/* prototype function */
static double M (double phi, double a, double es);


/****************************************************************************/
/* Convert latitude and longitude to converted position.                    */
/****************************************************************************/
void
toTM (double lat, double lon, double lat0, double lon0, double k0,
      double *x, double *y)
{
  // extern struct PREFS gPrefs;
  double m, et2, n, t, c, A, a, m0, es, lambda, phi, lambda0, phi0;

  datumParams (gPrefs.datum, &a, &es);

  lambda = lon * (M_PI/180.0);
  phi = lat * (M_PI/180.0);

  phi0 = lat0 * (M_PI/180.0);
  lambda0 = lon0 * (M_PI/180.0);

  m0 = M (phi0, a, es);
  m = M (phi, a, es);

  et2 = es / (1 - es);

  n = a / sqrt (1 - es * pow (sin (phi), 2.0));
  t = pow (tan (phi), 2.0);
  c = et2 * pow (cos (phi), 2.0);
  A = (lambda - lambda0) * cos (phi);
  *x = k0 * n * (A + (1.0 - t + c) * A * A * A / 6.0
		 + (5.0 - 18.0 * t + t * t + 72.0 * c - 58.0 * et2) * pow (A,
									   5.0)
		 / 120.0);
  *y =
    k0 * (m - m0 +
	  n * tan (phi) * (A * A / 2.0 +
			   (5.0 - t + 9.0 * c + 4 * c * c) * pow (A,
								  4.0) /
			   24.0 + (61.0 - 58.0 * t + t * t + 600.0 * c -
				   330.0 * et2) * pow (A, 6.0) / 720.0));
}


/****************************************************************************/
/* Convert converted position to latitude and longitude.                    */
/****************************************************************************/
void
fromTM (double x, double y, double lat0, double lon0, double k0,
	double *lat, double *lon)
{
  // extern struct PREFS gFilePrefs;
  double a, m0, es, et2, m, e1, mu, phi1, c1, t1, n1, r1, d, phi0, lambda0;

  phi0 = lat0 * (M_PI/180.0);
  lambda0 = lon0 * (M_PI/180.0);

  datumParams (gFilePrefs.datum, &a, &es);

  m0 = M (phi0, a, es);
  et2 = es / (1.0 - es);
  m = m0 + y / k0;

  e1 = (1.0 - sqrt (1.0 - es)) / (1.0 + sqrt (1.0 - es));
  mu =
    m / (a *
	 (1.0 - es / 4.0 - 3.0 * es * es / 64.0 -
	  5.0 * es * es * es / 256.0));
  phi1 =
    mu + (3.0 * e1 / 2.0 - 27.0 * pow (e1, 3.0) / 32.0) * sin (2.0 * mu) +
    (21.0 * e1 * e1 / 16.0 - 55.0 * pow (e1,
					 4.0) / 32.0) * sin (4.0 * mu) +
    151.0 * pow (e1, 3.0) / 96.0 * sin (6.0 * mu) + 1097.0 * pow (e1,
								  4.0) /
    512.0 * sin (8.0 * mu);
  c1 = et2 * pow (cos (phi1), 2.0);
  t1 = pow (tan (phi1), 2.0);
  n1 = a / sqrt (1 - es * pow (sin (phi1), 2.0));
  r1 = a * (1.0 - es) / pow (1.0 - es * pow (sin (phi1), 2.0), 1.5);
  d = x / (n1 * k0);
  *lat = (phi1 - n1 * tan (phi1) / r1
	  * (d * d / 2.0 -
	     (5.0 + 3.0 * t1 + 10.0 * c1 - 4.0 * c1 * c1 -
	      9.0 * et2) * pow (d,
				4.0) / 24.0 + (61.0 + 90.0 * t1 + 298.0 * c1 +
					       45.0 * t1 * t1 - 252.0 * et2 -
					       3.0 * c1 * c1) * pow (d,
								     6.0) /
	     720.0)) / (M_PI/180.0);
  *lon =
    (lambda0 +
     (d - (1.0 + 2.0 * t1 + c1) * pow (d, 3.0) / 6.0 +
      (5.0 - 2.0 * c1 + 28.0 * t1 - 3.0 * c1 * c1 + 8.0 * et2 +
       24.0 * t1 * t1) * pow (d, 5.0) / 120.0) / cos (phi1)) / (M_PI/180.0);
}


/****************************************************************************/
/* Do some calculations  -  don't really know whats happen here.            */
/****************************************************************************/
static double
M (double phi, double a, double es)
{
  double fix;

  if (phi == 0.0)
    return 0.0;
  else
    {
      fix = a * (
		 (1.0 - es / 4.0 - 3.0 * es * es / 64.0 -
		  5.0 * es * es * es / 256.0) * phi - (3.0 * es / 8.0 +
						       3.0 * es * es / 32.0 +
						       45.0 * es * es * es /
						       1024.0) * sin (2.0 *
								      phi) +
		 (15.0 * es * es / 256.0 +
		  45.0 * es * es * es / 1024.0) * sin (4.0 * phi) -
		 (35.0 * es * es * es / 3072.0) * sin (6.0 * phi));
      return fix;
    }
}
