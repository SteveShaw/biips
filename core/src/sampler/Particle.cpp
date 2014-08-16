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

/*! \file Particle.cpp
 * \brief 
 * 
 * \author  $LastChangedBy$
 * \date    $LastChangedDate$
 * \version $LastChangedRevision$
 * Id:      $Id$
 */

#include "sampler/Particle.hpp"

namespace Biips
{

  void Particle::AddToLogWeight(Scalar increment)
  {
    if (isNan(logWeight_+increment))
    {
      if (!isFinite(logWeight_) && !isFinite(increment))
      {
        throw RuntimeError(String("Log weight and incremental log weight are incompatible: ")+print(logWeight_)+" ,  "+print(increment));
      }
      throw RuntimeError("Failure to calculate particle log weight.");
    }
    logWeight_ += increment;
    weight_ = std::exp(logWeight_);
    if (isNan(weight_))
      throw RuntimeError("Failure to calculate particle weight.");

  }
}
