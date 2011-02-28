#include "global.hpp"
#include "model.hpp"
#include "util.hpp"
#include "mat.hpp"
#include <cmath>
#include <cassert>
#include <gsl/gsl_interp.h>
#include <gsl/gsl_spline.h>

namespace KM {

  void ModelInput::extend_to( double t ) {
    if ( times[0] > 0 ) {
      times.prepend( 0 );
      values.prepend( 0 );
    }

    if ( times.last() < t ) {
      times.append( t );
      values.append( values.last() );
    }
  }

  void Model::add_input( const vector& times, const vector& values )
  {
    assert( times.size() == values.size() &&
            "times and values must be of the same length" );

    ModelInput* input = new ModelInput( times.size() );
    input->times = times;
    input->values = values;

    _inputs.push_back( input );
  }

  void Model::clear_inputs( )
  {
    for (unsigned int i = 0; i < _inputs.size(); ++i)
      delete _inputs[i];

    _inputs.clear();
  }

////////////////////////////////////////////////////////////////////////////////
//// TwoCompFuncAvgModel functions

  void TwoCompFuncAvgModel::setup( const vector& petime )
  {
    assert( !fwin || _inputs.size() >= 2 );

    int numInputs = fwin ? 2 : 1;
    for (int i = 0; i < numInputs; ++i)
      _inputs[i]->extend_to( petime.last() + pstime + 10 );

    _ci.copy( _inputs[0]->values );
    if (fwin)
      _wbi.copy( _inputs[1]->values );
  }

  gsl_vector* TwoCompFuncAvgModel::compute( const vector& pp,
                                            const vector& petime ) const
  {
    int ind = 0;

    double threshold = 1e-7;

    vector dpetime = pettsubdivide5( petime, pstime + pp[5] );

    const double a = 1.0, b = -(pp[1] + pp[2] + pp[3]), c = pp[1] * pp[3];

    double disc = b * b - 4.0 * a * c;

    if (disc > 0.0)
      ind = 1;

    double disc_rt = sqrt(ind * disc);

    double ks = 0.5 * (-b - disc_rt);

    vector input_times = _inputs[0]->times;
    vector conv_res = conv_exp(input_times, _ci, ks, dpetime);
    vector nmf = (pp[2] + pp[3] - ks) * conv_res;

    ks = 0.5 * (-b + disc_rt);
    conv_res = conv_exp(input_times, _ci, ks, dpetime);
    nmf -= (pp[2] + pp[3] - ks) * conv_res;

    vector nmfSum( nmf.size() / 5 );
    vector temp = linear_interpolation(
      input_times, this->fwin ? _wbi : _ci, dpetime);

    disc_rt = std::min( disc_rt, threshold );

    temp.replaceNaN();

    if ( this->nh3 )
      nmf = pp[0] * nmf / disc_rt + (pp[4] + pp[0]) * temp;
    else
      nmf = pp[0] * nmf / disc_rt + pp[4] * temp;

    matrix nmfRes(nmf, 5, nmf.size() / 5 );
    return (nmfRes.sum( ACROSS_COLUMN ) * 0.2).move();
  }

////////////////////////////////////////////////////////////////////////////////
//// FDopaModel methods

  void FDopaModel::setup( const vector& times )
  {
    assert( _inputs.size() == 3 );

    for (int i = 0; i < 3; ++i)
      _inputs[i]->extend_to( times.last() + pstime + 10 );
  }

  gsl_vector* FDopaModel::compute( const vector& pp, 
                                   const vector& petime ) const
  {
    double K1 = pp[0], k2 = pp[1], k3 = pp[2], k4 = pp[3], k5_over_K1 = pp[4];
    double Vb = pp[6], time_delay = pp[7];

    const double threshold = 1e-7;

    vector refined_times = pettsubdivide5( petime, pstime + time_delay );
    vector conv_res_td = conv_exp( _inputs[0]->times, _inputs[0]->values, 
                                   k2 + k3, refined_times, threshold );

    vector nmf = K1 * conv_res_td;
    vector conv_res_fdg = conv_exp( refined_times, nmf, k4,
                                    refined_times, threshold );
    nmf *= k3 * conv_res_fdg;

    const double k5 = k5_over_K1 * K1;
    double ks = k5 / pp[5];
    nmf += k5 * vector( conv_exp( _inputs[1]->times, _inputs[1]->values,
                                  ks, refined_times ) );

    vector wbi = 1.01 * 0.6 * vector( _inputs[0]->interp( refined_times ) ) +
      1.08 * vector( _inputs[1]->interp( refined_times ) ) +
      1.01 * 0.6 * vector( _inputs[2]->interp( refined_times ) );

    wbi.replaceNaN();
    nmf += Vb * wbi;

    matrix nmfRes(nmf, 5, nmf.size() / 5 );
    return ( nmfRes.sum( ACROSS_COLUMN ) * 0.2 ).move();
  }
}
