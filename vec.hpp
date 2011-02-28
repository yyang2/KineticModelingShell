#ifndef VEC_HPP__
#define VEC_HPP__

#include "global.hpp"
#include <iostream>
#include <gsl/gsl_vector.h>
#include <boost/operators.hpp>
#include <vector>

namespace KM {

  class matrix;
  using std::ostream;

  /**
  * \class vector
  * Fixed-length wrapper for gsl_vector.
  * This class provides memory management and convenience methods, such as
  * operator overloading, for gsl_vector*. The underlying vector is assumed to
  * be fixed length, meaning that operations cannot change the length of the
  * vector unless otherwise indicated. In particular, <code>v = w</code> will
  * fail unless v and w are already the same size. 
  *
  */
  class vector : boost::field_operators<vector, 
                          boost::field_operators<vector, double> >
  {
  public:    
    friend class matrix;
    
    /** 
     * Create a place-holder vector. Place-holders cannot be used until they are
     * re-assigned to an actual data source. When possible, one should create an
     * actual vector instead, using one of the other constructors.
     */
    vector() : _data(NULL) { }

    /** Create a zero vector of the specified size */
    explicit vector(int size);

    /** Create a filled vector of the specified size */
    vector( unsigned int size, double d );
    
    /** Create a deep copy of \a data */
    vector(const double* data, int size);

    /** Create a deepy copy of \a v */
    explicit vector(const std::vector<double>& v);

    /** 
     * Create a *shallow* copy of the initial vector. The newly-created object 
     * will be responsible for deallocating the other vector. */
    vector(gsl_vector* vec);

    //! Copy constructor
    vector(const vector& rhs);

    //! Assignment operator
    vector& operator =(const vector& rhs);
    
    /**
     * (Shallow) Assignement Operator.
     * Creates a shallow copy of \a rhs. This instance is now responsible for
     * deallocating \a rhs. 
     */
    vector& operator =(gsl_vector* rhs); 

    /** 
     * Fill all elements of the vector with the common scalar \a d
     */
    void fill( double d );

    /**
     * Fill the vector with zeros
     */
    void zeros( double d );

    /** 
     * Replace all NaNs with \a replace_with
     */
    void replaceNaN( double replace_with = 0.0 );

    /**
     * Add \a d to the start of the vector
     */
    void prepend( double d );

    /**
     * Add \a d to the end of the vector
     */
    void append( double d );

    /**
     * Return the length of this object.
     */
    int size() const;

    // Term-by-term arithmetic operations
    friend vector& operator +=(vector& lhs, const vector& rhs);
    friend vector& operator +=(vector& lhs, double d);
    friend vector& operator -=(vector& lhs, const vector& rhs);
    friend vector& operator -=(vector& lhs, double d);
    friend vector& operator *=(vector& lhs, const vector& rhs);
    friend vector& operator *=(vector& lhs, double d);
    friend vector& operator /=(vector& lhs, const vector& rhs);
    friend vector& operator /=(vector& lhs, double d);
    
    /**
     * Call \a f on each element of the calling instance,
     * returning a newly-allocated vector.
     */
    template <typename MapFunc>
    gsl_vector* map( MapFunc& f ) const
    {
      return gsl_vector_map( _data, f );
    }

    /**
     * Get a copy of the subvector starting at \a start of length \a n
     */
    gsl_vector* subvector( int start, int length ) const;

    gsl_vector* subvector( int start ) const;

    /** 
     * Replace \f$v_i\f$ with \f$f(v_i)\f$ for each element \f$v_i\f$ of the
     * calling instance.
     */
    template <typename MapFunc>
    vector& transform( MapFunc& f ) 
    {
      for (int i = 0; i < size(); ++i)
        (*this)[i] =  f( (*this)[i] );
      return *this;
    }

    /**
     * Return a vector containing the square root of each term in 
     * the calling vector.
     */
    gsl_vector* sqrt() const;

    // accumulation
    /** 
     * Compute the sum of elements in the instance.
     */
    double sum() const;

    /**
     * Compute the two-norm of this vector
     */
    double norm() const;
    
    /**
     * Compute the square of the two norm of the vector
     */
    double norm_sq() const { 
      double n = norm(); 
      return n * n; 
    }

    // read-only indexing
    double operator[]( int i ) const;
    double& operator[] (int i ) { return _data->data[i*_data->stride]; }
    void set(int ip, double d);

    //! Return the last element of the vector
    double last() const { return (*this)[_data->size - 1]; }

    //! grab the raw gsl vector
    const gsl_vector* raw() const { return _data; }

    // make sure the vector is valid
    bool is_valid() const { return _data != NULL; }

    /** 
     * Copy the contents of \a vec over to this object, resizing if
     * necessary. 
     */
    void copy( const gsl_vector* vec );

    /** 
     * Copy the contents of \a vec over to this object, resizing if
     * necessary. 
     */
    void copy( const vector& vec );

    /**
     * Copy the contents of \a vec, resizing if necessary 
     */
    void copy( const double* vec, int n );

    /**
     * Resize the vector and fiil it with a constant
     */
    void resize( int n, double fill );

    /** 
     * Return the underlying gsl pointer, transferring responsiblity.  
     * 
     * After calling this function, this object is no longer responsible for
     * deallocating the associated gsl_vector. Furthermore, this should no
     * longer be used, as it may no longer even reference the underlying
     * vector. This should typically be used with return values for functions.
     */
    gsl_vector* move();

    //! Destructor
    ~vector();

  private:
    void copy_data(const vector& rhs);
    void cleanup();

    void add_element( double d, bool to_prepend );

    gsl_vector* _data;
  };

  ostream& operator <<(ostream& out, const vector& rhs);
}




#endif
