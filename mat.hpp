#ifndef MAT_HPP__
#define MAT_HPP__

#include <boost/operators.hpp>
#include <gsl/gsl_matrix.h>

namespace KM {

  class vector;

  enum SumDirection
  {
    ACROSS_COLUMN,
    ACROSS_ROW
  };

  class matrix : boost::ring_operators<matrix,
                                       boost::ring_operators<matrix, double> >
  {

  public:
    /**
     * Create an empty matrix. This matrix is invalid and should not be used
     * until data is copied from another source.
     * \see matrix::copy
     */

    matrix() : _data(NULL) { }

    //! Create an \f$m \times n\f$ matrix of zeros.
    matrix(int m, int n);

    matrix(gsl_matrix* mat) : _data(mat) { }

    //! Deep copy of a vector-like object
    template <typename VecType>
    matrix(const VecType& data, int m, int n, bool fill_by_column = true) {
      _data = gsl_matrix_alloc( m, n );
      int c = 0;
      for (int j = 0; j < n; ++j)
        for (int i = 0; i < m; ++i)
          gsl_matrix_set( _data,
                          fill_by_column ? i : j,
                          fill_by_column ? j : i,
                          data[c++] );
    }


    //! Create a deep copy of \a rhs.
    matrix& operator =( const matrix& rhs );

    /**
     * Create a shallow copy of \a mat, taking ownership. Once \a mat is passed
     * this object, the caller no longer has responsibility for freeing \a
     * mat.
     */
    matrix& operator =( gsl_matrix* mat );

    //! Copy constructor
    matrix(const matrix& rhs);

    /**
     * Fill all elements of the matrix with the common scalar $d$
     */
    void fill( double d );
    void zeros( double d );

    /**
     * return the dimensions of the matrix
     */
    int rows() const;
    int cols() const;

    // term-by-term arithmetic operations
    friend matrix& operator +=(matrix& lhs, const matrix& rhs);
    friend matrix& operator +=(matrix& lhs, double d);
    friend matrix& operator -=(matrix& lhs, const matrix& rhs);
    friend matrix& operator -=(matrix& lhs, double d);
    friend matrix& operator %=(matrix& lhs, const matrix& rhs);
    friend matrix& operator *=(matrix& lhs, const matrix& rhs);
    friend matrix& operator *=(matrix& lhs, double d);

    // vector arithmetic
    friend vector operator *(const matrix& mat, const vector& vec);

    // accumulation
    vector sum( SumDirection dir ) const;

    // indexing
    double operator() (int i, int j) const;
    double& operator() (int i, int j) { return _data->data[i*_data->tda + j]; }
    void set(int i, int j, double d);

    /**
     * Transpose in place. The original matrix must be square.
     */
    matrix& transpose();

    //! Return a copy of column \a i
    gsl_vector* get_col(int i) const;

    //! Set a specific column from vector-like data.
    template <typename VecType>
    void set_col(int j, VecType& v) {
      for (unsigned int i = 0; i < _data->size1; ++i)
        (*this)(i, j) = v[i];
    }

    //! Return a copy of row \a i
    gsl_vector* get_row(int i) const;

    // grab the raw gsl matrix
    const gsl_matrix* raw() const { return _data; };

    gsl_matrix* move() { gsl_matrix* ret = _data; _data = NULL; return ret; }

    void copy( const matrix& m, bool transpose = false );
    void copy( const gsl_matrix* m, bool transpose = false );

    ~matrix();

  private:
    /**
     * Return a column vector, where each element is the sum of elements of the
     * matrix row.
     */
    vector sum_across_row() const;

    /**
     * Return a (row) vector, where each element is the sum of elements in the
     * matrix column.
     */
    vector sum_across_col() const;

    void copy_data(const matrix& rhs);
    void cleanup();

    gsl_matrix* _data;
  };
}


#endif
