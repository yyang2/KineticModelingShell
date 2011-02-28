/**
 * @file
 * @author Mason Smith <masonium@cs.berkeley.edu>
 *
 * @section COPYRIGHT
 * Copyright 2010. The Regents of the University of California
 *
 * Date: August 2010
 */

#ifndef ODE_HPP__
#define ODE_HPP__

#include "vec.hpp"
#include "mat.hpp"
#include <gsl/gsl_odeiv.h>
#include <boost/utility.hpp>

namespace KM {

  /*abstract*/
  class ODESystem
  {
  public:
    virtual int func(double t, const vector& y, gsl_vector* dydt) = 0;;
  };
  
  typedef int (* dydt_func)(double, const vector&, gsl_vector*);
  
  /**
   * wrapper for an ODE evaluation based on a standard C function
   */
  class UnparameterizedODE : public ODESystem
  {
  public:
    UnparameterizedODE( dydt_func& func ) : _f(func) { }

    virtual int func(double t, const vector& y, gsl_vector* dydt)
    {
      return _f(t, y, dydt);
    }
    
  private:
    dydt_func& _f;
  };
 

  /**
   * \class ODESolver
   * Computes numerical solutions to systems of ODEs.
   */
  class ODESolver : boost::noncopyable
  {
  public:
    ODESolver( int n, const gsl_odeiv_step_type* T = gsl_odeiv_step_rk8pd );

    gsl_vector* solve( double t0, double t1, const vector& y0,
                       ODESystem* odes) const;

    gsl_matrix* solve( double t0, const vector& times, const vector& y0,
                       ODESystem* odes) const;

    double initial_step() const { return _h; }
    ODESolver* initial_step( double h ) { _h = h; return this; }

    /**
     * \return The number of dimensions of an input ODE system.
     */
    int num_dimensions() const { return _dims; }

    ~ODESolver();

  private:
    static int gsl_dydt_wrapper(double t, const double y[], double dydt[], void * params);
      
    gsl_odeiv_step * _stepper; 
    gsl_odeiv_control * _step_controller;
    gsl_odeiv_evolve * _solver;
    int _dims;
    double _h;
  };
}

#endif
