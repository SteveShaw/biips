#ifndef BIIPS_HMMMNORMALLINEAR4D_HPP_
#define BIIPS_HMMMNORMALLINEAR4D_HPP_

#include "HmmMNormalLinear.hpp"

namespace Biips
{

  class HmmMNormalLinear4D : public HmmMNormalLinear
  {
  protected:
    static const String NAME_;

  public:
    typedef HmmMNormalLinear BaseType;

    HmmMNormalLinear4D(int argc, char** argv, Size verbose = 1, Size showMode = 0, Bool precFlag = false, std::ostream & os = std::cout);

    virtual void PrintIntro();

//    virtual void InputModelParam(std::istream & is = std::cin);
  };

}

#endif /* BIIPS_HMMMNORMALLINEAR4D_HPP_ */
