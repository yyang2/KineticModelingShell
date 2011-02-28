#include "ode.hpp"
#include <iostream>

using std::cout;
using std::endl;

namespace KM {

  struct ode_params
  {
    int n;
    ODESystem* system;
  };


  ODESolver::ODESolver( int n, const gsl_odeiv_step_type* T ) : _dims(n), _h(1e-3) {
    _stepper = gsl_odeiv_step_alloc( T, _dims );
    _step_controller = gsl_odeiv_control_y_new( 1.0e-3, 0 ); // TODO: make
                                                             // customizable
    _solver = gsl_odeiv_evolve_alloc( _dims );
  }

  gsl_vector* ODESolver::solve( double t0, double t1, const vector& y0,
                                ODESystem* odes ) const
  {
    // restart the system
    gsl_odeiv_evolve_reset( _solver );

    // create the parameter object
    ode_params odep = { _dims, odes };
    
    // create the system to solve
    gsl_odeiv_system system = { &ODESolver::gsl_dydt_wrapper, 
                                NULL, _dims, &odep };

    gsl_vector* vec = gsl_vector_alloc( _dims );
    gsl_vector_memcpy( vec, y0.raw() );
    double* ya = vec->data;
    
    double t = t0, h = 0.01;
    while (t < t1) {
      int status = gsl_odeiv_evolve_apply( _solver, _step_controller, _stepper, 
                                           &system, &t, t1, &h, ya );
      
      if (status != GSL_SUCCESS)
        break;
    }

    return vec;
  }

  gsl_matrix* ODESolver::solve( double t0, const vector& times, const vector& y0,
                                ODESystem* odes ) const
  {
    // restart the system
    gsl_odeiv_evolve_reset( _solver );

    // create the parameter object
    ode_params odep = { _dims, odes };
    
    // create the system to solve
    gsl_odeiv_system system = { &ODESolver::gsl_dydt_wrapper, 
                                NULL, _dims, &odep };

    matrix ys( _dims, times.size() );

    gsl_vector* vec = gsl_vector_alloc( _dims );
    gsl_vector_memcpy( vec, y0.raw() );
    double* ya = vec->data;
    
    double t = t0, h = 0.01;
    for (int i = 0; i < times.size(); ++i) {
      double end = times[i];

      // compute up to the next time
      while (t < end) {
        int status = gsl_odeiv_evolve_apply( _solver, _step_controller, _stepper, 
                                             &system, &t, end, &h, ya );
        if (status != GSL_SUCCESS)
          break;
      }
      
      // add that time's y-values as the next column
      ys.set_col( i, ya );
    }

    gsl_vector_free( vec );

    return ys.move();
  }

  ODESolver::~ODESolver()
  {
    gsl_odeiv_evolve_free( _solver );
    gsl_odeiv_control_free( _step_controller );
    gsl_odeiv_step_free( _stepper );
  }

  int ODESolver::gsl_dydt_wrapper(double t, const double y[], double dydt[], void * data)
  {
    ode_params* params = reinterpret_cast< ode_params* >(data);
    gsl_vector_view dydt_view = gsl_vector_view_array(
      dydt, params->n );

    vector yv( y, params->n );

    int status = params->system->func( t, yv, &dydt_view.vector );

    return status;
  }
}
