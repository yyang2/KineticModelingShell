#include "util.hpp"
#include <vector>
#include <cmath>
#include <gsl/gsl_spline.h>
#include <cassert>
#include <iostream>

using std::cout;
using std::endl;


namespace KM {

  double subconvk(float t1, float t2, double c1, double c2, double k, float t);

  gsl_vector* conv_exp( const vector& ti, const vector& ci, double ks, 
                        const vector& petime, double threshold ) {

    if (ks < threshold)
      return integrate( ti, ci, petime );

    int ib = 1, npt = petime.size();
    float ptime, ttest = ti[ib];
    double acc = 0.0;
    vector conv_res(npt);
    
    for (int ip = 0; ip < npt; ip++) {
      ptime = petime[ip];
      while (ptime > ttest) {
        double temp = subconvk( ti[ib - 1], ttest, ci[ib - 1], ci[ib], ks, ttest );
        acc += temp;
        ib++;
        ttest = ti[ib];
      }
      double frac = subconvk( ti[ib - 1], ttest, ci[ib - 1], ci[ib], ks, ptime );
      if (ks != 0.0)
        conv_res.set( ip, (acc + frac) * exp(-ks * ptime) / ks );
      else
        conv_res.set( ip, acc + frac );
    }
    
    return conv_res.move();
  }  

  
  gsl_vector* integrate(const vector & ti, const vector& ci, const vector & petime) {
    // Note: In the Matlab code, ib = 2, which is because arrays start their
    // index at 1, not 0. This way, no other expressions associated with ib
    // needs to be, or should be, changed.

    int ib = 1, npt = petime.size();
    double acc = 0.0, ttest = ti[ib];
    vector conv_res(npt);

    double ptime, t1, t2, c1, c2, dt, ai, area;
    for (int ip = 0; ip < npt; ip++) {
      ptime = petime[ip];
      while (ptime > ttest) {
        t1 = ti[ib - 1];
        t2 = ttest;
        c1 = ci[ib - 1];
        c2 = ci[ib];
        dt = t2 - t1;
        area = 0.5 * (c2 + c1) * dt;
        acc += area;
        ib++;
        ttest = ti[ib];
      }
      t1 = ti[ib - 1];
      t2 = ttest;
      c1 = ci[ib - 1];
      c2 = ci[ib];
      ai = (c2 - c1) / (t2 - t1);
      area = ai * (ptime - t1) * (ptime - t1) / 2 + c1 * (ptime - t1);

      conv_res.set(ip, acc + area);
    }

    return conv_res.move();
  }

  gsl_vector* pettsubdivide5(const vector& midt, double pstime) {
    const int lt = midt.size();

    vector stt(lt);
    vector ddt(lt);

    vector dpetimeRS(5 * lt);

    for (int i = 0; i < lt; i++) {
      if (i > 0)
        stt[i] = stt[i-1] + 2 * (midt[i - 1] - stt[i - 1]);
      ddt[i] = 0.4f * (midt[i] - stt[i]);
    }
    
    int a = 0;
    for (int n = 0; n < lt; n++) {
      for (int m = 0; m < 5; m++) {
        dpetimeRS[a++] = stt[n] + (0.5f + m) * ddt[n] + pstime;
      }
    }

    return dpetimeRS.move();
  }

  gsl_vector* expand_parameters(const vector& p, const vector& k, 
                                const bool* toggles)
  {
    vector kres = k;
    
    int j = 0;
    for (int i = 0; i < k.size(); i++) {
      if (toggles[i])
        kres.set(i, p[j++]);
    }

    return kres.move();
  }

  gsl_vector* condense_parameters(const vector& k, const bool* toggles)
  {
    int p_length = count( toggles, toggles + k.size(), true );
  
    vector p( p_length );

    int j = 0;
    for (int i = 0; i < k.size(); ++i) {
      if ( toggles[i] )
        p[j++] = k[i];
    }

    return p.move();
  }
  
  gsl_vector* linear_interpolation( const vector& xi, const vector& yi, 
                                    const vector& x )
  {
    Interpolator interp( xi, yi, gsl_interp_linear );

    const int N = x.size();
    vector y(N);
    for (int i = 0; i < N; ++i)
      y[i] = interp( x[i] );

    return y.move();
  }
  
  double subconvk(float t1, float t2, double c1, double c2, double k, float t) {
    double ai = (c2 - c1) / (t2 - t1);
    double bi = -ai * t1 + c1;
    double temp = -ai / k + bi;
    double res = ((ai * t + temp) * exp(k*t) - (ai * t1 + temp) * exp(k*t1));
    return res;
  }

  ////////////////////////////////////////
  //// Interpolator
  ////////////////////////////////////////

  Interpolator::Interpolator( const vector& x, const vector& y, 
    const gsl_interp_type* T )
  {
    assert( x.size() == y.size() );

    _acc = gsl_interp_accel_alloc();
    _spline = gsl_spline_alloc( T, x.size() );

    gsl_spline_init( _spline, x.raw()->data, y.raw()->data, x.size() );
  }

  double Interpolator::eval( double x ) const
  {
    return gsl_spline_eval( _spline, x, _acc );
  }

  // evaluate the interpolator
  double Interpolator::eval( double x, int n ) const 
  {
    switch (n)
    {
    case 1:
      return gsl_spline_eval_deriv( _spline, x, _acc );
    case 2:
      return gsl_spline_eval_deriv2( _spline, x, _acc );
    default:
      //case 0:
      return gsl_spline_eval( _spline, x, _acc );
    }
  }
      
  Interpolator::~Interpolator()
  {
    gsl_spline_free( _spline );
    gsl_interp_accel_free( _acc );
  }
}
