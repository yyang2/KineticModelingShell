#include "vec.hpp"
#include <gsl/gsl_math.h>
#include <gsl/gsl_vector.h>
#include <gsl/gsl_blas.h>
#include <cassert>
#include "gsl_ext.hpp"
#include <cmath>
#include <iostream>

namespace KM {
  using std::min;

  vector::vector(int size) {
    _data = gsl_vector_calloc( size );
  }

  vector::vector( unsigned int size, double d ) {
    _data = gsl_vector_alloc_fill( size, d );
  }

  vector::vector(const std::vector<double>& v) {
    _data = gsl_vector_alloc( v.size() );
    for (unsigned int i = 0; i < v.size(); ++i)
      gsl_vector_set( _data, i, v[i] );
  }

  vector::vector(const double* d, int size) {
    _data = gsl_vector_alloc( size );
    for (int i = 0; i < size; ++i)
      gsl_vector_set( _data, i, d[i] );
  }

  vector::vector( const vector& rhs ) {
    _data = gsl_vector_alloc( rhs.size() );
    copy_data( rhs );
  }

  vector::vector(gsl_vector* v) {
    assert( v != NULL );    
    _data = v;
  }
      
  void vector::fill( double d ) {
    gsl_vector_set_all( _data, d );
  }

  void vector::replaceNaN( double d ) {
    for (unsigned int i = 0; i < _data->size; ++i)
      if ( gsl_isnan( gsl_vector_get( _data, i) ) )
        gsl_vector_set( _data, i, d );
  }

  void vector::add_element( double d, bool to_prepend ) {
    gsl_vector* new_data = gsl_vector_alloc( size() + 1 );
    
    gsl_vector_view rest = gsl_vector_subvector( new_data, to_prepend ? 1 : 0, size() );
    gsl_vector_set( new_data, to_prepend ? 0 : size(), d );
    gsl_vector_memcpy( &rest.vector, _data );

    gsl_vector_free( _data );
    _data = new_data;
  }

  gsl_vector* vector::subvector( int start, int length ) const {
    length = min(length, size() - start);
    return gsl_vector_clone( &gsl_vector_subvector( _data, start, length ).vector );
  }

  gsl_vector* vector::subvector( int start ) const {
    return gsl_vector_clone( &gsl_vector_subvector( _data, start, size() - start ).vector );
  }

  void vector::prepend( double d ) {
    add_element( d, true );
  }

  void vector::append( double d ) {
    add_element( d, false );
  }

  void vector::zeros( double d ) {
    gsl_vector_set_zero( _data );
  }

  int vector::size() const {
    return _data->size;
  }

  vector& vector::operator=( const vector& rhs ) {
    if (this != &rhs) {
      copy_data(rhs);
    }
    return *this;
  }

  vector& vector::operator=( gsl_vector* rhs ) {
    if (_data != rhs) {
      cleanup();
      _data = rhs;
    }
    return *this;
  }

  double vector::operator[](int i) const {
    return gsl_vector_get( _data, i );
  }

  void vector::set(int i, double d) {
    gsl_vector_set( _data, i, d );
  }

  void vector::copy( const gsl_vector* vec ) {
    if (vec != _data) {
      cleanup();
      _data = gsl_vector_alloc( vec->size );
      gsl_vector_memcpy( _data, vec );
    }
  }

  void vector::copy( const vector& vec ) {
    if ( vec._data != _data ) {
      cleanup();
      _data = gsl_vector_alloc( vec.size() );
      gsl_vector_memcpy( _data, vec._data );
    }
  }

  void vector::copy( const double* vec, int n ) {
    if ( _data->data != vec ) {
      gsl_vector_const_view view = gsl_vector_const_view_array( vec, n );
      copy( &view.vector );
    }
  }

  void vector::resize( int n, double fill ) {
    cleanup();
    _data = gsl_vector_alloc( n );
    this->fill( fill );
  }

  gsl_vector* vector::move() {
    gsl_vector* ret = _data;
    _data = NULL;
    return ret;
  }

  vector::~vector() {
    cleanup();
  }

  void vector::copy_data(const vector& rhs) {
    gsl_vector_memcpy( _data, rhs._data );
  }

  void vector::cleanup() {
    // gsl_vector_free will not clean up a shallow vector allocated from
    // another object, so we don't need to check that _data is actually owned by
    // this object. 
    if ( _data )
      gsl_vector_free( _data );
  }
  
  /***************************************
   * math operations 
   **************************************/
  double vector::sum() const 
  {
    return gsl_vector_sum( _data );
  }
  
  double vector::norm() const
  {
    return gsl_blas_dnrm2( _data );
  }

  gsl_vector* vector::sqrt() const
  {
    return this->map( ::sqrt );
  }

  /***************************************
   * term-by-term arithmetic operations
   **************************************/

  vector& operator +=(vector& lhs, const vector& rhs)
  {
    gsl_vector_add( lhs._data, rhs._data );
    return lhs;
  }

  vector& operator +=(vector& lhs, double rhs)
  {
    gsl_vector_add_constant( lhs._data, rhs );
    return lhs;
  }
  
  vector& operator -=(vector& lhs, const vector& rhs)
  {
    gsl_vector_sub( lhs._data, rhs._data );
    return lhs;
  }
  
  vector& operator -=(vector& lhs, double d)
  {
    return lhs += -d;
  }

  vector& operator *=(vector& lhs, const vector& rhs)
  {
    gsl_vector_mul( lhs._data, rhs._data );
    return lhs;
  }

  vector& operator *=(vector& lhs, double d)
  {
    gsl_vector_scale( lhs._data, d );
    return lhs;
  }

  vector& operator /=(vector& lhs, const vector& rhs)
  {
    gsl_vector_div( lhs._data, rhs._data );
    return lhs;
  }
  
  vector& operator /=(vector& lhs, double d)
  {
    return lhs *= (1.0 / d);
  }

  using std::ostream;
  ostream& operator <<(ostream& out, const vector& rhs)
  {
    for (int i = 0; i < rhs.size(); ++i)
      out << rhs[i] << " ";
    return out;
  }

}
