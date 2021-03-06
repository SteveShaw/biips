#ifndef BIIPS_HMMNORMALLINEAR_HPP_
#define BIIPS_HMMNORMALLINEAR_HPP_

#include "ModelTest.hpp"

namespace Biips
{

  class HmmNormalLinear: public ModelTest
  {
  protected:
    Bool precFlag_;

    static const String NAME_;

    void initAccumulators(Size nParticles, Size numBins, std::map<String,
        MultiArray::Array> & statsValuesMap);

    virtual void initFilterAccumulators(Size nParticles, Size numBins);
    virtual void initSmoothAccumulators(Size nParticles, Size numBins);

    void accumulate(Size t,
                    std::map<String, MultiArray::Array> & statsValuesMap,
                    const String & title);

    virtual void filterAccumulate(Size iter);
    virtual void smoothAccumulate(Size iter);

  public:
    typedef ModelTest BaseType;

    HmmNormalLinear(int argc,
                    char** argv,
                    Size verbose = 1,
                    Size showMode = 0,
                    Bool precFlag = false,
                    std::ostream & os = std::cout);

    virtual void PrintIntro();

    //    virtual void InputModelParam(std::istream & is = std::cin);

    virtual void RunBench();

    virtual void BuildModelGraph();

  };

}

#endif /* BIIPS_HMMNORMALLINEAR_HPP_ */
