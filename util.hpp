/**
 * @file
 * @author Mason Smith <masonium@cs.berkeley.edu>
 *
 * @section COPYRIGHT
 * Copyright 2010. The Regents of the University of California
 *
 * Date: August 2010
 */

#ifndef UTIL_HPP__
#define UTIL_HPP__

#include "vec.hpp"
#include <vector>
#include <algorithm>
#include <boost/utility.hpp>
#include <gsl/gsl_interp.h>
#include <gsl/gsl_spline.h>

namespace KM {

  using std::count;

  /**
   * Computes \f$f(t) \otimes e^{-k_s t}\f$ at the specified points in \a
   * petime, where \f$f(t)\f$ is by the points \f$(t_i, c_i\f$. If \f$k_s < \f$
   * \a integrate_threshold, the function will simply default to integration of
   * \f$f(t)\f$.
   */
  gsl_vector* conv_exp( const vector& ti, const vector& ci, 
                        double ks, const vector& petime,
                        double integrate_threshold = 1e-7 );
  
  /**
   * Compute the integral of the curve represented by \f$(t_i, c_i)\f$ along the
   * various points in \a petime
   */
  gsl_vector* integrate(const vector & ti, const vector& ci, 
                        const vector & petime);
  
  /**
   * Condense the parameter vector k by removing parameters that aren't
   * being used by the model. 
   */
  gsl_vector* condense_parameters(const vector& k, const bool* toggles);

  /**
   * Expand the condensed vector p to a full parameter vector, replacing the
   * correct elements of k. 
   */
  gsl_vector* expand_parameters(const vector& p, const vector& k, 
                                const bool* toggles);

  /**
   * Creates a delayed refinement of \a midt.
   * 
   * Given a set of montonically increasing times
   * \f$\{t_i\}_{i=1}^n\f$, this function first computes a refinement
   * \f$\{t'_i\}_{i=1}^{5n}\f$ with the following properties:
   *  - \f$t'_i \leq t'_{i+1}\f$
   *  - \f$t_i = t'_{5i - 2}\f$
   *  - \f$t'_{5i+1}, t'_{5i+2}, \hdots t'_{5(i+1)}\f$ are all equally spaced
   *
   * Finally, the function shifts the entire sequence by \a pstime \f$ \equiv s
   * \f$, returning \f$ \{T'_i\} = \{t'_i + s\} \f$ 
   */
  gsl_vector* pettsubdivide5(const vector& midt, double pstime);
  
  /**
   * For given data points (xi, yi), compute the values of the implied
   * piecewise linear function at each element of x.
   */
  gsl_vector* linear_interpolation(const vector& xi, const vector& yi, const vector& x);

  /**
   * \class Interpolator
   * Given a set of sampled points \f$\{\left(x_1, y_1\right), \hdots, \left(x_n,
   * y_n\right)\}\f$, \a Interpolatoor computes an interpolated function
   * \f$f(t)\f$ that can be evaluated on \f$\left[x_1, x_n\right]\f$ 
   */
  class Interpolator : boost::noncopyable
  {
  public:
    Interpolator(const vector& x, const vector& y, 
                 const gsl_interp_type* T = gsl_interp_linear);

    //! Evaluate the interpolated function at \a x.
    double eval( double x ) const;
    
    /**
     * Evaluate the \a n th derivative of the interpolated function at \a
     * x. \see operator()
     * 
     * \param x where to evaluate the interpolated function.
     * \param n the derivative to evaluate. At 0, the default, this returns the
     * function's value. 
     */
    double eval( double x, int n ) const;

    //! Evaluate the interpolated function at \a x.
    double operator()( double x ) const {
      return eval( x );
    }
    
   /**
     * Evaluate the \a n th derivative of the interpolated function at \a x. 
     * 
     * \param x where to evaluate the interpolated function.
     * \param n the derivative to evaluate. At 0, the default, this returns the
     * function's value. 
     */
    double operator()( double x, int n ) const {
      return eval( x, n );
    }

    ~Interpolator();

  private:
    gsl_interp_accel* _acc;
    gsl_spline* _spline;
  };

};

#endif
