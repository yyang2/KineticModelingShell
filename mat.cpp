#include "mat.hpp"
#include <gsl/gsl_blas.h>
#include <gsl/gsl_matrix.h>
#include "vec.hpp"
#include "gsl_ext.hpp"

namespace KM {

  matrix::matrix(int m, int n) {
    _data = gsl_matrix_calloc( m, n );
  }

  void matrix::fill( double d ) {
    gsl_matrix_set_all( _data, d );
  }

  void matrix::zeros( double d ) {
    gsl_matrix_set_zero( _data );
  }

  matrix& matrix::operator=( const matrix& rhs ) {
    if (this != &rhs) {
      copy_data(rhs);
    }
    return *this;
  }

  matrix& matrix::operator=( gsl_matrix* mat ) {
    if (_data != mat) {
      cleanup();
      _data = mat;
    }
    return *this;
  }

  matrix::matrix( const matrix& rhs ) {
    _data = gsl_matrix_alloc( rhs.rows(), rhs.cols() );
    copy_data( rhs );
  }

  double matrix::operator()(int i, int j) const {
    return gsl_matrix_get( _data, i, j );
  }

  int matrix::rows() const {
    return _data->size1;
  }
  int matrix::cols() const {
    return _data->size2;
  }

  matrix& matrix::transpose() {
    gsl_matrix_transpose( _data );
    return *this;
  }

  void matrix::set(int i,int j, double d) {
    gsl_matrix_set( _data, i, j, d );
  }

  gsl_vector* matrix::get_col( int i ) const {
    return gsl_vector_clone( &gsl_matrix_const_column( _data, i ).vector );
  }

  gsl_vector* matrix::get_row( int i ) const {
    return gsl_vector_clone( &gsl_matrix_const_row( _data, i ).vector );
  }

  void matrix::cleanup() {
    if ( _data ) {
      gsl_matrix_free( _data );
      _data = NULL;
    }
  }

  matrix::~matrix() {
    cleanup();
  }

  void matrix::copy_data(const matrix& rhs) {
    gsl_matrix_memcpy( _data, rhs._data );
  }

  void matrix::copy( const matrix& m, bool transpose ) {
    copy( m._data, transpose );
  }

  void matrix::copy( const gsl_matrix* m, bool transpose ) {
    cleanup();
    _data = gsl_matrix_alloc( m->size1, m->size2 );
    if ( transpose )
      gsl_matrix_transpose_memcpy( _data, m );
    else
      gsl_matrix_memcpy( _data, m );
  }

  /***************************************
   * math operations
   **************************************/
  vector matrix::sum( SumDirection dir) const {
    return dir == ACROSS_COLUMN ? sum_across_col() : sum_across_row();
  }

  vector matrix::sum_across_row() const {
    int M = rows();
    vector res(M);
    for (int i = 0; i < M; ++i)
      res[i] = gsl_vector_sum( &(gsl_matrix_row( _data, i)).vector );
    return res;
  }

  vector matrix::sum_across_col() const {
    int N = cols();
    vector res(N);
    for (int i = 0; i < N; ++i)
      res[i] = gsl_vector_sum( &(gsl_matrix_column( _data, i)).vector );
    return res;
  }

  /***************************************
   * term-by-term arithmetic operations
   **************************************/

  matrix& operator +=(matrix& lhs, const matrix& rhs)
  {
    gsl_matrix_add( lhs._data, rhs._data );
    return lhs;
  }

  matrix& operator +=(matrix& lhs, double rhs)
  {
    gsl_matrix_add_constant( lhs._data, rhs );
    return lhs;
  }

  matrix& operator -=(matrix& lhs, const matrix& rhs)
  {
    gsl_matrix_sub( lhs._data, rhs._data );
    return lhs;
  }

  matrix& operator -=(matrix& lhs, double d)
  {
    return lhs += -d;
  }

  matrix& operator %=(matrix& lhs, const matrix& rhs)
  {
    gsl_matrix_mul_elements( lhs._data, rhs._data );
    return lhs;
  }

  matrix& operator *=(matrix& lhs, const matrix& rhs)
  {
    gsl_matrix* result = gsl_matrix_alloc( lhs.rows(), rhs.cols() );
    gsl_blas_dgemm( CblasNoTrans, CblasNoTrans, 1.0, lhs._data, rhs._data, 0.0, result );
    lhs.cleanup();
    lhs._data = result;
    return lhs;
  }

  vector operator *(const matrix& lhs, const vector& rhs)
  {
    gsl_vector* result = gsl_vector_alloc( lhs.rows() );
    gsl_blas_dgemv( CblasNoTrans, 1.0, lhs._data, rhs.raw(), 0.0, result );
    return vector(result);
  }

  matrix& operator *=(matrix& lhs, double d)
  {
    gsl_matrix_scale( lhs._data, d );
    return lhs;
  }
}
