//                                               -*- C++ -*-
/*! \file Sum.cpp
* \brief
*
* $LastChangedBy$
* $LastChangedDate$
* $LastChangedRevision$
* $Id$
*/

#include "functions/Sum.hpp"


namespace Biips
{

  Bool Sum::checkParamDims(const Types<DimArray::Ptr>::Array & paramDims) const
  {
    return true;
  }

  MultiArray Sum::eval(const MultiArray::Array & paramValues) const
  {
    const MultiArray & val = paramValues[0];

    MultiArray ans(DimArray(1,1));
    ans.ScalarView() = val.Values().Sum();

    return ans;
  }

  Bool Sum::IsDiscreteValued(const Flags & mask) const
  {
    return mask[0];
  }
}
