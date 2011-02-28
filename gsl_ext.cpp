#include "gsl_ext.hpp"
#include <gsl/gsl_blas.h>

gsl_vector* gsl_vector_range(double start, double end, int n)
{
  double dx = (end - start) / n;

  gsl_vector* range = gsl_vector_alloc( n );
  for (int i = 0; i < n; ++i)
    gsl_vector_set( range, i, start + i * dx );
  
  return range;
}

gsl_vector* gsl_vector_alloc_fill( int n, double fill )
{
  gsl_vector* result = gsl_vector_alloc( n );
  gsl_vector_set_all( result, fill );
  return result;
}

double gsl_vector_sum( const gsl_vector* v )
{
  double sum = 0;
  for (unsigned int i = 0; i < v->size; ++i)
    sum += gsl_vector_get(v, i);
  return sum;
}

gsl_vector* gsl_vector_clone( const gsl_vector* v)
{
  gsl_vector* result = gsl_vector_alloc( v->size );
  gsl_vector_memcpy( result, v );
  return result;
}

gsl_matrix* gsl_matrix_clone( const gsl_matrix* m )
{
  gsl_matrix* result = gsl_matrix_alloc( m->size1, m->size2 );
  gsl_matrix_memcpy( result, m );
  return result;
}
