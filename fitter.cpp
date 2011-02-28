#include "fitter.hpp"
#include "gsl_ext.hpp"
#include "util.hpp"
#include <gsl/gsl_multifit_nlin.h>
#include <cmath>
#include <iostream>
#include <cassert>

using std::max;
using std::cout;
using std::endl;
using std::cerr;

namespace KM
{
  struct min_params
  {
    /**
     * \struct min_params
     * Structure containing various minimization parameters necessary
     * for use by gsl_mutlifit_fdf_solver. Inputs should already have already
     * been validated by a ModelFitter.
     *
     * \see ModelFitter::fit_tissue_curve_to_model
     */
    min_params( const Model* model_, const ModelFitter::Target* target,
                const vector& init_, const ModelFitter::Options* options )
      : n( target->ttac.size() ),
        ttac_times( target->ttac_times ), ttac( target->ttac ),
        inv_sigmas( target->weights.is_valid() ?
                    target->weights.sqrt() : gsl_vector_alloc_fill( n, 1.0 ) ),
        model(model_), init(init_),
        active_parameters( options->parameters_to_optimize ) {

    }

    /**
     * Expand a condensed parameter set, filling in missing parameters from the
     * initial parameter set.
     */
    gsl_vector* expand( const vector& dense ) {
      return expand_parameters( dense, init, active_parameters );
    }

    /**
     * Condense a parameter set, removing any parameters that shouldn't be
     * optimized over.
     */
    gsl_vector* condense( const vector& sparse ) {
      return condense_parameters( sparse, active_parameters );
    }

    const int n;
    const vector& ttac_times;
    const vector& ttac;
    const vector inv_sigmas;
    const Model* model;
    const vector& init;
    const bool* active_parameters;
  };

  void ModelFitter::validate_parameters( const Model* model,
                                         const Target* target,
                                         const vector& initial_parameters,
                                         const Options* options ) const {
    assert( model != NULL && "Must provide a model to fit to." );

    const int P = model->num_parameters();
    assert( P == initial_parameters.size() &&
            "The initial parameters vector is not the size expected by the model" );

    assert( target != NULL && "Must provide target tissue curve" );

    assert( target->ttac.is_valid() && "Must provide non-empty tissue curve" );
    assert( target->ttac_times.is_valid() &&
            "Must provide tissue curve times" );
    const int N = target->ttac.size();
    assert( target->ttac_times.size() == N &&
            "Tissue curve and times must be the same size" );
    assert( ( !target->weights.is_valid() ||
              target->weights.size() == N ) &&
            "Weights vector and tissue curve must be the same size" );

    if (options) {
      if ( options->use_lower_bounds )
        assert( P == options->lower_bounds.size() &&
                "The lower bounds option vector must be the same size as the full parameter vector");
      if ( options->use_upper_bounds )
        assert( P == options->upper_bounds.size() &&
                "The upper bounds option vector must be the same size as the full parameter vector");
    }
  }

  ModelFitter::Result* ModelFitter::fit_model_to_tissue_curve(
    Model* model, Target* target, const vector& initial_parameters,
    Options* options )
  {
    if ( !options )
      options = new Options( initial_parameters.size() );

    validate_parameters( model, target, initial_parameters, options );

    min_params mp(model, target,
                  initial_parameters, options);

    vector dense_init_param = mp.condense( initial_parameters );

    // setup the minimzation parameters
    gsl_multifit_function_fdf minfunc;
    minfunc.f = &(ModelFitter::func);
    minfunc.df = &(ModelFitter::jacobian);
    minfunc.fdf = &(ModelFitter::func_and_jacobian);
    minfunc.n = mp.n;
    minfunc.p = dense_init_param.size();
    minfunc.params = reinterpret_cast< void* >( &mp );

    const gsl_multifit_fdfsolver_type* type = gsl_multifit_fdfsolver_lmder;
    gsl_multifit_fdfsolver* solver = gsl_multifit_fdfsolver_alloc(
      type, minfunc.n, minfunc.p);

    model->setup( mp.ttac_times );

    gsl_multifit_fdfsolver_set( solver, &minfunc, dense_init_param.raw() );

    if (verbose)
      print_solver_state( solver );

    // run the solver
    MFStatus status = MF_MAX_ITERATIONS;
    for (int i = 0; (max_iterations <= 0 || i < max_iterations); ++i) {

      MFStatus iterate_status = iterate_solver( solver, options );

      if (iterate_status != MF_CONTINUE) {
        status = iterate_status;
        break;
      }
    }

    // save the resulting vectors and parameters
    Result* rr = createResult( solver, status, target, options );

    gsl_multifit_fdfsolver_free( solver );

    return rr;
  }

  ModelFitter::Result* ModelFitter::createResult(
    const gsl_multifit_fdfsolver* solver, MFStatus status,
    const Target* target, const Options* options )
  {
    Result* res = new Result();
    res->parameters.copy( solver->x );
    res->func_value.copy( solver->f );
    res->jacobian.copy( solver->J );

    res->status = status;

    gsl_matrix* cov = gsl_matrix_alloc( solver->fdf->p, solver->fdf->p );
    gsl_multifit_covar( solver->J, 0.0, cov );
    res->active_covariance = cov;

    vector residual = res->func_value - target->ttac;
    res->wrss = (residual * residual * target->weights).sum();

    return res;
  }

  MFStatus ModelFitter::iterate_solver( gsl_multifit_fdfsolver* solver,
                                        const Options* options ) const
  {
    // iterate the solver
    int step_result = gsl_multifit_fdfsolver_iterate(solver);

    // keep the result within bounds
    options->constrain_to_bounds( solver );

    if (verbose)
      print_solver_state( solver );

    if (step_result == GSL_CONTINUE) {

      // check user defiend constrants
      if ( gsl_multifit_test_delta( solver->dx, solver->x,
                                    absolute_step_threshold,
                                    relative_step_threshold )
           == GSL_SUCCESS )
        return MF_DELTA_THRESHOLD_REACHED;

      if ( gsl_multifit_test_gradient( solver->x, gradient_threshold )
           == GSL_SUCCESS )
        return MF_GRADIENT_THRESHOLD_REACHED;

      return MF_CONTINUE;
    }

    switch (step_result) {
    case GSL_ETOLF:
      return MF_ERROR_THRESHOLD_REACHED;
    case GSL_ETOLX:
      return MF_DELTA_THRESHOLD_REACHED;
    case GSL_ETOLG:
      return MF_GRADIENT_THRESHOLD_REACHED;
    default:
      //return MF_NO_STEP_SIZE_FOUND;
      return MF_CONTINUE;
    }
  }

  int ModelFitter::func( const gsl_vector* x, void* data, gsl_vector* v )
  {
    return func_and_jacobian( x, data, v, NULL );
  }

  int ModelFitter::jacobian( const gsl_vector* x, void* data, gsl_matrix* J)
  {
    return func_and_jacobian( x, data, NULL, J );
  }

  int ModelFitter::func_and_jacobian( const gsl_vector* x, void* data,
                                      gsl_vector* f, gsl_matrix* J )
  {
    min_params* params = reinterpret_cast<min_params*>( data );

    const vector dense_X( gsl_vector_clone( x ) );
    vector X = params->expand( dense_X );

    vector F = params->model->compute( X, params->ttac_times );

    vector dense_Xp = dense_X;

    const double delta_f = 1e-6;

    if (J != NULL) {
      matrix jm( params->n, dense_X.size() );

      for (int i = 0; i < dense_Xp.size(); ++i) {
        double delta = delta_f * dense_X[i];
        dense_Xp[i] = dense_X[i] + delta;
        delta = dense_Xp[i] - dense_X[i];

        // compute dF/dx_i
        if (delta == 0) {
          dense_Xp[i] = delta_f;
          delta = dense_Xp[i] - dense_X[i];
        }

        vector Xp( params->expand( dense_Xp ) );
        vector Fp = params->model->compute( Xp, params->ttac_times );

        vector dFp = (Fp - F) * params->inv_sigmas / delta;
        jm.set_col( i, dFp );

        // revert dense_Xp
        dense_Xp[i] = dense_X[i];
      }

      gsl_matrix_memcpy( J, jm.raw() );
    }

    vector wF = params->inv_sigmas * (F - params->ttac);
    if (f != NULL)
      gsl_vector_memcpy( f, wF.raw() );

    return GSL_SUCCESS;
  }

////////////////////////////////////////////////////////////////////////////////

  ModelFitter::Options::Options( unsigned int n ) :
    parameters_to_optimize( new bool[n] ),
    lower_bounds( n, -DBL_MAX ), upper_bounds( n, DBL_MAX ), dim( n ) {

    for ( unsigned int i = 0; i < n; ++i )
      parameters_to_optimize[i] = true;

    use_lower_bounds = use_upper_bounds = false;
  }

  void ModelFitter::Options::constrain_to_bounds(
    gsl_multifit_fdfsolver* solver ) const
  {
    // wrap in gsl_vectors for convenient [] access
    vector x( solver->x );
    vector dx( solver->dx );

    if ( use_lower_bounds )
      for (int i = 0; i < dim; ++i)
        if (parameters_to_optimize[i]) {
          double old = x[i];
          x[i] = std::max<double>(x[i], lower_bounds[i]);
          dx[i] += x[i] - old;
        }

    if ( use_upper_bounds )
      for (int i = 0; i < dim; ++i)
        if (parameters_to_optimize[i]) {
          double old = x[i];
          x[i] = std::min<double>(x[i], upper_bounds[i]);
          dx[i] += x[i] - old;
        }

    // Release the internal vectors, so they won't be deallocated.
    x.move();
    dx.move();
  }

  void ModelFitter::print_solver_state( gsl_multifit_fdfsolver* solver ) const {
    vector f( solver-> f), x( solver-> x ), dx( solver-> dx );
    cerr << "Parameters: ";
    cerr << x << endl;
    cerr << "||wf||: " << f.norm() << endl;
    cerr << "||dx||: " << dx.norm() << endl;

    f.move(), x.move(), dx.move();
  }

  ModelFitter::Options::~Options() {
    delete [] parameters_to_optimize;
  }

////////////////////////////////////////////////////////////////////////////////
  ModelFitter::Target::Target( unsigned int n ) :
    ttac( n ), ttac_times( n ), weights( n, 1.0 )
  {
  }
}
