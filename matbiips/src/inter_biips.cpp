//                                               -*- C++ -*-
/*! \file inter_biips.cpp
 * \brief
 *
 * \author  $LastChangedBy$
 * \date    $LastChangedDate$
 * \version $LastChangedRevision$
 * Id:      $Id$
 */

#include <deque>
#include "inter_utils.h"
#include <fstream>
#include "iostream/outStream.hpp"
#include "common/Accumulator.hpp"
#include "common/Utility.hpp"
#include "compiler/Compiler.hpp"
#include "MatlabFunction.hpp"
std::deque<Console_ptr> consoles;
std::deque<ProgressBar_ptr> progress;

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    
    if (nrhs < 1) {
     mexErrMsgIdAndTxt("inter_biips:Args", "must have at least one argument ");
    }
  
    if ( mxIsChar(prhs[0]) != 1)
      mexErrMsgIdAndTxt( "inter_biips:inputNotString",
              "Input must be a string.");
    
    if (mxGetM(prhs[0])!=1)
      mexErrMsgIdAndTxt( "inter_biips:inputNotVector",
              "Input must be a row vector.");
    
    char * input_buf = mxArrayToString(prhs[0]);
   
    String name_func = String(input_buf);

    /////////////////////////////////////////
    // MAKE_CONSOLE FUNCTION
    /////////////////////////////////////////
    if (name_func == "make_console") {
   
          consoles.push_back(Console_ptr(new Console(mbiips_cout, mbiips_cerr)));
          plhs[0] = mxCreateDoubleMatrix(1, 1, mxREAL);
          *mxGetPr(plhs[0]) = static_cast<double>(consoles.size()-1);
    }
   
    /////////////////////////////////////////
    // CLEAR_CONSOLE FUNCTION
    /////////////////////////////////////////
    else if (name_func == "clear_console") {

       CheckRhs(nrhs, 1, name_func);
       Size id = GetConsoleId(consoles, prhs[1], name_func);
       consoles[id].reset();
       
    }       
    /////////////////////////////////////////
    // CLEAR_ALL_CONSOLE FUNCTION
    /////////////////////////////////////////
    else if (name_func == "clear_all_console") {
       consoles.clear();
       
    }       
    /////////////////////////////////////////
    // CHECK_MODEL FUNCTION
    /////////////////////////////////////////
    else if (name_func == "check_model") {

       CheckRhs(nrhs, 2, name_func);
       
       char * filename = mxArrayToString(prhs[2]);
       
       Size id = GetConsoleId(consoles, prhs[1], name_func);
       Console_ptr p_console = consoles[id]; 

       if (! p_console->CheckModel(String(filename), VERBOSITY))
                 mexErrMsgTxt("Model syntax is incorrect.");
       mxFree(filename);
    }       
    /////////////////////////////////////////
    // COMPILE_MODEL FUNCTION
    /////////////////////////////////////////
    else if (name_func == "compile_model") {

       CheckRhs(nrhs, 4, name_func);
       Size id = GetConsoleId(consoles, prhs[1], name_func);
       Console_ptr p_console = consoles[id];
       
       CheckArgIsStruct(2);

       std::map<String, MultiArray> data_map = writeDataTable<MultiArray::StorageOrderType>(prhs[2]);

       CheckArgIsLogical(3);
       Bool sample_data = static_cast<Bool>(*mxGetLogicals(prhs[3]));
       Size data_rng_seed = static_cast<Size>(*mxGetPr(prhs[4]));

       // Compile model
       if (! p_console->Compile(data_map, sample_data, data_rng_seed, VERBOSITY))
         throw RuntimeError("Failed to compile model.");
       if (sample_data && VERBOSITY>1)
         mbiips_cout << INDENT_STRING << "data.rng.seed = " << data_rng_seed << endl;
        
    }      
    /////////////////////////////////////////
    // GET_DATA FUNCTION
    /////////////////////////////////////////
    else if (name_func == "get_data") {

       CheckRhs(nrhs, 1, name_func);
       Size id = GetConsoleId(consoles, prhs[1], name_func);
       Console_ptr p_console = consoles[id];
       
       std::map<String, MultiArray> data_table;

       if (! p_console->DumpData(data_table))
         throw RuntimeError("Failed to read data.");

       readDataTable<MultiArray::StorageOrderType>(data_table, &plhs[0]);
        
    }
    /////////////////////////////////////////
    // LOAD MODULE FUNCTION
    /////////////////////////////////////////
    else if (name_func == "load_module") {

       CheckRhs(nrhs, 1, name_func);
       
       char * mod_name = mxArrayToString(prhs[1]);
       plhs[0] = mxCreateLogicalMatrix(1, 1);
       if (!std::strcmp(mod_name,"basemod")) {
         load_base_module();
         *mxGetLogicals(plhs[0]) = 1;
       }
       else {
         *mxGetLogicals(plhs[0]) = 0;
       }
    }      
    
    /////////////////////////////////////////
    // VERBOSITY FUNCTION
    /////////////////////////////////////////
    else if (name_func == "verbosity") {

       CheckRhs(nrhs, 1, name_func);
       Size old_verb = VERBOSITY;
       VERBOSITY = static_cast<Size>(*mxGetPr(prhs[1]));
       plhs[0] = mxCreateDoubleMatrix(1, 1, mxREAL);
       *mxGetPr(plhs[0]) = old_verb;
    }      
    
    /////////////////////////////////////////
    // GET_VARIABLE_NAMES FUNCTION
    /////////////////////////////////////////
    else if (name_func == "get_variable_names") {

       CheckRhs(nrhs, 1, name_func);
       Size id = GetConsoleId(consoles, prhs[1], name_func);
       Console_ptr p_console = consoles[id];
       
       const Types<String>::Array & names = p_console->VariableNames();
       mwSize ndim = names.size();
       mwSize dims[] = { ndim };
       plhs[0] = mxCreateCellArray(1, dims);
       
       for (int i = 0; i < ndim ; ++i) {
            String var_name = names[i]; 
           mwSize  nd[] = { var_name.size() }; 
           mxArray * value = mxCreateCharArray(1, nd);
           std::copy(var_name.c_str(), var_name.c_str() + var_name.size(), mxGetChars(value));
           mxSetCell(plhs[0], i, value);
       }
    }      
    /////////////////////////////////////////
    // SET_DEFAULT_MONITORS FUNCTION
    /////////////////////////////////////////
    else if (name_func == "set_default_monitors") {

       CheckRhs(nrhs, 1, name_func);
       Size id = GetConsoleId(consoles, prhs[1], name_func);
       Console_ptr p_console = consoles[id];
        
       if (VERBOSITY>1)
          mbiips_cout << PROMPT_STRING << "Setting default filter monitors for backward smoothing step" << endl;

       if (!p_console->SetDefaultFilterMonitors())
         throw RuntimeError("Failed to set default filter monitors");

    }
    /////////////////////////////////////////
    // SET_FILTER_MONITORS FUNCTION
    /////////////////////////////////////////
    else if (name_func == "set_filter_monitors") {

       CheckRhs(nrhs, 4, name_func);
       Size id = GetConsoleId(consoles, prhs[1], name_func);
       Console_ptr p_console = consoles[id];
        
       if (VERBOSITY>1)
          mbiips_cout << PROMPT_STRING << "Filter monitoring variables:";
       
       Size nbVarNames = static_cast<Size>(mxGetNumberOfElements(prhs[2]));

       if ((nbVarNames != mxGetNumberOfElements(prhs[3])) || (nbVarNames != mxGetNumberOfElements(prhs[4])))
            mbiips_cerr << name_func <<  ": arguments 2, 3 and 4 must have the same number of Elements" << endl;
   
       CheckArgIsCell(2);
       CheckArgIsCell(3);
       CheckArgIsCell(4);
        
       for(int i = 0; i <  nbVarNames; ++i )
        {
          const mxArray * m   = mxGetCell(prhs[2], i);
          const mxArray * low = mxGetCell(prhs[3], i);
          const mxArray * up  = mxGetCell(prhs[4], i);
         
         CheckIsString(m);
         String name = mxArrayToString(m);
         
         if (!mxIsEmpty(low)) {
           CheckIsDouble(low);
          }
         if (!mxIsEmpty(up)) {
           CheckIsDouble(up);
         }

          IndexRange range = makeRange(low, up);
         Bool ok = p_console->SetFilterMonitor(name, range);
          if (ok && VERBOSITY>1)
             {
                 mbiips_cout << " " << name;
                 if (!range.IsNull())
                     mbiips_cout << range;
             }
        } 
       
       if (VERBOSITY>1)
            mbiips_cout << endl;
    }
    
    /////////////////////////////////////////
    // SET_GEN_TREE_MONITORS FUNCTION
    /////////////////////////////////////////
    else if (name_func == "set_gen_tree_monitors") {

       CheckRhs(nrhs, 4, name_func);
       Size id = GetConsoleId(consoles, prhs[1], name_func);
       Console_ptr p_console = consoles[id];
        
       if (VERBOSITY>1)
          mbiips_cout << PROMPT_STRING << "Smooth monitoring variables:";
       
       mwSize nbVarNames = mxGetNumberOfElements(prhs[2]);

       if ((nbVarNames != mxGetNumberOfElements(prhs[3])) || (nbVarNames != mxGetNumberOfElements(prhs[4])))
            mbiips_cerr << name_func <<  ": arguments 2, 3 and 4 must have the same number of Elements" << endl;
   
       CheckArgIsCell(2);
       CheckArgIsCell(3);
       CheckArgIsCell(4);

       for(int i = 0; i <  nbVarNames; ++i )
        {
          const mxArray * m   = mxGetCell(prhs[2], i);
          const mxArray * low = mxGetCell(prhs[3], i);
          const mxArray * up  = mxGetCell(prhs[4], i);
         
         CheckIsString(m);
         String name = mxArrayToString(m);
          
          
         if (!mxIsEmpty(low)) {
           CheckIsDouble(low);
          }
         if (!mxIsEmpty(up)) {
           CheckIsDouble(up);
         }
          IndexRange range = makeRange(low, up);
          Bool ok = p_console->SetGenTreeMonitor(name, range);
          if (ok && VERBOSITY>1)
             {
                 mbiips_cout << " " << name;
                 if (!range.IsNull())
                     mbiips_cout << range;
             }
        } 
       
       if (VERBOSITY>1)
            mbiips_cout << endl;
    }
    
    /////////////////////////////////////////
    // SET_BACKWARD_SMOOTH_MONITORS FUNCTION
    /////////////////////////////////////////
    else if (name_func == "set_backward_smooth_monitors") {

       CheckRhs(nrhs, 4, name_func);
       Size id = GetConsoleId(consoles, prhs[1], name_func);
       Console_ptr p_console = consoles[id];
        
       if (VERBOSITY>1)
          mbiips_cout << PROMPT_STRING << "Backward smoother monitoring variables:";
       
       mwSize nbVarNames = mxGetNumberOfElements(prhs[2]);

       if ((nbVarNames != mxGetNumberOfElements(prhs[3])) || (nbVarNames != mxGetNumberOfElements(prhs[4])))
            mbiips_cerr << name_func <<  ": arguments 2, 3 and 4 must have the same number of Elements" << endl;
   
       CheckArgIsCell(2);
       CheckArgIsCell(3);
       CheckArgIsCell(4);

       for(int i = 0; i <  nbVarNames; ++i )
        {
          const mxArray * m   = mxGetCell(prhs[2], i);
          const mxArray * low = mxGetCell(prhs[3], i);
          const mxArray * up  = mxGetCell(prhs[4], i);
         
         CheckIsString(m);
         String name = mxArrayToString(m);
          
         if (!mxIsEmpty(low)) {
           CheckIsDouble(low);
          }
         if (!mxIsEmpty(up)) {
           CheckIsDouble(up);
         }
          
          IndexRange range = makeRange(low, up);
          Bool ok = p_console->SetBackwardSmoothMonitor(name, range);
          if (ok && VERBOSITY>1)
             {
                 mbiips_cout << " " << name;
                 if (!range.IsNull())
                     mbiips_cout << range;
             }
        } 
       
       if (VERBOSITY>1)
            mbiips_cout << endl;
    }
    
    /////////////////////////////////////////
    // BUILD_SMC_SAMPLER FUNCTION
    /////////////////////////////////////////
    else if (name_func == "build_smc_sampler") {

       CheckRhs(nrhs, 2, name_func);
       Size id = GetConsoleId(consoles, prhs[1], name_func);
       Console_ptr p_console = consoles[id];
       
       CheckArgIsLogical(2);
       Bool prior_flag = static_cast<Bool>(*mxGetLogicals(prhs[2]));

       if (!p_console->BuildSampler(prior_flag, VERBOSITY))
         throw RuntimeError("Failed to build sampler.");
    }
    
    /////////////////////////////////////////
    // IS_SAMPLER_BUILT FUNCTION
    /////////////////////////////////////////
    else if (name_func == "is_sampler_built") {

       CheckRhs(nrhs, 1, name_func);
       Size id = GetConsoleId(consoles, prhs[1], name_func);
       Console_ptr p_console = consoles[id];
       
       plhs[0] = mxCreateLogicalMatrix(1, 1);
       *mxGetLogicals(plhs[0]) =  (p_console->SamplerBuilt() ? 1 : 0);

    }
    
    /////////////////////////////////////////
    // RUN_SMC_SAMPLER FUNCTION
    /////////////////////////////////////////
    else if (name_func == "run_smc_sampler") {

       CheckRhs(nrhs, 5, name_func);
       Size id = GetConsoleId(consoles, prhs[1], name_func);
       Console_ptr p_console = consoles[id];

       CheckArgIsDouble(2);
       Size n_part = static_cast<Size>(*mxGetPr(prhs[2]));

       CheckArgIsDouble(3);
       Size smc_rng_seed = static_cast<Size>(*mxGetPr(prhs[3]));

       
       CheckArgIsDouble(4);
       Scalar  ess_threshold = static_cast<Scalar>(*mxGetPr(prhs[4]));
       
       CheckArgIsString(5);
       String resample_type = mxArrayToString(prhs[5]);

       Bool ok = p_console->RunForwardSampler(n_part, smc_rng_seed, resample_type, ess_threshold, VERBOSITY, VERBOSITY);

       plhs[0] = mxCreateLogicalMatrix(1, 1);
       *mxGetLogicals(plhs[0]) =  (ok ? 1 : 0);
    }
    
    
    /////////////////////////////////////////
    // GET_LOG_NORM_CONST FUNCTION
    /////////////////////////////////////////
    else if (name_func == "get_log_norm_const") {

       CheckRhs(nrhs, 1, name_func);
       Size id = GetConsoleId(consoles, prhs[1], name_func);
       Console_ptr p_console = consoles[id];
       
       Scalar log_norm_const;
       if(!p_console->GetLogNormConst(log_norm_const))
          throw RuntimeError("Failed to get log normalizing constant.");

       plhs[0] = mxCreateDoubleMatrix(1, 1, mxREAL);
       *mxGetPr(plhs[0]) = static_cast<double>(log_norm_const);

    }
    
    /////////////////////////////////////////
    // GET_FILTER_MONITORS FUNCTION
    /////////////////////////////////////////
    else if (name_func == "get_filter_monitors") {

       CheckRhs(nrhs, 1, name_func);
       Size id = GetConsoleId(consoles, prhs[1], name_func);
       Console_ptr p_console = consoles[id];
  
       std::map<String, NodeArrayMonitor> monitors_map;

       if (!p_console->DumpFilterMonitors(monitors_map))
         throw RuntimeError("Failed to dump filter monitors.");
       
       getMonitors<ColumnMajorOrder>(monitors_map, "filtering", &plhs[0]);

    }
    
    /////////////////////////////////////////
    // GET_GEN_TREE_MONITORS FUNCTION
    /////////////////////////////////////////
    else if (name_func == "get_gen_tree_monitors") {

       CheckRhs(nrhs, 1, name_func);
       Size id = GetConsoleId(consoles, prhs[1], name_func);
       Console_ptr p_console = consoles[id];
  
       std::map<String, NodeArrayMonitor> monitors_map;

       if (!p_console->DumpGenTreeMonitors(monitors_map))
         throw RuntimeError("Failed to dump gen tree monitors.");
       
       getMonitors<ColumnMajorOrder>(monitors_map, "smoothing", &plhs[0]);

    }
    
    /////////////////////////////////////////
    // GET_BACKWARD_SMOOTH_MONITORS FUNCTION
    /////////////////////////////////////////
    else if (name_func == "get_backward_smooth_monitors") {

       CheckRhs(nrhs, 1, name_func);
       Size id = GetConsoleId(consoles, prhs[1], name_func);
       Console_ptr p_console = consoles[id];
  
       std::map<String, NodeArrayMonitor> monitors_map;

       if (!p_console->DumpBackwardSmoothMonitors(monitors_map))
         throw RuntimeError("Failed to dump backward smooth monitors.");
       
       getMonitors<ColumnMajorOrder>(monitors_map, "backward_smoothing", &plhs[0]);

    }
    
    /////////////////////////////////////////
    // CLEAR_FILTER_MONITORS FUNCTION
    /////////////////////////////////////////
    else if (name_func == "clear_filter_monitors") {

       CheckRhs(nrhs, 2, name_func);
       Size id = GetConsoleId(consoles, prhs[1], name_func);
       Console_ptr p_console = consoles[id];
       
       CheckArgIsLogical(2);
       Bool release_only = static_cast<Bool>(*mxGetLogicals(prhs[2]));
  
       if (!p_console->ClearFilterMonitors(release_only))
         throw RuntimeError("Failed to clear filter monitors.");

    }
    
    /////////////////////////////////////////
    // CLEAR_GEN_TREE_MONITORS FUNCTION
    /////////////////////////////////////////
    else if (name_func == "clear_gen_tree_monitors") {

       CheckRhs(nrhs, 2, name_func);
       Size id = GetConsoleId(consoles, prhs[1], name_func);
       Console_ptr p_console = consoles[id];
  
       CheckArgIsLogical(2);
       Bool release_only = static_cast<Bool>(*mxGetLogicals(prhs[2]));
       
       if (!p_console->ClearGenTreeMonitors(release_only))
         throw RuntimeError("Failed to clear gen tree monitors.");

    }
    
    /////////////////////////////////////////
    // CLEAR_BACKWARD_SMOOTH_MONITORS FUNCTION
    /////////////////////////////////////////
    else if (name_func == "clear_backward_smooth_monitors") {

       CheckRhs(nrhs, 2, name_func);
       Size id = GetConsoleId(consoles, prhs[1], name_func);
       Console_ptr p_console = consoles[id];
  
       CheckArgIsLogical(2);
       Bool release_only = static_cast<Bool>(*mxGetLogicals(prhs[2]));
       
       if (!p_console->ClearBackwardSmoothMonitors(release_only))
         throw RuntimeError("Failed to clear backward smooth monitors.");

    }
    
    /////////////////////////////////////////
    // RUN_BACKWARD_SMOOTHER FUNCTION
    /////////////////////////////////////////
    else if (name_func == "run_backward_smoother") {

       CheckRhs(nrhs, 1, name_func);
       Size id = GetConsoleId(consoles, prhs[1], name_func);
       Console_ptr p_console = consoles[id];
  
       if (!p_console->RunBackwardSmoother(VERBOSITY,VERBOSITY))
         throw RuntimeError("Failed to run backward smoother.");

    }
    /////////////////////////////////////////
    // GET_SORTED_NODES FUNCTION
    /////////////////////////////////////////
    else if (name_func == "get_sorted_nodes") {

       CheckRhs(nrhs, 1, name_func);
       Size id = GetConsoleId(consoles, prhs[1], name_func);
       Console_ptr p_console = consoles[id];
      
       const char *field_names[] = { "id", "names", "type", "observed" };
       mwSize  dims[] = { 1};
       plhs[0] = mxCreateStructArray(1, dims, sizeof(field_names)/sizeof(char *), field_names);

       Size graph_size;
       if (!p_console->GraphSize(graph_size))
         throw RuntimeError("Failed to get graph size.");
      
       {// id assignment 
         Types<Size>::Array node_ids_vec;
         if (!p_console->DumpNodeIds(node_ids_vec))
            throw RuntimeError("Failed to dump node ids.");
         mxArray * id = mxCreateDoubleMatrix(1, node_ids_vec.size(), mxREAL);
         std::replace_copy(node_ids_vec.begin(), node_ids_vec.end(), mxGetPr(id), 
                           static_cast<Scalar>(NULL_NODEID), std::numeric_limits<Scalar>::quiet_NaN());
         mxSetFieldByNumber(plhs[0], 0, 0, id);
       }

       {// names assignment 
         Types<String>::Array node_names_vec;
         if (!p_console->DumpNodeNames(node_names_vec))
           throw RuntimeError("Failed to dump node names.");
       
         mwSize name_ndim = 1;
         mwSize name_dims[] = { node_names_vec.size() };
         mxArray * names = mxCreateCellArray(name_ndim, name_dims);
         for (int i = 0;  i <  node_names_vec.size() ; ++i) {
               mxArray * str = mxCreateString(node_names_vec[i].c_str());
                 mxSetCell(names, i, str);
         }
         mxSetFieldByNumber(plhs[0], 0, 1, names);
       }
       { // type assignment
         Types<NodeType>::Array node_types_vec;
         if (!p_console->DumpNodeTypes(node_types_vec))
            throw RuntimeError("Failed to dump node types.");
         mwSize type_ndim = 1;
         mwSize type_dims[] = { node_types_vec.size() };
         mxArray * types = mxCreateCellArray(type_ndim, type_dims);
         for (Size i=0; i<graph_size; ++i)
         {
           String type_str ;
          switch (node_types_vec[i])
           {
             case CONSTANT:
               type_str = "Constant";
               break;
             case Biips::LOGICAL:
               type_str = "Logical";
               break;
             case STOCHASTIC:
               type_str = "Stochastic";
               break;
             default:
               break;
           }
           mxArray * str = mxCreateString(type_str.c_str());
             mxSetCell(types, i, str);
        }
         mxSetFieldByNumber(plhs[0], 0, 2, types);
       }
      
       {// node_obs assignment 
         Flags node_obs_vec;
         if (!p_console->DumpNodeObserved(node_obs_vec))
            throw RuntimeError("Failed to dump node observed boolean.");
         mxArray * node_obs = mxCreateDoubleMatrix(1, node_obs_vec.size(), mxREAL);
         std::copy(node_obs_vec.begin(), node_obs_vec.end(), mxGetPr(node_obs));
         mxSetFieldByNumber(plhs[0], 0, 3, node_obs);
       }


    }
    /////////////////////////////////////////
    // GET_NODES_SAMPLERS FUNCTION
    /////////////////////////////////////////
    else if (name_func == "get_nodes_samplers") {

       CheckRhs(nrhs, 1, name_func);
       Size id = GetConsoleId(consoles, prhs[1], name_func);
       Console_ptr p_console = consoles[id];
      
       const char *field_names[] = { "iteration", "sampler"};
       mwSize  dims[] = { 1};
       plhs[0] = mxCreateStructArray(1, dims, sizeof(field_names)/sizeof(char *), field_names);

       Size graph_size;
       if (!p_console->GraphSize(graph_size))
         throw RuntimeError("Failed to get graph size.");
      
       {// node_iterations assignment 
         Types<Size>::Array node_iterations_vec;
         if (!p_console->DumpNodeIterations(node_iterations_vec))
            throw RuntimeError("Failed to dump node iterationss.");
         mxArray * node_iterations = mxCreateDoubleMatrix(1, node_iterations_vec.size(), mxREAL);
         std::replace_copy(node_iterations_vec.begin(), node_iterations_vec.end(), mxGetPr(node_iterations), 
                           static_cast<Scalar>(BIIPS_SIZENA), std::numeric_limits<Scalar>::quiet_NaN());
         mxSetFieldByNumber(plhs[0], 0, 0, node_iterations);
       }
       
       {// node_samplers assignment 
         Types<String>::Array node_samplers_vec;
         if (!p_console->DumpNodeSamplers(node_samplers_vec))
           throw RuntimeError("Failed to dump node samplers.");
       
         mwSize name_ndim = 1;
         mwSize name_dims[] = { node_samplers_vec.size() };
         mxArray * samplers = mxCreateCellArray(name_ndim, name_dims);
         for (int i = 0;  i <  node_samplers_vec.size() ; ++i) {
               mxArray * str = mxCreateString(node_samplers_vec[i].c_str());
                 mxSetCell(samplers, i, str);
         }
         mxSetFieldByNumber(plhs[0], 0, 1, samplers);
       }
    }
    
    /////////////////////////////////////////
    // PRINT_GRAPHVIZ FUNCTION
    /////////////////////////////////////////
    else if (name_func == "print_graphviz") {

       CheckRhs(nrhs, 2, name_func);
       Size id = GetConsoleId(consoles, prhs[1], name_func);
       Console_ptr p_console = consoles[id];
  
       CheckArgIsString(2);
       String dot_file_name = mxArrayToString(prhs[2]);

       if (VERBOSITY)
         mbiips_cout << PROMPT_STRING << "Writing dot file in: "
                     << dot_file_name << endl;

       std::ofstream ofs(dot_file_name.c_str());

       if (ofs.fail())
         throw RuntimeError(String("Failed to open file ") + dot_file_name);

       if (!p_console->PrintGraphviz(ofs))
         throw RuntimeError("Failed to print dot file.");

    }
    /////////////////////////////////////////
    // CHANGE_DATA FUNCTION
    /////////////////////////////////////////
    else if (name_func == "change_data") {

       CheckRhs(nrhs, 6, name_func);
       Size id = GetConsoleId(consoles, prhs[1], name_func);
       Console_ptr p_console = consoles[id];

       CheckArgIsCell(2);
       mxArray * str = mxGetCell(prhs[2], 0);
       CheckIsString(str);
       String name = mxArrayToString(str);

       CheckArgIsDouble(3);
       const mxArray * lower = prhs[3];

       CheckArgIsDouble(4);
       const mxArray * upper = prhs[4];
      
       IndexRange range = makeRange(lower, upper);

       CheckArgIsDouble(5);
       double * r_vec = mxGetPr(prhs[5]);
       mwSize r_vec_nb_elems = mxGetNumberOfElements(prhs[5]);
       mwSize ndims = mxGetNumberOfDimensions(prhs[5]);
       const mwSize * dims = mxGetDimensions(prhs[5]);
       MultiArray marray;

       DimArray::Ptr p_dim(new DimArray(ndims));
       std::copy(dims, dims + ndims , p_dim->begin());

       ValArray::Ptr p_val(new ValArray(r_vec_nb_elems));
       std::replace_copy( r_vec , r_vec + r_vec_nb_elems, p_val->begin(), 
                           std::numeric_limits<Scalar>::quiet_NaN(), BIIPS_REALNA);
       marray.SetPtr(p_dim, p_val);

       CheckArgIsLogical(6);
       Bool mcmc = *mxGetLogicals(prhs[6]);
       Bool ok = p_console->ChangeData(name, range, marray, mcmc, VERBOSITY);

       plhs[0] = mxCreateLogicalMatrix(1, 1);
       *mxGetLogicals(plhs[0]) =  (ok ? 1 : 0);
    }
    
    /////////////////////////////////////////
    // SAMPLE_DATA FUNCTION
    /////////////////////////////////////////
    else if (name_func == "sample_data") {

       CheckRhs(nrhs, 5, name_func);
       Size id = GetConsoleId(consoles, prhs[1], name_func);
       Console_ptr p_console = consoles[id];

       CheckArgIsString(2);
       String name = mxArrayToString(prhs[2]);

       CheckArgIsDouble(3);
       const mxArray * lower = prhs[3];

       CheckArgIsDouble(4);
       const mxArray * upper = prhs[4];
      
       IndexRange range = makeRange(lower, upper);

       CheckArgIsDouble(5);
       Size rngSeed = static_cast<Size>(*mxGetPr(prhs[5]));
       
       MultiArray data;

       Bool ok = p_console->SampleData(name, range, data, rngSeed, VERBOSITY);
       if (!ok)
         throw RuntimeError("Failed to sample data.");
    
       mwSize ndim = data.Dim().size();
       mwSize *dims = new mwSize [ndim];
       std::copy(data.Dim().begin(), data.Dim().end(), dims);
       plhs[0] = mxCreateNumericArray(ndim, dims, mxDOUBLE_CLASS , mxREAL);
       delete [] dims;

       std::replace_copy(data.Values().begin(), data.Values().end(), mxGetPr(plhs[0]),
                    BIIPS_REALNA, std::numeric_limits<Scalar>::quiet_NaN());

    }
    
    /////////////////////////////////////////
    // GET_LOG_PRIOR_DENSITY FUNCTION
    /////////////////////////////////////////
    else if (name_func == "get_log_prior_density") {

       CheckRhs(nrhs, 4, name_func);
       Size id = GetConsoleId(consoles, prhs[1], name_func);
       Console_ptr p_console = consoles[id];
  
       CheckArgIsString(2);
       String name = mxArrayToString(prhs[2]);

       CheckArgIsDouble(3);
       const mxArray * lower = prhs[3];

       CheckArgIsDouble(4);
       const mxArray * upper = prhs[4];
      
       IndexRange range = makeRange(lower, upper);
       Scalar prior;

       if(!p_console->GetLogPriorDensity(prior, name, range))
         throw RuntimeError("Failed to get prior density.");

       if (prior == BIIPS_REALNA)
         prior = std::numeric_limits<Scalar>::quiet_NaN();
       plhs[0] = mxCreateDoubleMatrix(1, 1, mxREAL);
       *mxGetPr(plhs[0]) = prior;

    }
    
    /////////////////////////////////////////
    // IS_SMC_SAMPLER_AT_END FUNCTION
    /////////////////////////////////////////
    else if (name_func == "is_smc_sampler_at_end") {

       CheckRhs(nrhs, 1, name_func);
       Size id = GetConsoleId(consoles, prhs[1], name_func);
       Console_ptr p_console = consoles[id];

       plhs[0] = mxCreateLogicalMatrix(1, 1);
       *mxGetLogicals(plhs[0]) =  (p_console->ForwardSamplerAtEnd() ? 1 : 0);

    }
    
    /////////////////////////////////////////
    // MESSAGE FUNCTION
    /////////////////////////////////////////
    else if (name_func == "message") {

       CheckRhs(nrhs, 1, name_func);
       CheckArgIsString(1);
       String mess = mxArrayToString(prhs[1]);
       mbiips_cout << PROMPT_STRING << mess << endl;
    }
    
    /////////////////////////////////////////
    // SET_LOG_NORM_CONST FUNCTION
    /////////////////////////////////////////
    else if (name_func == "set_log_norm_const") {

       CheckRhs(nrhs, 2, name_func);
       Size id = GetConsoleId(consoles, prhs[1], name_func);
       Console_ptr p_console = consoles[id];
       
       CheckArgIsDouble(2);
       Scalar logNormConst = static_cast<Scalar>(*mxGetPr(prhs[2]));

       p_console->SetLogNormConst(logNormConst);
    
    }
    
    /////////////////////////////////////////
    // MAKE_PROGRESS_BAR FUNCTION
    /////////////////////////////////////////
    else if(name_func == "make_progress_bar") {
   
       CheckRhs(nrhs, 3, name_func);
       
       CheckArgIsDouble(1);
       unsigned long expected_count = static_cast<unsigned long>(*mxGetPr(prhs[1]));

       CheckArgIsString(2);
       String symbol = mxArrayToString(prhs[2]);
       if (symbol.size() != 1)
           throw RuntimeError("Error in progress_bar: symbol argument must be one character sized.");

       CheckArgIsString(3);
       String iter_name = mxArrayToString(prhs[3]);
         

       progress.push_back(ProgressBar_ptr(new ProgressBar(expected_count, mbiips_cout, INDENT_STRING, 
                                          symbol[0], iter_name)));
       plhs[0] = mxCreateDoubleMatrix(1, 1, mxREAL);
       *mxGetPr(plhs[0]) = progress.size()-1;
    }
   
    /////////////////////////////////////////
    // CLEAR_PROGRESS_BAR FUNCTION
    /////////////////////////////////////////
    else if (name_func == "clear_progress_bar") {

       CheckRhs(nrhs, 1, name_func);
       Size id = GetProgressBarId(progress, prhs[1], name_func);
       
       progress[id].reset();
       
    }       
    
    /////////////////////////////////////////
    // ADVANCE_PROGRESS_BAR FUNCTION
    /////////////////////////////////////////
    else if (name_func == "advance_progress_bar") {

       CheckRhs(nrhs, 2, name_func);
       Size id = GetProgressBarId(progress, prhs[1], name_func);
       ProgressBar_ptr p = progress[id];
       
       CheckArgIsDouble(2);
       unsigned long count = static_cast<unsigned long>(*mxGetPr(prhs[2])); 
       
       (*p) += count; 
       
    }       
    
    /////////////////////////////////////////
    // IS_GEN_TREE_MONITORED FUNCTION
    /////////////////////////////////////////
    else if (name_func == "is_gen_tree_monitored") {

       CheckRhs(nrhs, 4, name_func);
       Size id = GetConsoleId(consoles, prhs[1], name_func);
       Console_ptr p_console = consoles[id];
        
       mwSize nbVarNames = mxGetNumberOfElements(prhs[2]);

       if ((nbVarNames != mxGetNumberOfElements(prhs[3])) || (nbVarNames != mxGetNumberOfElements(prhs[4])))
            mbiips_cerr << name_func <<  ": arguments 2, 3 and 4 must have the same number of Elements" << endl;
   
       CheckArgIsCell(2);
       CheckArgIsCell(3);
       CheckArgIsCell(4);

       plhs[0] = mxCreateLogicalMatrix(1, 1);
       for(int i = 0; i <  nbVarNames; ++i )
        {
          const mxArray * m   = mxGetCell(prhs[2], i);
          const mxArray * low = mxGetCell(prhs[3], i);
          const mxArray * up  = mxGetCell(prhs[4], i);
         
         CheckIsString(m);
         String name = mxArrayToString(m);
          
          IndexRange range = makeRange(low, up);
        
         if (!p_console->IsGenTreeMonitored(name, range)) {
               *mxGetLogicals(plhs[0]) = 0; 
               return;
           }
       } 
       *mxGetLogicals(plhs[0]) = 1; 
       
    }
    
    /////////////////////////////////////////////
    // GET_SAMPLED_GEN_TREE_PARTICLE FUNCTION
    /////////////////////////////////////////////
    else if (name_func == "get_sampled_gen_tree_particle") {

       CheckRhs(nrhs, 1, name_func);
       Size id = GetConsoleId(consoles, prhs[1], name_func);
       Console_ptr p_console = consoles[id];

       std::map<String, MultiArray> sampled_value_map; 

       if(!p_console->DumpSampledGenTreeParticle(sampled_value_map))
         throw RuntimeError("Failed to get sampled gen tree particle.");

       readDataTable<MultiArray::StorageOrderType>(sampled_value_map, &plhs[0]);
    
    }
    
    ////////////////////////////////////////////
    // SAMPLE_GEN_TREE_PARTICLE FUNCTION
    ////////////////////////////////////////////
    else if (name_func == "sample_gen_tree_particle") {

       CheckRhs(nrhs, 2, name_func);
       Size id = GetConsoleId(consoles, prhs[1], name_func);
       Console_ptr p_console = consoles[id];
       
       CheckArgIsDouble(2);
       Size smcRngSeed = static_cast<Size>(*mxGetPr(prhs[2]));

       if (!p_console->SampleGenTreeParticle(smcRngSeed))
         throw RuntimeError("Failed to sample gen tree particle.");
    
    }
    
    ////////////////////////////////////////////
    // SET_SAMPLED_GEN_TREE_PARTICLE FUNCTION
    ////////////////////////////////////////////
    else if (name_func == "set_sampled_gen_tree_particle") {

       CheckRhs(nrhs, 2, name_func);
       Size id = GetConsoleId(consoles, prhs[1], name_func);
       Console_ptr p_console = consoles[id];
       
       CheckArgIsStruct(2);

       std::map<String, MultiArray> sampled_value_map = writeDataTable<MultiArray::StorageOrderType>(prhs[2]);

       if(!p_console->SetSampledGenTreeParticle(sampled_value_map))
         throw RuntimeError("Failed to set sampled gen tree particle.");
    
    }
    
    /////////////////////////////////////////
    // WEIGHTED_MEAN FUNCTION
    /////////////////////////////////////////
    else if (name_func == "weighted_quantiles") {

       CheckRhs(nrhs, 3, name_func);
       
       const mxArray * values  = prhs[1];
       const mxArray * weights = prhs[2];
       const mxArray * probas  = prhs[3];
       
       
       CheckArgIsDouble(1);
       CheckArgIsDouble(2);
       CheckArgIsDouble(3);


       double * values_vec = mxGetPr(values);
       double * weights_vec = mxGetPr(weights);
       double * probas_vec = mxGetPr(probas);

       int values_size = mxGetNumberOfElements(values);
       int weights_size = mxGetNumberOfElements(weights);
       int probas_size = mxGetNumberOfElements(probas);

       if (values_size != weights_size)
         throw LogicError("values and weights must have same length.");

       QuantileAccumulator accu(mxGetPr(probas), mxGetPr(probas) + probas_size);
       accu.Init();

       for (int i = 0; i< values_size; ++i)
         accu.Push(values_vec[i], weights_vec[i]);
       
       plhs[0] = mxCreateDoubleMatrix(probas_size, 1, mxREAL);
       double * probas_out = mxGetPr(plhs[0]);
       
       for (int i = 0; i<probas_size; ++i) {
           probas_out[i] = accu.Quantile(probas_vec[i]);
       }
       
       
    }       
    
    /////////////////////////////////////////
    // CELL2STRUCT_WEAK_NAMES 
    /////////////////////////////////////////
    else if (name_func == "cell2struct_weak_names") {

       CheckRhs(nrhs, 2, name_func);
       
       mwSize nb_cell = mxGetNumberOfElements(prhs[1]);

       if ((nb_cell != mxGetNumberOfElements(prhs[2])))
            mbiips_cerr << name_func <<  ": arguments 1, 2 must have the same number of Elements" << endl;
   
       CheckArgIsCell(1);
       CheckArgIsCell(2);

       for(int i = 0; i <  nb_cell; ++i ) {
          const mxArray * m = mxGetCell(prhs[2], i);
          CheckIsString(m);
          String name = mxArrayToString(m);
       }
       
       typedef char * chaine_carac ;
       chaine_carac* field_names= new chaine_carac[nb_cell];
       for(int i = 0; i <  nb_cell; ++i ) {
          const mxArray * m = mxGetCell(prhs[2], i);
          CheckIsString(m);
          String name = mxArrayToString(m);
          field_names[i] = new char[name.size()];
          std::strcpy(field_names[i], name.c_str());
       }
  
       mwSize  dims[] = { 1 };
       plhs[0] = mxCreateStructArray(1, dims, nb_cell, const_cast<const char **>(field_names));
       for(int i = 0;  i < nb_cell; ++i) {
            mxArray * contenu = mxDuplicateArray(mxGetCell(prhs[1], i));
            mxSetFieldByNumber(plhs[0], 0, i, contenu); 
            delete [] field_names[i];
       }
       delete [] field_names;
    }     
    ////////////////////////////////////////////
    // ADD_FUNCTION FUNCTION
    ////////////////////////////////////////////
    else if (name_func == "add_function") {

       CheckRhs(nrhs, 6, name_func);
       CheckArgIsString(1);
       CheckArgIsDouble(2);
       CheckArgIsString(3);
       CheckArgIsString(4);
       CheckArgIsString(5);
       CheckArgIsString(6);
   
       String arg1 = mxArrayToString(prhs[1]);
       Size arg2 = static_cast<Size>(*mxGetPr(prhs[2]));
       String arg3 = mxArrayToString(prhs[3]);
       String arg4 = mxArrayToString(prhs[4]);
       String arg5 = mxArrayToString(prhs[5]);
       String arg6 = mxArrayToString(prhs[6]);

       
       if (!Compiler::FuncTab().Insert(Function::Ptr(new MatlabFunction(arg1,
                                                     arg2,
                                                     arg3,
                                                     arg4,
                                                     arg5,
                                                     arg6)))) {
             mexErrMsgTxt("add_function: can not insert the function (may already exist?)");
       }						     

    
    }
    else {
       mexErrMsgTxt("bad name of function\n");

    }
    /* set C-style string output_buf to MATLAB mexFunction output*/
    mxFree(input_buf);
    return;

}

