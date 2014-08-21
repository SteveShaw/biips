//                                               -*- C++ -*-
/*
 * Biips software is a set of C++ libraries for
 * Bayesian inference with interacting Particle Systems.
 * Copyright (C) Inria, 2012
 * Authors: Adrien Todeschini, Francois Caron
 *
 * Biips is derived software based on:
 * JAGS, Copyright (C) Martyn Plummer, 2002-2010
 * SMCTC, Copyright (C) Adam M. Johansen, 2008-2009
 *
 * This file is part of Biips.
 *
 * Biips is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/*! \file Table.hpp
 * \brief
 *
 * \author  $LastChangedBy$
 * \date    $LastChangedDate$
 * \version $LastChangedRevision$
 * Id:      $Id$
 */

#ifndef BIIPS_TABLE_HPP_
#define BIIPS_TABLE_HPP_

#include "common/Types.hpp"
#include <map>

namespace Biips
{

  template<typename T>
  class Table
  {
  public:
    typedef T StoredType;
    typedef typename Types<StoredType>::Ptr StoredPtr;

  protected:
    std::map<String, StoredPtr> map_;
    std::map<String, Bool> lock_;

    static const StoredPtr nullPtr_;

  public:
    Table() {}

    Bool Insert(const StoredPtr & ptr, Bool lock=false);
    Size Remove(const String & name);

    Bool Contains(const String & name) const;
    Bool IsLocked(const String & name) const;

    const StoredPtr & GetPtr(const String & name) const;
    const StoredPtr & operator [] (const String & name) const { return GetPtr(name); }

    virtual ~Table() {}
  };


  template<typename T>
  const typename Table<T>::StoredPtr Table<T>::nullPtr_;


  template<typename T>
  Bool Table<T>::Insert(const StoredPtr & ptr, Bool lock)
  {
    if (!ptr)
      throw LogicError("Can not Insert in Table: ptr is NULL.");

    String name = ptr->Name();
    String alias = ptr->Alias();

    if (IsLocked(name))
      return false;
    else if (!alias.empty() && IsLocked(alias))
      return false;


    map_.insert(std::make_pair(name, ptr));
    lock_.insert(std::make_pair(name, lock));

    if (!alias.empty()) {
      map_.insert(std::make_pair(alias, ptr));
      lock_.insert(std::make_pair(alias, lock));
    }

    return true;
  }


  template<typename T>
  Size Table<T>::Remove(const String & name)
  {
    if (IsLocked(name))
      return 0;

    Size nb_removed = map_.erase(name);
    lock_.erase(name);
    String alias = map_.at(name)->Alias();
    if (!alias.empty()) {
      nb_removed += map_.erase(alias);
      lock_.erase(alias);
    }

    return nb_removed;
  }


  template<typename T>
  Bool Table<T>::Contains(const String & name) const
  {
    return map_.find(name) != map_.end();
  }

  template<typename T>
  Bool Table<T>::IsLocked(const String & name) const
  {
    return map_.find(name) != map_.end() && lock_.at(name);
  }


  template<typename T>
  const typename Table<T>::StoredPtr & Table<T>::GetPtr(const String & name) const
  {
    if (map_.find(name) != map_.end())
      return map_.at(name);
    else
      return nullPtr_;
  }

}

#endif /* BIIPS_TABLE_HPP_ */
