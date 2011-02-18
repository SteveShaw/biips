//                                               -*- C++ -*-
/*! \file Multiply.cpp
 * \brief
 *
 * \author  $LastChangedBy$
 * \date    $LastChangedDate$
 * \version $LastChangedRevision$
 * Id:      $Id$
 */


#include "functions/Multiply.hpp"

namespace Biips
{
    DataType Multiply::Eval(const DataType::Array & paramValues) const
    {
      // TODO check paramValues
      const DataType & left = paramValues[0];
      const DataType & right = paramValues[1];

      DataType ans;
      if ( left.IsScalar() )
      {
        ans = DataType(right.DimPtr(), left.ScalarView() * right.Values());
      }
      else if ( right.IsScalar() )
        ans = DataType(left.DimPtr(), left.Values() * right.ScalarView());
      else
        ans = DataType(left.DimPtr(), left.Values() * right.Values());
      return ans;
    }
}
