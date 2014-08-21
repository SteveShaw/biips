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

/*! \file DMNorm.cpp
 * \brief
 *
 * \author  $LastChangedBy$
 * \date    $LastChangedDate$
 * \version $LastChangedRevision$
 * Id:      $Id$
 */

#define _USE_MATH_DEFINES

#include <boost/random/normal_distribution.hpp>
#include <boost/random/variate_generator.hpp>

#include "distributions/DMNorm.hpp"
#include "common/cholesky.hpp"

namespace Biips
{

  static const Scalar TOL = 1e-7;

  Bool DMNorm::checkParamDims(
      const Types<DimArray::Ptr>::Array & paramDims) const
  {
    const DimArray & mean_dim = *paramDims[0];
    const DimArray & prec_dim = *paramDims[1];
    if (!mean_dim.Drop().IsVector())
      return false;
    if (prec_dim.IsSquared())
      return (mean_dim[0] == prec_dim[0]);
    else
      return mean_dim.IsScalar() && prec_dim.IsScalar();
  }

  DimArray DMNorm::dim(const Types<DimArray::Ptr>::Array & paramDims) const
  {
    return paramDims[0]->Drop();
  }

  Bool DMNorm::CheckParamValues(const NumArray::Array & paramValues) const
  {
    const NumArray & mean = paramValues[0];
    const NumArray & prec = paramValues[1];


    Size n = mean.Length();

    // FIXME: this is only valid for Column major order
    for (Size i = 0; i < n; ++i)
    {
      if (!isFinite(mean.Values()[i]))
        return false;
      Size x_ind = i;
      Size y_ind = n * i;
      for (Size j = 0; j < i; ++j)
      {
        if (std::fabs(prec.Values()[x_ind] - prec.Values()[y_ind]) > TOL)
          return false;
        x_ind += n;
        y_ind++;
      }
    }

    return true;
  }

  void DMNorm::sample(ValArray & values, const NumArray::Array & paramValues,
                      const NumArray::Pair & boundValues, Rng & rng) const
  {
    const NumArray & mean = paramValues[0];
    const NumArray & prec = paramValues[1];

    Size n_dim = mean.Values().size();

    Matrix prec_chol(prec);
    if (!ublas::cholesky_factorize(prec_chol))
      throw RuntimeError(
          "DMNorm::sample: matrix is not positive-semidefinite.");

    typedef boost::normal_distribution<Scalar> DistType;
    boost::variate_generator<Rng::GenType&, DistType> gen(rng.GetGen(),
                                                          DistType());

    std::generate(values.begin(), values.end(), gen);

    ublas::vector<Scalar, ValArray> sample_vec(values.size(), ValArray());
    sample_vec.data().swap(values);
    ublas::inplace_solve(ublas::trans(prec_chol), sample_vec,
                         ublas::upper_tag());
    values.swap(sample_vec.data());

    for (Size i = 0; i < n_dim; ++i)
      values[i] += mean.Values()[i];
  }

  Scalar DMNorm::logDensity(const NumArray & x,
                            const NumArray::Array & paramValues,
                            const NumArray::Pair & boundValues) const
  {
    const NumArray & mean = paramValues[0];
    const NumArray & prec = paramValues[1];

    Vector diff_vec(x.Length(), x.Values() - mean.Values());

    Matrix prec_chol(prec);
    if (!ublas::cholesky_factorize(prec_chol))
      throw LogicError(
          "DMNorm::logDensity: matrix is not positive-semidefinite.");

    diff_vec = ublas::prod(
        diff_vec, ublas::triangular_adaptor<Matrix, ublas::lower>(prec_chol));

    return -0.5
           * (diff_vec.size() * LOG_2PI - ublas::cholesky_logdet(prec_chol)
              + ublas::inner_prod(diff_vec, diff_vec));
  }

  void DMNorm::fixedUnboundedSupport(ValArray & lower, ValArray & upper,
                                const NumArray::Array & paramValues) const
  {
    std::fill(lower.begin(), lower.end(), BIIPS_NEGINF);
    std::fill(upper.begin(), upper.end(), BIIPS_POSINF);
  }
}
