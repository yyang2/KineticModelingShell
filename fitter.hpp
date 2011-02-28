#ifndef FITTER_HPP__
#define FITTER_HPP__

#include "vec.hpp"
#include "mat.hpp"
#include "model.hpp"
#include <gsl/gsl_multifit_nlin.h>

namespace KM {

  enum MFStatus
  {
    MF_MAX_ITERATIONS,
    MF_GRADIENT_THRESHOLD_REACHED,
    MF_DELTA_THRESHOLD_REACHED,
    MF_ERROR_THRESHOLD_REACHED,
    MF_NO_STEP_SIZE_FOUND,
    MF_CONTINUE
  };

  /**
   * \class ModelFitter
   * Perform least squares minimization on a multi-parameter model
   */
  class ModelFitter
  {
  public:

    struct Options
    {
      Options( unsigned int n );

      bool* parameters_to_optimize;

      //! Lower bounds on the full parameter set.
      bool use_lower_bounds;
      vector lower_bounds;

      //! Upper bounds on the full parameter set.
      bool use_upper_bounds;
      vector upper_bounds;

      int dim;

      /**
       * Constrain the parameter set to be within bounds.
       * Operates only on parameters to be optimized on. This updates solver->x
       * with the new values, as well as solver->dx.
       */
      void constrain_to_bounds( gsl_multifit_fdfsolver* solver ) const;

      ~Options( );
    };

    struct Target
    {
      Target() { }

      /**
       * Preallocates all vectors with the specified size
       */
      Target( unsigned int n );

      //! Tissue curve for the model to fit
      vector ttac;

      //! Corresponding times at which each point on curve is measured
      vector ttac_times;

      //! Weights associated with each curve sample
      vector weights;
    };

    /**
     * Return structure for ModelFitter::fit_model_to_tissue_curve
     */
    struct Result
    {
      vector parameters;
      vector func_value;
      matrix active_covariance; //< covariance matrix of fitted parameters only
      matrix jacobian;
      double wrss;

      MFStatus status;
    };

    ModelFitter()
      : verbose(false), gradient_threshold(0.0),
        absolute_step_threshold(0.0), relative_step_threshold(0.0),
        max_iterations(100) { }
    
    /**
     * Finds parameters for the model which minimize the weighted least squares
     * error with a given tissue curve.
     *
     * The function uses unscaled Levenberg-Marquardt to perform the least
     * squares optimization. 
     */
    Result* fit_model_to_tissue_curve(
      Model* model, ModelFitter::Target* input,
      const vector& initial_parameters, ModelFitter::Options* options );

    //! Toggle for using verbose output.
    bool verbose;

    double gradient_threshold;
    double absolute_step_threshold;
    double relative_step_threshold;;

    //! If \a max_iterations > 0, regression will stop after \a max_iterations
    //! iterations.
    int max_iterations;

  private:
    /**
     * Perform one iteration of the minimization strategy, along with a
     * parameter constraint to bounds if necessary
     */
    MFStatus iterate_solver( gsl_multifit_fdfsolver* solver,
                             const Options* options ) const;

    /**
     * Prints the current value of parameters and function values.
     */
    void print_solver_state( gsl_multifit_fdfsolver* solver ) const;

    /**
     * Ensure that the optimization problem is valid as specified.
     * Checks that all vectors are initialized and are the correct sizes. This
     * also checks that lower and upper bounds, if active, are not contradictory.
     */
    void validate_parameters( const Model* model, const Target* input,
                              const vector& initial_parameters,
                              const Options* options ) const;


    /**
     * Construct a return structure of relevant result information.
     */
    Result* createResult( const gsl_multifit_fdfsolver* solver,
                                       MFStatus status,
                                       const Target* target,
                          const Options* options );

    static int func( const gsl_vector* x, void* data, gsl_vector* f );
    static int jacobian( const gsl_vector* x, void* data, gsl_matrix* m );
    static int func_and_jacobian( const gsl_vector* x,
                                  void* data, gsl_vector* f, gsl_matrix* J );
  };
}

#endif
