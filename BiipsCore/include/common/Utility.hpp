//                                               -*- C++ -*-
/*! \file Utility.hpp
 * \brief
 *
 * \author  $LastChangedBy$
 * \date    $LastChangedDate$
 * \version $LastChangedRevision$
 * Id:      $Id$
 */

#ifndef BIIPS_UTILITY_HPP_
#define BIIPS_UTILITY_HPP_

#include <utility>

#include "Types.hpp"

namespace Biips
{

  template <typename Container>
  typename Types<typename Container::iterator>::Pair iterRange(Container & cont)
  {
    return std::make_pair(cont.begin(), cont.end());
  }


  template <typename Container>
  typename Types<typename Container::const_iterator>::Pair iterRange(const Container & cont)
  {
    return std::make_pair(cont.begin(), cont.end());
  }


  template<typename T>
  String print(const T & val)
  {
    std::ostringstream ostr;
    ostr << val;
    return ostr.str();
  }

}

#endif /* BIIPS_UTILITY_HPP_ */
