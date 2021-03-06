/*! \file Console.hpp
 * COPY: Adapted from JAGS Console class
 */

#ifndef BIIPS_CONSOLE_HPP_
#define BIIPS_CONSOLE_HPP_

#include "common/Types.hpp"
#include <map>
#include "common/IndexRange.hpp"
#include "common/MultiArray.hpp"
#include "common/Histogram.hpp"
#include "model/NodeArrayMonitor.hpp"

class ParseTree;

namespace Biips
{
  extern String PROMPT_STRING;
  extern Size INDENT_SIZE;
  extern const char INDENT_CHAR;
  extern String INDENT_STRING;

  class BUGSModel;

  class Console
  {
  protected:
    std::ostream & out_;
    std::ostream & err_;
    BUGSModel * pModel_;
    ParseTree * pData_;
    ParseTree * pRelations_;
    Types<ParseTree*>::Array * pVariables_;
    Types<String>::Array nodeArrayNames_;
    Bool lockBackward_;

    void clearParseTrees();

  public:
    /*!
     * Constructor
     *
     * @param out Output stream to which information messages will be printed.
     *
     * @param err Output stream to which error messages will be printed.
     *
     */
    Console(std::ostream & out, std::ostream & err);

    ~Console();

    /*!
     * Checks syntactic correctness of model
     *
     * @param file containing BUGS-language description of the model
     *
     * @return true on success or false on error.
     */
    Bool CheckModel(const String & modelFileName, Size verbosity = 1);

    Bool GraphSize(Size & s);

    // FIXME add module manager and a load module by name function
    Bool LoadBaseModule(Size verbosity = 1);

    /*!
     * Compiles the model.
     *
     * @param data Map relating the names of the observed variables to
     * their values.
     *
     * @param nchain Number of chains in the model.
     *
     * @param gendata Boolean flag indicating whether the data generation
     * sub-model should be run, if there is one.
     *
     * @return true on success or false on error.
     */
    Bool Compile(std::map<String, MultiArray> & dataMap,
                 Bool genData,
                 Size dataRngSeed,
                 Size verbosity = 1, Bool clone = false);

    Bool PrintGraphviz(std::ostream & os);
    /*!
     * Returns a vector of variable names used by the model. This vector
     * excludes any counters used by the model within a for loop.
     */
    Types<String>::Array const & VariableNames() const
    {
      return nodeArrayNames_;
    }

    /*! Clears the model */
    void ClearModel(Size verbosity = 1);

    Bool SetDefaultFilterMonitors();

    Bool SetFilterMonitor(const String & name, const IndexRange & range =
                              NULL_RANGE);
    Bool SetGenTreeSmoothMonitor(const String & name, const IndexRange & range =
                                  NULL_RANGE);
    Bool SetBackwardSmoothMonitor(const String & name, const IndexRange & range =
                              NULL_RANGE);

    Bool IsFilterMonitored(const String & name, const IndexRange & range =
                               NULL_RANGE, Bool check_released = true);
    Bool IsGenTreeSmoothMonitored(const String & name, const IndexRange & range =
                                   NULL_RANGE, Bool check_released = true);
    Bool IsBackwardSmoothMonitored(const String & name, const IndexRange & range =
                               NULL_RANGE, Bool check_released = true);

    Bool ClearFilterMonitors(Bool release_only = false);
    Bool ClearGenTreeSmoothMonitors(Bool release_only = false);
    Bool ClearBackwardSmoothMonitors(Bool release_only = false);

    /*!
     * @short Builds the SMC sampler.
     *
     * The samplers are chosen for the unobserved
     * stochastic nodes based on the list of sampler factories.
     *
     * @returns true on success, false on failure
     */
    Bool BuildSampler(Bool prior, Size verbosity = 1);
    Bool SamplerBuilt();

    Bool RunForwardSampler(Size nParticles,
                           Size smcRngSeed,
                           const String & rsType,
                           Scalar essThreshold,
                           Size verbosity = 1,
                           Bool progressBar = true);

    Bool ForwardSamplerAtEnd();

    Bool GetLogNormConst(Scalar & logNormConst);

    Bool SampleGenTreeSmoothParticle(Size rngSeed, std::map<String, MultiArray> & sampledValueMap);

    Bool RunBackwardSmoother(Size verbosity = 1, Bool progressBar = true);

    Bool ExtractFilterStat(const String & name,
                           StatTag statFeature,
                           std::map<IndexRange, MultiArray> & statMap);
    Bool ExtractGenTreeSmoothStat(const String & name,
                               StatTag statFeature,
                               std::map<IndexRange, MultiArray> & statMap);
    Bool ExtractBackwardSmoothStat(const String & name,
                           StatTag statFeature,
                           std::map<IndexRange, MultiArray> & statMap);

    Bool ExtractFilterPdf(const String & name,
                          std::map<IndexRange, Histogram> & pdfMap,
                          Size numBins = 40,
                          Scalar cacheFraction = 0.25);
    Bool ExtractGenTreeSmoothPdf(const String & name,
                              std::map<IndexRange, Histogram> & pdfMap,
                              Size numBins = 40,
                              Scalar cacheFraction = 0.25);
    Bool ExtractBackwardSmoothPdf(const String & name,
                          std::map<IndexRange, Histogram> & pdfMap,
                          Size numBins = 40,
                          Scalar cacheFraction = 0.25);

    Bool DumpData(std::map<String, MultiArray> & dataMap);
    Bool
    ChangeData(const String & variable,
               const IndexRange & range,
               const MultiArray & data,
               Bool mcmc = true,
               Size verbosity = 1);
    Bool
    SampleData(const String & variable,
               const IndexRange & range,
               MultiArray & data,
               Size rngSeed,
               Size verbosity = 1);

    Bool RemoveData(const String & variable,
                    const IndexRange & range,
                    Size verbosity = 1);
    Bool GetLogPriorDensity(Scalar & prior,
                            const String & variable,
                            const IndexRange & range = NULL_RANGE);
    Bool GetFixedSupport(ValArray & lower, ValArray & upper,
                         const String & variable,
                         const IndexRange & range = NULL_RANGE);

    Bool DumpFilterMonitors(std::map<String, NodeArrayMonitor> & particlesMap);
    Bool
    DumpGenTreeSmoothMonitors(std::map<String, NodeArrayMonitor> & particlesMap);
    Bool DumpBackwardSmoothMonitors(std::map<String, NodeArrayMonitor> & particlesMap);

    Bool DumpNodeIds(Types<NodeId>::Array & nodeIds);
    Bool DumpNodeNames(Types<String>::Array & nodeNames);
    Bool DumpNodeTypes(Types<NodeType>::Array & nodeTypes);
    Bool DumpNodeObserved(Flags & nodeObserved);
    Bool DumpNodeDiscrete(Flags & nodeDiscrete);
    Bool DumpNodeIterations(Types<Size>::Array & nodeIterations);
    Bool DumpNodeSamplers(Types<String>::Array & nodeSamplers);
  };
}

#endif /* BIIPS_CONSOLE_HPP_ */
