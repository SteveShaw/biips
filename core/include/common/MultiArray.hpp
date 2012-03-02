//                                               -*- C++ -*-
/*! \file MultiArray.hpp
 * \brief A n-dimensional data object class
 *
 * \author  $LastChangedBy$
 * \date    $LastChangedDate$
 * \version $LastChangedRevision$
 * Id:      $Id$
 */

#ifndef BIIPS_MULTIARRAY_HPP_
#define BIIPS_MULTIARRAY_HPP_

#include "common/Types.hpp"
#include "common/DimArray.hpp"
#include "common/ValArray.hpp"
#include "common/Error.hpp"

namespace Biips
{
  class Vector;
  class Matrix;

  class VectorRef;
  class MatrixRef;

  // -----------------------------------------------------------------------------
  // NumArray
  // -----------------------------------------------------------------------------

  class NumArrayArray;
  class NumArrayPair;

  class NumArray
  {
  public:
    //! The Values storage Type is ValArray
    typedef ValArray StorageType;
    typedef StorageType::value_type ValueType;
    typedef StorageOrder StorageOrderType;

    typedef NumArray SelfType;
    //! An array of MultiArray
    typedef NumArrayArray Array;
    //! A pair of MultiArray
    typedef NumArrayPair Pair;

  protected:
    //! pointer of the dimensions array of the data
    DimArray * pDim_;
    //! pointer of the values array of the data
    StorageType * pValues_;

    void checkDimPtr() const
    {
      if (!pDim_)
        throw LogicError("Can not access dimension of NumArray: null pointer.");
    }
    void checkValuesPtr() const
    {
      if (!pValues_)
        throw LogicError("Can not access values of NumArray: null pointer.");
    }

  public:
    NumArray() :
      pDim_(NULL), pValues_(NULL)
    {
    }
    explicit NumArray(DimArray * pDim, StorageType * pVal) :
      pDim_(pDim), pValues_(pVal)
    {
    }

    //! Number of dimensions accessor
    /*!
     * @return the size of the DimArray
     */
    Size NDim() const
    {
      checkDimPtr();
      return pDim_->size();
    }

    //! Length of the DatType
    /*!
     * Computes the product of the sizes of each dimension
     * @return the number of elements of the NumArray
     */
    Size Length() const
    {
      checkDimPtr();
      return pDim_->Length();
    }

    /*!
     * Indicates whether the NumArray corresponds to a scalar object,
     * i.e. containing only one element.
     */
    Bool IsScalar() const
    {
      checkDimPtr();
      return pDim_->IsScalar();
    }
    /*!
     * Indicates whether the NumArray corresponds to a vector object,
     * i.e. only one dimension.
     */
    Bool IsVector() const
    {
      checkDimPtr();
      return pDim_->IsVector();
    }
    /*!
     * Indicates whether the NumArray corresponds to a matrix object,
     * i.e. exactly two dimensions.
     */
    Bool IsMatrix() const
    {
      checkDimPtr();
      return pDim_->IsMatrix();
    }
    /*!
     * Indicates whether the NumArray corresponds to a squared matrix.
     */
    Bool IsSquared() const
    {
      checkDimPtr();
      return pDim_->IsSquared();
    }

    //! DimArray accessor.
    /*!
     * @return the dimension array
     */
    const DimArray & Dim() const
    {
      checkDimPtr();
      return *pDim_;
    }

    //! DimArray accessor.
    /*!
     * @return a reference to the dimension array
     */
    DimArray & Dim()
    {
      checkDimPtr();
      return *pDim_;
    }

    //! DimArray shared pointer accessor.
    /*!
     * @return the dimension array shared pointer
     */
    const DimArray * DimPtr() const
    {
      return pDim_;
    }

    DimArray * DimPtr()
    {
      return pDim_;
    }

    //! ValArray accessor.
    /*!
     * @return the values array
     */
    const StorageType & Values() const
    {
      checkValuesPtr();
      return *pValues_;
    }
    //! ValArray accessor.
    /*!
     * @return a reference to the values array
     */
    StorageType & Values()
    {
      checkValuesPtr();
      return *pValues_;
    }
    //! ValArray accessor.
    /*!
     * @return the values array shared pointer
     */
    const StorageType * ValuesPtr() const
    {
      return pValues_;
    }
    //! ValArray accessor.
    /*!
     * @return the values array shared pointer
     */
    StorageType * ValuesPtr()
    {
      return pValues_;
    }

    SelfType & SetPtr(DimArray * pDim)
    {
      pDim_ = pDim;
      return *this;
    }
    SelfType & SetPtr(StorageType * pVal)
    {
      pValues_ = pVal;
      return *this;
    }
    SelfType & SetPtr(DimArray * pDim, StorageType * pVal)
    {
      pDim_ = pDim;
      pValues_ = pVal;
      return *this;
    }

    /*!
     * Most of the NumArray objects will contain one scalar value.
     * This method gives a convenient Scalar handle of the ValArray.
     * @return The first value of the ValArray if size is 1
     */
    Scalar ScalarView() const
    {
      return (*pValues_)[0];
    } // TODO throw exception
    /*!
     * Most of the NumArray objects will contain one scalar value.
     * This method gives a convenient Scalar handle of the ValArray.
     * @return  A reference to the first value of the ValArray if size is 1
     */
    Scalar & ScalarView()
    {
      return (*pValues_)[0];
    } // TODO throw exception

    Bool IsNULL() const
    {
      return !pValues_;
    }
  };

  // -----------------------------------------------------------------------------
  // NULL_NUMARRAY
  // -----------------------------------------------------------------------------

  const NumArray NULL_NUMARRAY = NumArray();

  // -----------------------------------------------------------------------------
  // NumArrayArray
  // -----------------------------------------------------------------------------

  class NumArrayArray: public std::vector<NumArray>
  {
  public:
    typedef NumArrayArray SelfType;
    typedef std::vector<NumArray> BaseType;

    NumArrayArray()
    {
    }
    NumArrayArray(Size s) :
      BaseType(s)
    {
    }
  };

  // -----------------------------------------------------------------------------
  // NumArrayPair
  // -----------------------------------------------------------------------------

  class NumArrayPair: public std::pair<NumArray, NumArray>
  {
  public:
    typedef NumArrayPair SelfType;
    typedef std::pair<NumArray, NumArray> BaseType;

    NumArrayPair()
    {
    }
  };

  const NumArrayPair NULL_NUMARRAYPAIR;

  Bool allMissing(const NumArray & marray);
  Bool anyMissing(const NumArray & marray);

  // -----------------------------------------------------------------------------
  // NumArray Types
  // -----------------------------------------------------------------------------

  template<>
  struct Types<NumArray>
  {
    typedef NumArray SelfType; //!< The template type itself

    //! Smart pointer type defined with a boost::shared_ptr<>
    typedef boost::shared_ptr<SelfType> Ptr;

    typedef NumArrayArray Array; //!< Array type
    typedef Array::iterator Iterator; //!< Iterator type of the Array type
    typedef Array::reverse_iterator ReverseIterator; //!< Reverse iterator type of the Array type
    typedef Array::const_iterator ConstIterator; //!< Const iterator type of the Array type
    typedef Array::const_reverse_iterator ConstReverseIterator; //!< Const reverse iterator type of the Array type

    typedef std::vector<Ptr> PtrArray; //!< Array of pointers defined with a std::vector<boost::shared_ptr<> >

    typedef NumArrayPair Pair;
    typedef std::pair<Iterator, Iterator> IteratorPair;
    typedef std::pair<ConstIterator, ConstIterator> ConstIteratorPair; //!< Pair of ConstIterators type, used to define a range
  };

  // -----------------------------------------------------------------------------
  // MultiArray
  // -----------------------------------------------------------------------------

  class MultiArrayArray;
  class MultiArrayPair;

  //! A n-dimensional data object class
  /*!
   * MultiArray represents a wholly defined n-dimensional data object,
   * aggregating its dimension and its values.
   * Those two members are aggregated with shared pointers, so MultiArray
   * objects are light weight objects providing a convenient interface.
   */
  class MultiArray
  {
  public:
    //! The Values storage Type is ValArray
    typedef ValArray StorageType;
    typedef StorageType::value_type ValueType;
    typedef StorageOrder StorageOrderType;

    typedef MultiArray SelfType;
    //! An array of MultiArray
    typedef MultiArrayArray Array;
    //! A pair of MultiArray
    typedef MultiArrayPair Pair;

  protected:
    //! Shared pointer of the dimensions array of the data
    Types<DimArray>::Ptr pDim_;
    //! Shared pointer of the values array of the data
    Types<StorageType>::Ptr pValues_;

    void checkDimPtr() const
    {
      if (!pDim_)
        throw LogicError("Can not access dimension of MultiArray: null pointer.");
    }
    void checkValuesPtr() const
    {
      if (!pValues_)
        throw LogicError("Can not access values of MultiArray: null pointer.");
    }

  public:
    MultiArray()
    {
    }
    /*!
     * Creates a MultiArray with DimArray pointed by pDim
     * and ValArray pointed by pValue.
     * @param pDim dimension array shared pointer
     * @param pValue values array shared pointer
     */
    MultiArray(const DimArray::Ptr & pDim,
               const Types<StorageType>::Ptr & pValue) :
      pDim_(pDim), pValues_(pValue)
    {
    } // TODO check dims
    Size NDim() const
    {
      checkDimPtr();
      return pDim_->size();
    }

    //! Length of the DatType
    /*!
     * Computes the product of the sizes of each dimension
     * @return the number of elements of the MultiArray
     */
    Size Length() const
    {
      checkDimPtr();
      return pDim_->Length();
    }

    /*!
     * Indicates whether the MultiArray corresponds to a scalar object,
     * i.e. containing only one element.
     */
    Bool IsScalar() const
    {
      checkDimPtr();
      return pDim_->IsScalar();
    }
    /*!
     * Indicates whether the MultiArray corresponds to a vector object,
     * i.e. only one dimension.
     */
    Bool IsVector() const
    {
      checkDimPtr();
      return pDim_->IsVector();
    }
    /*!
     * Indicates whether the MultiArray corresponds to a matrix object,
     * i.e. exactly two dimensions.
     */
    Bool IsMatrix() const
    {
      checkDimPtr();
      return pDim_->IsMatrix();
    }
    /*!
     * Indicates whether the MultiArray corresponds to a squared matrix.
     */
    Bool IsSquared() const
    {
      checkDimPtr();
      return pDim_->IsSquared();
    }

    //! DimArray accessor.
    /*!
     * @return the dimension array
     */
    const DimArray & Dim() const
    {
      checkDimPtr();
      return *pDim_;
    }

    //! DimArray accessor.
    /*!
     * @return a reference to the dimension array
     */
    DimArray & Dim()
    {
      checkDimPtr();
      return *pDim_;
    }

    //! DimArray shared pointer accessor.
    /*!
     * @return the dimension array shared pointer
     */
    const DimArray::Ptr & DimPtr() const
    {
      return pDim_;
    }

    //! ValArray accessor.
    /*!
     * @return the values array
     */
    const StorageType & Values() const
    {
      checkValuesPtr();
      return *pValues_;
    }

    //! ValArray accessor.
    /*!
     * @return a reference to the values array
     */
    StorageType & Values()
    {
      checkValuesPtr();
      return *pValues_;
    }

    //! ValArray accessor.
    /*!
     * @return the values array shared pointer
     */
    const Types<StorageType>::Ptr & ValuesPtr() const
    {
      return pValues_;
    }

    /*!
     * Most of the MultiArray objects will contain one scalar value.
     * This method gives a convenient Scalar handle of the ValArray.
     * @return The first value of the ValArray if size is 1
     */
    Scalar ScalarView() const
    {
      return (*pValues_)[0];
    } // TODO throw exception
    /*!
     * Most of the MultiArray objects will contain one scalar value.
     * This method gives a convenient Scalar handle of the ValArray.
     * @return  A reference to the first value of the ValArray if size is 1
     */
    Scalar & ScalarView()
    {
      return (*pValues_)[0];
    } // TODO throw exception

    SelfType & SetPtr(const DimArray::Ptr & pDim)
    {
      pDim_ = pDim;
      return *this;
    }
    SelfType & SetPtr(const StorageType::Ptr & pVal)
    {
      pValues_ = pVal;
      return *this;
    }
    SelfType & SetPtr(const DimArray::Ptr pDim, const StorageType::Ptr & pVal)
    {
      pDim_ = pDim;
      pValues_ = pVal;
      return *this;
    }

    MultiArray Clone() const
    {
      DimArray::Ptr p_dim_clone(new DimArray(*pDim_));
      StorageType::Ptr p_val_clone(new StorageType(*pValues_));
      return MultiArray(p_dim_clone, p_val_clone);
    }

    Bool IsNULL() const
    {
      return !(pDim_ || pValues_);
    }
  };

  // -----------------------------------------------------------------------------
  // NULL_MULTIARRAY
  // -----------------------------------------------------------------------------

  const MultiArray NULL_MULTIARRAY = MultiArray();

  // -----------------------------------------------------------------------------
  // MultiArrayArray
  // -----------------------------------------------------------------------------

  class MultiArrayArray: public std::vector<MultiArray>
  {
  public:
    typedef MultiArrayArray SelfType;
    typedef std::vector<MultiArray> BaseType;

    MultiArrayArray()
    {
    }
    MultiArrayArray(Size s) :
      BaseType(s)
    {
    }

    MultiArrayArray Clone() const
    {
      MultiArrayArray clone(size());
      for (Size i = 0; i < size(); ++i)
        clone[i] = (*this)[i].Clone();
      return clone;
    }
  };

  // -----------------------------------------------------------------------------
  // MultiArrayPair
  // -----------------------------------------------------------------------------

  class MultiArrayPair: public std::pair<MultiArray, MultiArray>
  {
  public:
    typedef MultiArrayPair SelfType;
    typedef std::pair<MultiArray, MultiArray> BaseType;
    MultiArrayPair()
    {
    }

    MultiArrayPair Clone() const
    {
      MultiArrayPair clone;
      clone.first = first.Clone();
      clone.second = second.Clone();
      return clone;
    }
  };

  const MultiArrayPair NULL_MULTIARRAYPAIR;

  Bool allMissing(const MultiArray & marray);
  Bool anyMissing(const MultiArray & marray);

  // -----------------------------------------------------------------------------
  // MultiArray Types
  // -----------------------------------------------------------------------------

  template<>
  struct Types<MultiArray>
  {
    typedef MultiArray SelfType; //!< The template type itself

    //! Smart pointer type defined with a boost::shared_ptr<>
    typedef boost::shared_ptr<SelfType> Ptr;

    typedef MultiArrayArray Array; //!< Array type
    typedef Array::iterator Iterator; //!< Iterator type of the Array type
    typedef Array::reverse_iterator ReverseIterator; //!< Reverse iterator type of the Array type
    typedef Array::const_iterator ConstIterator; //!< Const iterator type of the Array type
    typedef Array::const_reverse_iterator ConstReverseIterator; //!< Const reverse iterator type of the Array type

    typedef std::vector<Ptr> PtrArray; //!< Array of pointers defined with a std::vector<boost::shared_ptr<> >

    typedef MultiArrayPair Pair;
    typedef std::pair<Iterator, Iterator> IteratorPair;
    typedef std::pair<ConstIterator, ConstIterator> ConstIteratorPair; //!< Pair of ConstIterators type, used to define a range
  };

}

#endif /* BIIPS_MULTIARRAY_HPP_ */