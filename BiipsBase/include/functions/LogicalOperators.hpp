//                                               -*- C++ -*-
/*! \file LogicalOperators.hpp
 * \brief 
 * 
 * $LastChangedBy$
 * $LastChangedDate$
 * $LastChangedRevision$
 * $Id$
 */

#ifndef BIIPS_LOGICALOPERATORS_HPP_
#define BIIPS_LOGICALOPERATORS_HPP_

#include "functions/ScalarFunction.hpp"

namespace Biips
{

  class And : public BinaryScalarFunction<std::logical_and<Scalar> >
  {
  public:
    typedef And SelfType;
    typedef BinaryScalarFunction<std::logical_and<Scalar> > BaseType;

  protected:
    And() : BaseType("&&") {};

    virtual Bool checkParamValues(const MultiArray::Array & paramValues) const { return true; }

  public:
    virtual Bool IsInfix() const { return true; }
    virtual Bool IsDiscreteValued(const Flags & mask) const { return true; }

    static Function::Ptr Instance() { static Function::Ptr p_instance(new SelfType()); return p_instance; }
  };


  class Or : public BinaryScalarFunction<std::logical_or<Scalar> >
  {
  public:
    typedef Or SelfType;
    typedef BinaryScalarFunction<std::logical_or<Scalar> > BaseType;

  protected:
    Or() : BaseType("||") {};

    virtual Bool checkParamValues(const MultiArray::Array & paramValues) const { return true; }

  public:
    virtual Bool IsInfix() const { return true; }
    virtual Bool IsDiscreteValued(const Flags & mask) const { return true; }

    static Function::Ptr Instance() { static Function::Ptr p_instance(new SelfType()); return p_instance; }
  };


  class Not : public UnaryScalarFunction<std::logical_not<Scalar> >
  {
  public:
    typedef Not SelfType;
    typedef UnaryScalarFunction<std::logical_not<Scalar> > BaseType;

  protected:
    Not() : BaseType("!") {};

    virtual Bool checkParamValues(const MultiArray::Array & paramValues) const { return true; }

  public:
    virtual Bool IsPrefix() const { return true; }
    virtual Bool IsDiscreteValued(const Flags & mask) const { return true; }

    static Function::Ptr Instance() { static Function::Ptr p_instance(new SelfType()); return p_instance; }
  };

}

#endif /* BIIPS_LOGICALOPERATORS_HPP_ */
