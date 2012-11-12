/*******************************************************************************
* --- CORDIC TRIG LIBRARY ---
*
* FILE NAME:        trig.h
* AUTHOR:           Patrick Fairbank
* LAST MODIFIED:    Jan. 16, 2008
*
* DESCRIPTION:      This file contains stuctures and prototypes for the CORDIC
*                   trigonometric functions implemented in trig.asm.
*
* USAGE:            Include this file at the top of each .c file in which the
*                   trig functions are used.
*
* LICENSE:          Users are free to use, modify, and distribute this code
*                   as they see fit.
*
* NOTE:             The C18 compiler doesn't seem to always like expresssions of
*                   the form "sin_cos(1503).cos". If problems occur, try
*                   assigning the function output to a (global) variable first.
*******************************************************************************/

#ifndef _trig_h
#define _trig_h

typedef struct
{
  int sin;
  int cos;
} sin_cos_struct;

typedef struct
{
  int atan2;
  int sqrt;
} atan2_sqrt_struct;

/*******************************************************************************
* FUNCTION NAME:    sin_cos
*
* ARGUMENTS:        int angle (angle in 16-bit binary radians)
*
* RETURNS:          sin_cos_struct
*
* DESCRIPTION:      The angle is given in 16-bit radians (on a scale of -32,768
*                   to 32,767). The function simultaneously calculates the sine
*                   and cosine of the angle as fractions of 30,000 (where 30,000
*                   equates to 1 and -30,000 equates to -1) and returns them in
*                   a sin_cos_struct.
*
* EXAMPLE:          sin_cos_struct foo;
*                   int ang = 5461; // 30 degrees
*                   foo = sin_cos(ang);
*                   printf("%d, %d\r", foo.sin, foo.cos); // ~ 15000, 25980
*******************************************************************************/
extern sin_cos_struct sin_cos(int angle);

/*******************************************************************************
* FUNCTION NAME:    atan2_sqrt
*
* ARGUMENTS:        int y (y-coordinate)
*                   int x (x-coordinate)
*
* RETURNS:          atan2_sqrt_struct
*
* DESCRIPTION:      Given an ordered pair of coordinates, the function
*                   simultaneously calculates the atan2 (the direction of the
*                   position vector in 16-bit radians) and the square root of
*                   the sum of the squares of the coordinates (the magnitude of
*                   the position vector) and returns them in an
*                   atan2_sqrt_struct.
*
* NOTES:            (1) The accuracy of the returned values increases as the
*                   sizes of x and y increase. Consider multiplying both by a
*                   scaling factor before calling the function.
*                   (2) The function will fail for x and y values that result in
*                   magnitues greater than 32,767 (the size of a signed int).
*
* EXAMPLE:          atan2_sqrt_struct bar;
*                   int x = 25980, y = 15000;
*                   bar = atan2_sqrt(y, x);
*                   printf("%d, %d\r", bar.atan2, bar.sqrt); // ~ 5461, 30000
*******************************************************************************/
extern atan2_sqrt_struct atan2_sqrt(int y, int x);

#endif
