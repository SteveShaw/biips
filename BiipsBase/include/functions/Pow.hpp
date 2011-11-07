//                                               -*- C++ -*-
/*! \file Pow.hpp
 * \brief 
 * 
 * $LastChangedBy$
 * $LastChangedDate$
 * $LastChangedRevision$
 * $Id$
 */

#ifndef BIIPS_POW_HPP_
#define BIIPS_POW_HPP_

#include "functions/ScalarFunction.hpp"

namespace Biips
{
  struct PowScalar : public std::binary_function<Scalar, Scalar, Scalar>
  {
    Scalar operator() (Scalar base, Scalar exponent) const
    {
      return std::pow(base, exponent);
    }
  };


  class Pow : public BinaryScalarFunction<PowScalar>
  {
  public:
    typedef Pow SelfType;
    typedef BinaryScalarFunction<PowScalar> BaseType;

  protected:
    Pow() : BaseType("pow") {};

    virtual Bool checkParamValues(const MultiArray::Array & paramValues) const;

  public:
    static Function::Ptr Instance() { static Function::Ptr p_instance(new SelfType()); return p_instance; };
  };


  class PowInfix : public BinaryScalarFunction<PowScalar>
  {
  public:
    typedef PowInfix SelfType;
    typedef BinaryScalarFunction<PowScalar> BaseType;

  protected:
    PowInfix() : BaseType("^") {};

    virtual Bool checkParamValues(const MultiArray::Array & paramValues) const;

  public:
    virtual Bool IsInfix() const { return true; }

    static Function::Ptr Instance() { static Function::Ptr p_instance(new SelfType()); return p_instance; };
  };
}

#endif /* BIIPS_POW_HPP_ */
