/****************************************************************************/
/*                                                                          */
/* ./grid/utm.c   -   Convert to and from UTM Grid Format                   */
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

#include <math.h>

/* define constants */
static const double lat0 = 0.0;	/* reference transverse mercator latitude */
static const double k0 = 0.9996;


/****************************************************************************/
/* Convert degree to UTM Grid.                                              */
/****************************************************************************/
void
DegToUTM (double lat, double lon, int *zone, char *nz, double *x, double *y)
{
  double lon0;

  if ((lat >= -80.0) && (lat <= 84.0))
    {
      *nz = 'C' + ((short) (lat + 80.0)) / 8;

      /* skip 'I' and 'O' */
      if (*nz > 'H')
	++*nz;
      if (*nz > 'N')
	++*nz;

      lon0 = 6.0 * floor (lon / 6.0) + 3.0;
      *zone = ((short) lon0 + 183) / 6;

      toTM (lat, lon, lat0, lon0, k0, x, y);

      /* false easting */
      *x = *x + 500000.0;

      /* false northing for southern hemisphere */
      if (lat < 0.0)
	*y = 10000000.0 - *y;
    }
  else
    {
      *zone = 0;
      if (lat > 0.0)
	if (lon < 0.0)
	  *nz = 'Y';
	else
	  *nz = 'Z';
      else if (lon < 0.0)
	*nz = 'A';
      else
	*nz = 'B';
      toUPS (lat, lon, x, y);
    }
}


/****************************************************************************/
/* Convert UTM Grid to degree.                                              */
/****************************************************************************/
void
UTMtoDeg (short zone, short southernHemisphere, double x, double y,
	  double *lat, double *lon)
{
  double lon0;

  if (zone != 0)
    {
      lon0 = (double) ((-183 + 6 * zone));


      /* remove false northing for southern hemisphere and false easting */
      if (southernHemisphere)
	y = 1.0e7 - y;
      x -= 500000.0;

      fromTM (x, y, lat0, lon0, k0, lat, lon);
    }
  else
    fromUPS (southernHemisphere, x, y, lat, lon);
  *lat = fabs (*lat);
  if (southernHemisphere)
    *lat = -(*lat);

}
