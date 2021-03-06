#include "samplers/ConjugateBeta.hpp"
#include "sampler/GetNodeValueVisitor.hpp"

namespace Biips
{

  const String ConjugateBeta::NAME_ = "ConjugateBeta";

  void ConjugateBeta::formLikeParamContrib(NodeId likeId,
                                           MultiArray::Array & likeParamContribValues)
  {
    GraphTypes::ParentIterator it_parents = graph_.GetParents(likeId).first;

    NodeId trials_id = *(it_parents);

    likeParamContribValues[0].ScalarView() += getNodeValue(trials_id,
                                                           graph_,
                                                           *this).ScalarView();
    likeParamContribValues[1].ScalarView()
        += graph_.GetValues()[likeId]->ScalarView();
  }

  MultiArray::Array ConjugateBeta::postParam(const NumArray::Array & priorParamValues,
                                           const MultiArray::Array & likeParamContribValues) const
  {
    ValArray::Ptr post_alpha_val(new ValArray(1));
    (*post_alpha_val)[0] = priorParamValues[0].ScalarView()
        + likeParamContribValues[1].ScalarView();

    ValArray::Ptr post_beta_val(new ValArray(1));
    (*post_beta_val)[0] = priorParamValues[1].ScalarView()
        + likeParamContribValues[0].ScalarView()
        - likeParamContribValues[1].ScalarView();

    MultiArray::Array post_param_values(2);
    post_param_values[0].SetPtr(P_SCALAR_DIM, post_alpha_val);
    post_param_values[1].SetPtr(P_SCALAR_DIM, post_beta_val);
    return post_param_values;
  }

  Scalar ConjugateBeta::computeLogIncrementalWeight(const NumArray & sampledData,
                                                    const NumArray::Array & priorParamValues,
                                                    const NumArray::Array & postParamValues,
                                                    const MultiArray::Array & likeParamContrib)
  {
    // Prior
    Scalar log_prior = DBeta::Instance()->LogDensity(sampledData,
                                                     priorParamValues,
                                                     NULL_NUMARRAYPAIR); // FIXME Boundaries
    if (isNan(log_prior))
      throw NodeError(nodeId_, "Failure to calculate log prior density.");

    // Likelihood
    NumArray::Array like_param_values(2);
    like_param_values[0] = NumArray(likeParamContrib[0]);
    like_param_values[1] = sampledData;

    Scalar log_like = DBin::Instance()->LogDensity(NumArray(likeParamContrib[1]),
                                                   like_param_values,
                                                   NULL_NUMARRAYPAIR); // FIXME Boundaries
    if (isNan(log_like))
      throw RuntimeError("Failure to calculate log likelihood.");

    // Posterior
    Scalar log_post = DBeta::Instance()->LogDensity(sampledData,
                                                    postParamValues,
                                                    NULL_NUMARRAYPAIR); // FIXME Boundaries
    if (isNan(log_post))
      throw NodeError(nodeId_, "Failure to calculate log posterior density.");

    // Incremental weight
    Scalar log_incr_weight = log_prior + log_like - log_post;
    if (isNan(log_incr_weight))
    {
      if (!isFinite(log_prior))
      {
        if (!isFinite(log_like))
          throw RuntimeError("Prior and likelihood are incompatible.");
        if (!isFinite(log_post))
          throw RuntimeError("Prior and posterior are incompatible.");
      }

      if (!isFinite(log_like))
      {
        if (!isFinite(log_post))
          throw RuntimeError("Likelihood and posterior are incompatible.");
      }

      throw RuntimeError("Failure to calculate log incremental weight.");
    }

    return log_incr_weight;
  }

}
