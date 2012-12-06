//                                               -*- C++ -*-
/*
 * BiiPS software is a set of C++ libraries for
 * Bayesian inference with interacting Particle Systems.
 * Copyright (C) Inria, 2012
 * Authors: Adrien Todeschini, Francois Caron
 *
 * BiiPS is derived software based on:
 * JAGS, Copyright (C) Martyn Plummer, 2002-2010
 * SMCTC, Copyright (C) Adam M. Johansen, 2008-2009
 *
 * This file is part of BiiPS.
 *
 * BiiPS is free software: you can redistribute it and/or modify
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

/*! \file ConjugateNormal.cpp
 * \brief
 *
 * \author  $LastChangedBy$
 * \date    $LastChangedDate$
 * \version $LastChangedRevision$
 * Id:      $Id$
 */

#include "samplers/ConjugateNormal.hpp"
#include "sampler/GetNodeValueVisitor.hpp"

namespace Biips
{

  const String ConjugateNormal::NAME_ =
      "Conjugate Normal (with known precision)";

  MultiArray::Array ConjugateNormal::initLikeParamContrib() const
  {
    MultiArray::Array paramContribValues(2);
    ValArray::Ptr mean_valptr(new ValArray(1, 0.0));
    ValArray::Ptr prec_valptr(new ValArray(1, 0.0));
    paramContribValues[0].SetPtr(P_SCALAR_DIM, mean_valptr);
    paramContribValues[1].SetPtr(P_SCALAR_DIM, prec_valptr);

    return paramContribValues;
  }

  void ConjugateNormal::formLikeParamContrib(NodeId likeId,
                                             MultiArray::Array & likeParamContribValues)
  {
    GraphTypes::ParentIterator it_parents = graph_.GetParents(likeId).first;

    NodeId prec_id = *(++it_parents);
    Scalar like_prec = getNodeValue(prec_id, graph_, *this).ScalarView();
    likeParamContribValues[0].ScalarView()
        += graph_.GetValues()[likeId]->ScalarView() * like_prec;
    likeParamContribValues[1].ScalarView() += like_prec;
  }

  MultiArray::Array ConjugateNormal::postParam(const NumArray::Array & priorParamValues,
                                             const MultiArray::Array & likeParamContribValues) const
  {
    ValArray::Ptr post_prec_val(new ValArray(1));
    (*post_prec_val)[0] = priorParamValues[1].ScalarView()
        + likeParamContribValues[1].ScalarView();
    ValArray::Ptr post_mean_val(new ValArray(1));
    (*post_mean_val)[0] = (priorParamValues[0].ScalarView()
        * priorParamValues[1].ScalarView()
        + likeParamContribValues[0].ScalarView()) / (*post_prec_val)[0];

    MultiArray::Array post_param_values(2);
    post_param_values[0].SetPtr(P_SCALAR_DIM, post_mean_val);
    post_param_values[1].SetPtr(P_SCALAR_DIM, post_prec_val);
    return post_param_values;
  }

  Scalar ConjugateNormal::computeLogIncrementalWeight(const NumArray & sampledData,
                                                      const NumArray::Array & priorParamValues,
                                                      const NumArray::Array & postParamValues,
                                                      const MultiArray::Array & LikeParamContrib)
  {
    Scalar like_mean_contrib = LikeParamContrib[0].ScalarView();
    Scalar like_prec_contrib = LikeParamContrib[1].ScalarView();
    Scalar prior_prec = priorParamValues[1].ScalarView();
    NumArray::Array norm_const_param_values(2);
    ValArray norm_const_mean_val(1);
    norm_const_mean_val[0] = like_mean_contrib / like_prec_contrib;
    norm_const_param_values[0].SetPtr(P_SCALAR_DIM.get(), &norm_const_mean_val);
    ValArray norm_const_prec_val(1);
    norm_const_prec_val[0] = 1.0 / (1.0 / prior_prec + 1.0 / like_prec_contrib);
    norm_const_param_values[1].SetPtr(P_SCALAR_DIM.get(), &norm_const_prec_val);

    Scalar log_incr_weight =
        DNorm::Instance()->LogDensity(priorParamValues[0],
                                      norm_const_param_values,
                                      NULL_NUMARRAYPAIR); // FIXME Boundaries
    if (isNan(log_incr_weight))
      throw RuntimeError("Failure to calculate log incremental weight.");

    return log_incr_weight;
  }

}
