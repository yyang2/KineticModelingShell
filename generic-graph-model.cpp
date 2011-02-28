#include "model.hpp"
#include <algorithm>
#include <cassert>

namespace KM {

  using std::copy;

  GenericGraphModel::GenericGraphModel( int num_compartments,
                                        const bool adjacency_matrix[],
                                        const bool input_modifier [],
                                        const bool tissue_modifier [] )
  : _ode_solver(NULL) {
    _compartments = num_compartments;

    const int c2 = _compartments * _compartments;
    _full_adjacency_mat = new bool[ c2 ];
    copy( adjacency_matrix, adjacency_matrix + c2,
          _full_adjacency_mat );

    for (int i = 0; i < _compartments; ++i) {
      // For future ease of use, assume compartments are not connected to
      // themselves.
      _full_adjacency_mat[ i * _compartments + i ] = false;

      // fill the list of inputs and tissue contributors
      if ( input_modifier[i] )
        _input_indices.push_back( i );
      else
        _non_input_indices.push_back( i );

      _tissue_mod.push_back( tissue_modifier[i] );
    }

    _num_connections = count( _full_adjacency_mat, _full_adjacency_mat + c2, true );
  }

  unsigned int GenericGraphModel::num_parameters() const
  {
    return inputs() + num_connections();
  }

  gsl_vector* GenericGraphModel::parameter_vector(
    const matrix& mat, const vector& volumes ) const
  {
    assert( mat.rows() == _compartments );
    assert( mat.cols() == _compartments );
    assert( (unsigned int)volumes.size() == inputs() );

    vector k( num_connections() + inputs() );
    int n = 0;
    for (int i = 0; i < _compartments; ++i)
      for (int  j = 0; j < _compartments; ++j)
        if ( is_connected(i, j) )
          k[n++] = mat(i, j);

    for ( unsigned int i = 0; i < inputs(); ++i )
      k[n++] += volumes[i];

    return k.move();
  }

  gsl_matrix* GenericGraphModel::connection_matrix( const vector& v ) const
  {
    assert( (unsigned int)v.size() == num_parameters() );

    matrix mat( _compartments, _compartments );
    int n = 0;
    for (int i = 0; i < _compartments; ++i)
      for (int  j = 0; j < _compartments; ++j)
        if ( is_connected(i, j) )
          mat(i, j) = v[n++];

    return mat.move();
  }

  gsl_matrix* GenericGraphModel::K( const matrix& cc ) const
  {
    vector cc_sum_into = cc.sum( ACROSS_COLUMN );

    matrix K_ret( non_inputs(), non_inputs() );

    // In general, K(i, j) is the connection from i to j. If i == j, then K(i,
    // j) \equiv K(i, i) is the negative sum of all elements flowing in.
    for (size_t i = 0; i < non_inputs(); ++i) {
      for (size_t j = 0; j < non_inputs(); ++j) {

        // K(i, j) is the negative sum of all inputs
        if (i == j)
          K_ret(i, j) = -cc_sum_into[ _non_input_indices[i] ];
        else
          K_ret(i, j) = cc( _non_input_indices[i], _non_input_indices[j] );
      }
    }

    return K_ret.move();
  }

  void GenericGraphModel::cleanup( ) {
    delete _ode_solver;
  }

  void GenericGraphModel::setup( const vector& times )
  {
    cleanup();
    _ode_solver = new ODESolver( non_inputs() );
  }

  gsl_vector* GenericGraphModel::compute( const vector& pp,
                                          const vector& petime ) const
  {
    // create the derivative matrix for the ODE
    matrix cc_mat = connection_matrix( pp );
    matrix K = this->K( cc_mat );

    matrix B( _non_input_indices.size(), _input_indices.size() );

    for (int i = 0; i < B.rows(); ++i) {
      for (int j = 0; j < B.cols(); ++j) {
        B(i, j) = cc_mat( _non_input_indices[i], _input_indices[j] );
      }
    }

    // create the injection to simulate the input curves
    RIF rif( K, B, _inputs );

    // Initially, all simulated compartments are zeroes.
    vector y0( non_inputs() );

    // Solve the ODE system to compute compartment concentrations at the given times.
    matrix yn = _ode_solver->solve( 0.0, petime, y0, &rif );

    // add contributions from input tissues, modified by volume parameter
    vector result( petime.size() );
    for (unsigned int i = 0; i < _input_indices.size(); ++i)
      if ( _tissue_mod[ _input_indices[i] ] )
        result += pp[ num_connections() + i ] *
          vector( linear_interpolation( _inputs[i]->times, _inputs[i]->values, petime ) );

    // add contributions from non-input tissues
    for (unsigned int i = 0; i < _non_input_indices.size(); ++i)
      if ( _tissue_mod[ _non_input_indices[i] ] )
        result += yn.get_row( i );

    return result.move();
  }

  GenericGraphModel::~GenericGraphModel( )
  {
    cleanup();
    delete [] _full_adjacency_mat;
  }

////////////////////////////////////////////////////////////////////////////////

  GenericGraphModel::RIF::RIF( const matrix& K, const matrix& B,
                               const std::vector< ModelInput* >& inputs )
    : _K(K), _B(B) {

    for (unsigned int i = 0; i < inputs.size(); ++i)
      _interpolators.push_back( new Interpolator(inputs[i]->times,
                                                 inputs[i]->values) );
  }

  int GenericGraphModel::RIF::func( double t, const vector& y,
                                    gsl_vector* dydt ) {

    vector u( _interpolators.size() );
    for ( unsigned int i = 0; i < _interpolators.size(); ++i )
      u[i] = _interpolators[i]->eval( t );

    gsl_vector_memcpy( dydt, (_K * y + _B * u).raw() );
    return GSL_SUCCESS;
  }

  GenericGraphModel::RIF::~RIF() {
    for (unsigned int i = 0; i < _interpolators.size(); ++i)
      delete _interpolators[i];
  }
}
