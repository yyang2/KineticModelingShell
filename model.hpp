#ifndef MODEL_HPP__
#define MODEL_HPP__

#include "global.hpp"
#include "vec.hpp"
#include "mat.hpp"
#include <gsl/gsl_interp.h>
#include <gsl/gsl_spline.h>
#include "ode.hpp"
#include "util.hpp"

namespace KM {

  /**
   * Represents inputs for a model
   */
  struct ModelInput
  {
    ModelInput() { }
    ModelInput(int n) : times(n), values(n) { }

    // Default copy constructor
    // Default assignment operator

    /**
     * Extend the time range so that the maximum time is least \a t and the
     * minimum time is 0.
     */
    void extend_to( double t );

    /**
     * Compute the linearly-interpolated values at the supplied times.
     */
    gsl_vector* interp( const vector& _interp_times ) {
      return linear_interpolation( times, values, _interp_times );
    }

    vector times;
    vector values;
  };

  /*abstract*/
  class Model
  {
  public:
    Model( ) : pstime(0) { }

    /**
     * Perform any necessary internal computations necessary before running the
     * model with any parameters set. This method is called by ModelFitter
     * before fitting begins.
     * \see ModelFitter
     */
    virtual void setup( const vector& petime ) { }

    /**
     * Compute the tissue concentrations at the given times \a petime,
     * given the model parameters \a k.
     * @param k Parameters of the model
     * @param petime Times on which to evaluate the model
     */
    virtual gsl_vector* compute( const vector& k, const vector& petime ) const = 0;

    /**
     * Returns the number of parameters expected by Model::compute.
     */
    virtual unsigned int num_parameters() const = 0;

    // Data management
    void add_input( const vector& times, const vector& values );
    void clear_inputs( );

    virtual ~Model() { 
      clear_inputs();
    }

  protected:
    std::vector<ModelInput*> _inputs;
    double pstime; //< Time delay
  };

  class TwoCompFuncAvgModel : public Model
  {
  public:
    TwoCompFuncAvgModel( bool fwin_, bool nh3_ )
      : fwin( fwin_ ), nh3( nh3_ ) { }

    virtual void setup( const vector& petime );
    virtual gsl_vector* compute( const vector& k, const vector& petime ) const;
    virtual unsigned int num_parameters() const {
      return 6;
    }

    bool fwin, nh3;

  private:
    vector _ci, _wbi;
  };

  class FDGModel : public TwoCompFuncAvgModel
  {
  public:
    FDGModel(  )
      : TwoCompFuncAvgModel( false, false )
    {

    }
  };

  /**
   * \class FDopaModel
   * 5-compartment FDOPA model
   */
  class FDopaModel : public Model
  {
  public:
    FDopaModel( );
    
    virtual void setup( const vector& times );
    virtual gsl_vector* compute( const vector& k, const vector& petime ) const;
    virtual unsigned int num_parameters() const {
      return 8;
    }

  private:
  };

  /**
   * \class GenericGraphModel
   * User-defined model, with an arbitrary number of compartments. The model is
   * defined by a user-provided graph of compartments. Compartments are
   * characterized by how they contribute to the tissue result and/or inputs.
   */
  class GenericGraphModel : public Model
  {
  public:
    GenericGraphModel( int num_compartments, const bool adjacency_matrix [],
                       const bool input_modifier [], const bool tissue_modifier [] );


    virtual void setup( const vector& times );
    virtual gsl_vector* compute( const vector& k, const vector& petime ) const;
    virtual unsigned int num_parameters() const;

    /**
     * Return the number of one-way connections between compartments.
     */
    int num_connections() const { return _num_connections; }

    /**
     * Return true iff compartment \a i is connected to compartment \a j.
     */
    bool is_connected(int i, int j) const {
      return _full_adjacency_mat[i * _compartments + j];
    }

    // convert between intuitive full matrix form and
    // internal parameter form.

    /**
     * Convert a matrix of parameter values for connection rates between
     * compartments and vector of input volumes to a flat vector.
     */
    gsl_vector* parameter_vector( const matrix& connections, const vector& volumes ) const;

    /**
     * Convert a vector of parameters values to the intuitive matrix of
     * connection values.
     */
    gsl_matrix* connection_matrix( const vector& ) const;

    unsigned int inputs() const { return _input_indices.size(); }
    unsigned int non_inputs() const { return _non_input_indices.size(); }

    virtual ~GenericGraphModel();

  private:
    void cleanup();

    /**
     * Internal function to simulate the running system.
     * RIF == Regional Injection Function
     */
    class RIF : boost::noncopyable, public ODESystem {
    public:
      RIF( const matrix& K, const matrix& B,
           const std::vector< ModelInput* >& inputs );

      int func(double t, const vector& y, gsl_vector* dydt);

      ~RIF( );

    private:
      const matrix& _K, _B;
      std::vector< Interpolator* > _interpolators;
    };


    /**
     * Compute the coefficient matrix \f$K\f$ from a matrix of compartment
     * connection rates.
     */
    gsl_matrix* K( const matrix& cc ) const;

    int _compartments;
    int _num_connections;

    bool* _full_adjacency_mat;
    std::vector<int> _input_indices;;
    std::vector<int> _non_input_indices;
    std::vector<bool> _tissue_mod;

    ODESolver* _ode_solver;
  };
}

#endif
