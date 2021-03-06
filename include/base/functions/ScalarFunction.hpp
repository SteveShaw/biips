#ifndef BIIPS_SCALARFUNCTION_HPP_
#define BIIPS_SCALARFUNCTION_HPP_

#include "function/Function.hpp"

namespace Biips
{

  template<typename UnaryOperator>
  class UnaryScalarFunction: public Function
  {
  public:
    typedef Function BaseType;
    typedef UnaryScalarFunction SelfType;
    typedef typename Types<SelfType>::Ptr Ptr;

  protected:
    UnaryScalarFunction(const String & name) :
      BaseType(name, 1)
    {
    }

    virtual Bool checkParamDims(const Types<DimArray::Ptr>::Array & paramDims) const
    {
      return true;
    }
    virtual DimArray dim(const Types<DimArray::Ptr>::Array & paramDims) const;
    virtual void eval(ValArray & values, const NumArray::Array & paramValues) const;

  public:
    virtual Bool CheckParamValues(const NumArray::Array & paramValues) const = 0;
    virtual ~UnaryScalarFunction()
    {
    }
  };

  template<typename BinaryOperator>
  class BinaryScalarFunction: public Function
  {
  public:
    typedef Function BaseType;
    typedef BinaryScalarFunction SelfType;
    typedef typename Types<SelfType>::Ptr Ptr;

  protected:
    BinaryScalarFunction(const String & name) :
      BaseType(name, 2)
    {
    }

    virtual Bool
    checkParamDims(const Types<DimArray::Ptr>::Array & paramDims) const;
    virtual DimArray dim(const Types<DimArray::Ptr>::Array & paramDims) const;
    virtual void eval(ValArray & values, const NumArray::Array & paramValues) const;

  public:
    virtual Bool CheckParamValues(const NumArray::Array & paramValues) const = 0;
    virtual ~BinaryScalarFunction()
    {
    }
  };

  template<typename BinaryOperator>
  class VariableScalarFunction: public Function
  {
  public:
    typedef Function BaseType;
    typedef VariableScalarFunction SelfType;
    typedef typename Types<SelfType>::Ptr Ptr;

  protected:
    VariableScalarFunction(const String & name) :
      BaseType(name, 0)
    {
    }

    virtual Bool
    checkParamDims(const Types<DimArray::Ptr>::Array & paramDims) const;
    virtual DimArray dim(const Types<DimArray::Ptr>::Array & paramDims) const;
    virtual void eval(ValArray & values, const NumArray::Array & paramValues) const;

  public:
    virtual Bool CheckParamValues(const NumArray::Array & paramValues) const = 0;
    virtual ~VariableScalarFunction()
    {
    }
  };

  template<typename UnaryOperator>
  void UnaryScalarFunction<UnaryOperator>::eval(ValArray & values, const NumArray::Array & paramValues) const
  {
    const NumArray & val = paramValues[0];

    static UnaryOperator op;

    std::transform(val.Values().begin(), val.Values().end(), values.begin(), op);
  }

  template<typename UnaryOperator>
  DimArray UnaryScalarFunction<UnaryOperator>::dim(const Types<DimArray::Ptr>::Array & paramDims) const
  {
    return *paramDims[0];
  }

  template<typename BinaryOperator>
  Bool BinaryScalarFunction<BinaryOperator>::checkParamDims(const Types<
      DimArray::Ptr>::Array & paramDims) const
  {
    if (paramDims[0]->IsScalar())
      return true;
    else if (paramDims[1]->IsScalar())
      return true;
    else
      return paramDims[0]->Drop() == paramDims[1]->Drop();
  }

  template<typename BinaryOperator>
  DimArray BinaryScalarFunction<BinaryOperator>::dim(const Types<DimArray::Ptr>::Array & paramDims) const
  {
    if (paramDims[0]->IsScalar())
      return *paramDims[1];
    else
      return *paramDims[0];
  }

  template<typename BinaryOperator>
  void BinaryScalarFunction<BinaryOperator>::eval(ValArray & values, const NumArray::Array & paramValues) const
  {
    const NumArray & left = paramValues[0];
    const NumArray & right = paramValues[1];

    static BinaryOperator op;

    if (left.IsScalar())
    {
      std::transform(right.Values().begin(),
                     right.Values().end(),
                     values.begin(),
                     std::bind1st(op, left.ScalarView()));
    }
    else if (right.IsScalar())
    {
      std::transform(left.Values().begin(),
                     left.Values().end(),
                     values.begin(),
                     std::bind2nd(op, right.ScalarView()));
    }
    else
    {
      std::transform(left.Values().begin(),
                     left.Values().end(),
                     right.Values().begin(),
                     values.begin(),
                     op);
    }
  }

  template<typename BinaryOperator>
  Bool VariableScalarFunction<BinaryOperator>::checkParamDims(const Types<
      DimArray::Ptr>::Array & paramDims) const
  {
    Bool ans = true;
    DimArray::Ptr p_ref_dim;
    for (Size i = 0; i < paramDims.size() && ans; ++i)
    {
      if (paramDims[i]->IsScalar())
        continue;
      else if (!p_ref_dim)
        p_ref_dim = paramDims[i];
      else
        ans = paramDims[i]->Drop() == p_ref_dim->Drop();
    }
    return ans;
  }

  template<typename BinaryOperator>
  DimArray VariableScalarFunction<BinaryOperator>::dim(const Types<
      DimArray::Ptr>::Array & paramDims) const
  {
    DimArray::Ptr p_ref_dim = paramDims[0];
    if (p_ref_dim->IsScalar())
    {
      for (Size i = 1; i < paramDims.size(); ++i)
      {
        if (paramDims[i]->IsScalar())
          continue;
        else
        {
          p_ref_dim = paramDims[i];
          break;
        }
      }
    }
    return p_ref_dim->Drop();
  }

  template<typename BinaryOperator>
  void VariableScalarFunction<BinaryOperator>::eval(ValArray & values,
                                                    const NumArray::Array & paramValues) const
  {
    static BinaryOperator op;

    if (paramValues[0].IsScalar())
      std::fill(values.begin(), values.end(), paramValues[0].ScalarView());
    else
      values.assign(paramValues[0].Values().begin(),
                    paramValues[0].Values().end());

    for (Size i = 1; i < paramValues.size(); ++i)
    {
      const NumArray & right = paramValues[i];
      if (right.IsScalar())
      {
        std::transform(values.begin(),
                       values.end(),
                       values.begin(),
                       std::bind2nd(op, right.ScalarView()));
      }
      else
      {
        std::transform(values.begin(),
                       values.end(),
                       right.Values().begin(),
                       values.begin(),
                       op);
      }
    }
  }
}

#endif /* BIIPS_SCALARFUNCTION_HPP_ */
