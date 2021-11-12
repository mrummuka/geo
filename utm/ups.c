/****************************************************************************/
/*                                                                          */
/* ./grid/ups.c   -   Convert to and from UPS Grid Format                   */
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


/* prototype functions */
static void calcPhi (double *phi, double e, double t);


/****************************************************************************/
/* Convert degree to UPS Grid.                                              */
/****************************************************************************/
void
toUPS (double lat, double lon, double *x, double *y)
{
  // extern struct PREFS gPrefs;
  double a, t, e, es, rho;
  const double k0 = 0.994;
  double lambda = lon * (M_PI/180.0);
  double phi = fabs (lat * (M_PI/180.0));

  datumParams (gPrefs.datum, &a, &es);
  e = sqrt (es);
  t = tan (M_PI / 4.0 - phi / 2.0) / pow ((1.0 - e * sin (phi)) /
					(1.0 + e * sin (phi)), (e / 2.0));
  rho =
    2.0 * a * k0 * t / sqrt (pow (1.0 + e, 1.0 + e) * pow (1.0 - e, 1.0 - e));
  *x = rho * sin (lambda);
  *y = rho * cos (lambda);

  if (lat > 0.0)
    *y = -(*y);			/* Northern hemisphere */
  *x += 2.0e6;			/* Add in false easting and northing */
  *y += 2.0e6;
}


/****************************************************************************/
/* Convert UPS Grid to degree.                                              */
/****************************************************************************/
void
fromUPS (short southernHemisphere, double x, double y, double *lat,
	 double *lon)
{
  // extern struct PREFS gFilePrefs;
  double a, es, e, t, rho;
  const double k0 = 0.994;

  datumParams (gFilePrefs.datum, &a, &es);
  e = sqrt (es);

  /* Remove false easting and northing */
  x -= 2.0e6;
  y -= 2.0e6;

  rho = sqrt (x * x + y * y);
  t =
    rho * sqrt (pow (1.0 + e, 1.0 + e) * pow (1.0 - e, 1.0 - e)) / (2.0 * a *
								    k0);

  calcPhi (lat, e, t);
  *lat /= (M_PI/180.0);

  if (y != 0.0)
    t = atan (fabs (x / y));
  else
    {
      t = M_PI / 2.0;
      if (x < 0.0)
	t = -t;
    }

  if (!southernHemisphere)
    y = -y;

  if (y < 0.0)
    t = M_PI - t;
  if (x < 0.0)
    t = -t;

  *lon = t / (M_PI/180.0);
}


/****************************************************************************/
/* Calculate Phi.                                                           */
/****************************************************************************/
static void
calcPhi (double *phi, double e, double t)
{
  double old = M_PI / 2.0 - 2.0 * atan (t);
  short maxIterations = 20;

  while ((fabs ((*phi - old) / *phi) > 1.0e-8) && maxIterations--)
    {
      old = *phi;
      *phi = M_PI / 2.0 - 2.0 * atan (t * pow ((1.0 - e * sin (*phi)) /
					     ((1.0 + e * sin (*phi))),
					     (e / 2.0)));
    }
}
