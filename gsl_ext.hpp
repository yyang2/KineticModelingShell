/**
 * @file
 * @author Mason Smith <masonium@cs.berkeley.edu>
 *
 * Miscellaneous operators on GSL data-types to improve usability.
 *
 * @section Copyright
 * Copyright 2010. The Regents of the University of California
 */

#ifndef GSL_EXT_HPP__
#define GSL_EXT_HPP__

#include <gsl/gsl_vector.h>
#include <gsl/gsl_matrix.h>

/**
 * Compute the sum of the elements in \a v.
 */
double gsl_vector_sum( const gsl_vector* v );

/**
 * Compute the Euclidean 2-norm of \a v.
 */
double gsl_vector_norm( const gsl_vector* v );

/**
 * Generate a vector from a data range
 */
gsl_vector* gsl_vector_range( double start, double end, int n );

/**
 * Allocate a prefilled vector 
 */
gsl_vector* gsl_vector_alloc_fill( int n, double fill );

/**
 * Call \a f on each element of the calling instance,
 * returning a newly-allocated vector.
 */
template <typename MapFunc>
gsl_vector* gsl_vector_map( const gsl_vector* v, MapFunc& f )
{
  gsl_vector* result = gsl_vector_alloc( v->size );
  for (unsigned int i = 0; i < v->size; ++i)
    gsl_vector_set( result, i, gsl_vector_get(v, i) );
  return result;
}

/** 
 * Create a deep copy of \a v.
 */
gsl_vector* gsl_vector_clone( const gsl_vector* v );

/**
 * Create a deep copy of \a m.
 */
gsl_matrix* gsl_matrix_clone( const gsl_matrix* m );



#endif
