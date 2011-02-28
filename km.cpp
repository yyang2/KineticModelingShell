#include <iostream>
#include <fstream>
#include <string>
#include <memory.h>

#include "fitter.hpp"
#include "gsl_ext.hpp"
#include "mat.hpp"
#include "util.hpp"
#include "vec.hpp"

using std::cout;
using std::ifstream;
using std::endl;
using std::string;

using KM::vector;
using KM::Model;
using KM::TwoCompFuncAvgModel;
using KM::ModelFitter;

using namespace KM;

bool initial_only = false;

void load_two_column_data(const char* filename,
                          std::vector<double>& times,
                          std::vector<double>& values)
{
  times.clear();
  values.clear();

  ifstream file( filename );
  while ( file && !file.eof() )
  {
    double d;
    file >> d;
    if ( !(file && !file.eof() ))
      break;
    times.push_back( d );
    file >> d;
    values.push_back( d );
  }
  file.close();
}

int main(int argc, char** args)
{
  std::vector<double> ttac_times, ttac;
  load_two_column_data( "examples/fdg-ttac.txt", ttac_times, ttac );

  std::vector<double> input_times, curve;
  load_two_column_data( "examples/fdg-input.txt", input_times, curve );
/*
  bool adj [] = {
    false, true,  true,  false, false, false, false,
    true,  false, true,  true,  false, false, false,
    true,  true,  false, false, true,  false, false, 
    false, true,  false, false, true,  true,  false,
    false, false, true,  true,  false, false, true,
    false, false, false, true,  false, false, true,
    false, false, false, false, true,  true,  false };

  bool input [] = { true, false, false, false, false, false, false };
  bool tissue [] = { true, true, true, true, true, true, true };

  GenericGraphModel* model = new GenericGraphModel( 7, adj, input, tissue );
*/
  KM::Model* model = new FDGModel( );

  model->add_input( KM::vector(input_times), KM::vector( curve ) );

  KM::ModelFitter fitter;
  fitter.max_iterations = 30;

  // FDG model
  const int NUM_PARAMETERS = 6;
  double ip [] = {0.05, 0.25, 0.05, 0.002, 0.03, 0.0}; // (FDG)
  vector init_param(ip, NUM_PARAMETERS);
  bool param_toggles [] = {true, true, true, true, true, false};

  // User-defined model
/*
  const int NUM_PARAMETERS = 19;
  double ip [] = {
  0.14, 0.09, 0.0, 0.18, 0.009, 0.0,
  0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
  0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
  0.07};
  vector init_param(ip, NUM_PARAMETERS);
  bool param_toggles[NUM_PARAMETERS];
  for (int i = 0; i < NUM_PARAMETERS; ++i)
  param_toggles[i] = (ip[i] > 0);
*/

  // Generic Graph Model
/*
  const int NUM_PARAMETERS = 19;
  KM::matrix cc(7, 7);
  cc(1, 0) = 1.0;
  cc(3, 1) = 1.0;
  cc(0, 1) = 1.0;
  cc(1, 3) = 0.1;
 
  KM::vector volume(1);
  volume[0] = 0.02;

  vector init_param = model->parameter_vector( cc, volume );
  bool param_toggles[NUM_PARAMETERS];
  for (int i = 0; i < NUM_PARAMETERS; ++i)
    param_toggles[i] = (init_param[i] > 0);  
*/

  KM::vector ttac_v(ttac);
  KM::vector ttac_t(ttac_times);

  KM::vector results;

  if (initial_only) {
    model->setup( ttac_t );
    results.copy( model->compute( init_param, ttac_t ) );
  } 
  else {
    ModelFitter::Target target( ttac_v.size() );
    target.ttac = ttac_v;
    target.ttac_times = ttac_t;

    ModelFitter::Options options( NUM_PARAMETERS );
    memcpy( options.parameters_to_optimize, param_toggles, 
            sizeof( param_toggles ) );

    fitter.verbose = true;
    fitter.absolute_step_threshold = 0;
    fitter.relative_step_threshold = 0;

    KM::ModelFitter::Result* result = fitter.fit_model_to_tissue_curve( 
      model, &target, init_param, &options );
    
    results = model->compute(
      expand_parameters( result->parameters, 
                         init_param, param_toggles ),
      ttac_t );
    
    delete result;
  }
  
  for (int i = 0; i < ttac_t.size(); ++i)
    cout << ttac_t[i] << "\t"
         << results[i] << "\t"
         << ttac[i] << "\n";

  vector r = results - ttac_v;
  double rss = (r*r).sum();
  cout << rss << endl;
  
  delete model;

  return 0;
}
