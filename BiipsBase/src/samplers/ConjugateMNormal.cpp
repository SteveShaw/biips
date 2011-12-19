//                                               -*- C++ -*-
/*! \file ConjugateMNormal.cpp
 * \brief
 *
 * \author  $LastChangedBy$
 * \date    $LastChangedDate$
 * \version $LastChangedRevision$
 * Id:      $Id$
 */

#include "samplers/ConjugateMNormal.hpp"
#include "sampler/GetNodeValueVisitor.hpp"
#include "common/cholesky.hpp"

namespace Biips
{

  const String ConjugateMNormal::NAME_ = "Conjugate Multivariate Normal (with known precision matrix)";


  void ConjugateMNormal::formLikeParamContrib(NodeId likeId,
      MultiArray::Array & likeParamContribValues)
  {
    VectorRef like_mean(likeParamContribValues[0]);
    MatrixRef like_prec(likeParamContribValues[1]);

    GraphTypes::ParentIterator it_parents = graph_.GetParents(likeId).first;

    NodeId prec_id = *(++it_parents);

    Matrix prec_i_mat(getNodeValue(prec_id, graph_, *this));

    MultiArray obs_i(graph_.GetNode(likeId).DimPtr(), graph_.GetValues()[likeId]);
    VectorRef obs_i_vec(obs_i);

    like_mean += ublas::prod(prec_i_mat, obs_i_vec);
    like_prec += prec_i_mat;
  }


  MultiArray::Array ConjugateMNormal::postParam(const MultiArray::Array & priorParamValues,
      const MultiArray::Array & likeParamContribValues) const
  {
    Matrix post_prec(priorParamValues[1]);

    Vector post_mean = ublas::prod(post_prec, Vector(priorParamValues[0])) + Vector(likeParamContribValues[0]);

    post_prec += Matrix(likeParamContribValues[1]);

    Matrix post_cov = post_prec;
    if (!ublas::cholesky_factorize(post_cov))
      throw LogicError("ConjugateMNormal::postParam: matrix post_cov is not positive-semidefinite.");
    ublas::cholesky_invert(post_cov);

    post_mean = ublas::prod(post_cov, post_mean);

    MultiArray::Array post_param_values(2);
    post_param_values[0] = MultiArray(post_mean);
    post_param_values[1] = MultiArray(post_prec);
    return post_param_values;
  }


  Scalar ConjugateMNormal::computeLogIncrementalWeight(const MultiArray & sampledData,
      const MultiArray::Array & priorParamValues,
      const MultiArray::Array & postParamValues,
      const MultiArray::Array & LikeParamContrib)
  {
    Matrix norm_const_prec(LikeParamContrib[1]);
    if (!ublas::cholesky_factorize(norm_const_prec))
      throw LogicError("ConjugateMNormal::computeLogIncrementalWeight: matrix norm_const_prec is not positive-semidefinite.");
    ublas::cholesky_invert(norm_const_prec);

    Vector norm_const_mean = ublas::prod(norm_const_prec, Vector(LikeParamContrib[0]));

    Matrix prior_prec(priorParamValues[1]);
    if (!ublas::cholesky_factorize(prior_prec))
      throw LogicError("ConjugateMNormal::computeLogIncrementalWeight: matrix prior_prec is not positive-semidefinite.");
    ublas::cholesky_invert(prior_prec);

    norm_const_prec += prior_prec;
    if (!ublas::cholesky_factorize(norm_const_prec))
      throw LogicError("ConjugateMNormal::computeLogIncrementalWeight: matrix norm_const_prec is not positive-semidefinite.");
    ublas::cholesky_invert(norm_const_prec);

    MultiArray::Array norm_const_param_values(2);
    norm_const_param_values[0] = MultiArray(norm_const_mean);
    norm_const_param_values[1] = MultiArray(norm_const_prec);

    Scalar log_incr_weight = DMNorm::Instance()->LogDensity(priorParamValues[0], norm_const_param_values, NULL_MULTIARRAYPAIR); // FIXME Boundaries
    if (isNan(log_incr_weight))
      throw RuntimeError("Failure to calculate log incremental weight.");

    return log_incr_weight;
  }


}
