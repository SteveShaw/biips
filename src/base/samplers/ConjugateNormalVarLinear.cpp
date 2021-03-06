#include "samplers/ConjugateNormalVarLinear.hpp"
#include "graph/Graph.hpp"
#include "sampler/GetNodeValueVisitor.hpp"
#include "sampler/NodesRelationVisitor.hpp"
#include "samplers/GetLinearTransformVisitor.hpp"
#include "samplers/IsLinearVisitor.hpp"
#include "graph/StochasticNode.hpp"
#include "graph/LogicalNode.hpp"
#include "distributions/DNormVar.hpp"

namespace Biips
{

  const String ConjugateNormalVarLinear::NAME_ =
      "ConjugateNormal_knownVar_linearMean";

  class NormalVarLinearLikeFormVisitor: public ConstNodeVisitor
  {
  protected:
    typedef NormalVarLinearLikeFormVisitor SelfType;
    typedef Types<SelfType>::Ptr Ptr;

    const Graph & graph_;
    NodeId myId_;
    ConjugateNormalVarLinear & nodeSampler_;
    Scalar mean_;
    Scalar varInv_;

    virtual void visit(const StochasticNode & node)
    {
      mean_ = 0.0;
      varInv_ = 0.0;

      NodeId mean_id = node.Parents()[0];
      NodeId var_id = node.Parents()[1];

      Scalar var = getNodeValue(var_id, graph_, nodeSampler_).ScalarView();
      GetLinearTransformVisitor get_lin_trans_vis(graph_, myId_, nodeSampler_);
      graph_.VisitNode(mean_id, get_lin_trans_vis);

      varInv_ = get_lin_trans_vis.GetA() / var;
      mean_ = (graph_.GetValues()[nodeId_]->ScalarView()
          - get_lin_trans_vis.GetB()) * varInv_;
      varInv_ *= get_lin_trans_vis.GetA();
    }

  public:
    Scalar GetMean() const
    {
      return mean_;
    }

    Scalar GetVarInv() const
    {
      return varInv_;
    }

    NormalVarLinearLikeFormVisitor(const Graph & graph,
                                   NodeId myId,
                                   ConjugateNormalVarLinear & nodeSampler) :
      graph_(graph), myId_(myId), nodeSampler_(nodeSampler), mean_(0.0),
          varInv_(0.0)
    {
    }
  };

  void ConjugateNormalVarLinear::sample(const StochasticNode & node)
  {
    NodeId prior_mean_id = node.Parents()[0];
    NodeId prior_var_id = node.Parents()[1];

    ValArray prior_mean;
    prior_mean = getNodeValue(prior_mean_id, graph_, *this).Values();
    Scalar prior_var = getNodeValue(prior_var_id, graph_, *this).ScalarView();

    Scalar like_var_inv = 0.0;
    ValArray like_mean(1);
    like_mean[0] = 0.0;

    GraphTypes::LikelihoodChildIterator it_offspring, it_offspring_end;
    boost::tie(it_offspring, it_offspring_end)
        = graph_.GetLikelihoodChildren(nodeId_);
    NormalVarLinearLikeFormVisitor like_form_vis(graph_, nodeId_, *this);
    while (it_offspring != it_offspring_end)
    {
      graph_.VisitNode(*it_offspring, like_form_vis);
      like_var_inv += like_form_vis.GetVarInv();
      like_mean[0] += like_form_vis.GetMean();
      ++it_offspring;
    }

    ValArray post_var(1);
    post_var[0] = 1 / (1 / prior_var + like_var_inv);
    ValArray post_mean(1);
    post_mean[0] = post_var[0] * (prior_mean[0] / prior_var + like_mean[0]);
    like_mean[0] /= like_var_inv;

    NumArray::Array post_param_values(2);
    post_param_values[0].SetPtr(P_SCALAR_DIM.get(), &post_mean);
    post_param_values[1].SetPtr(P_SCALAR_DIM.get(), &post_var);

    //allocate memory
    nodeValuesMap()[nodeId_].reset(new ValArray(1));
    //sample
    DNormVar::Instance()->Sample(*nodeValuesMap()[nodeId_],
                                 post_param_values,
                                 NULL_NUMARRAYPAIR,
                                 *pRng_);

    NumArray::Array norm_const_param_values(2);
    norm_const_param_values[0].SetPtr(P_SCALAR_DIM.get(), &like_mean);
    ValArray norm_const_var(1);
    norm_const_var[0] = prior_var + 1 / like_var_inv;
    norm_const_param_values[1].SetPtr(P_SCALAR_DIM.get(), &norm_const_var);
    logIncrementalWeight_
        = DNormVar::Instance()->LogDensity(NumArray(P_SCALAR_DIM.get(),
                                                    &prior_mean),
                                           norm_const_param_values,
                                           NULL_NUMARRAYPAIR); // FIXME Boundaries
    if (isNan(logIncrementalWeight_))
      throw RuntimeError("Failure to calculate log incremental weight.");
    // TODO optimize computation removing constant terms

    sampledFlagsMap()[nodeId_] = true;
  }

  class IsConjugateNormalVarLinearVisitor: public ConstNodeVisitor
  {
  protected:
    const Graph & graph_;
    const NodeId myId_;
    Bool conjugate_;

    void visit(const StochasticNode & node)
    {
      conjugate_ = false;
      if (node.PriorName() != "dnormvar")
        return;

      // FIXME
      if (node.IsBounded())
        return;

      NodeId mean_id = node.Parents()[0];
      NodeId var_id = node.Parents()[1];
      conjugate_ = ((nodesRelation(var_id, myId_, graph_) == KNOWN)
          && isLinear(mean_id, myId_, graph_)) ? true : false;
    }

  public:
    Bool IsConjugate() const
    {
      return conjugate_;
    }

    IsConjugateNormalVarLinearVisitor(const Graph & graph, NodeId myId) :
      graph_(graph), myId_(myId), conjugate_(false)
    {
    }
  };

  class CanSampleNormalVarLinearVisitor: public ConstNodeVisitor
  {
  protected:
    const Graph & graph_;
    Bool canSample_;

    void visit(const StochasticNode & node)
    {
      canSample_ = false;

      if (graph_.GetObserved()[nodeId_])
        throw LogicError("CanSampleNormalVarLinearVisitor can not visit observed node: node id sequence of the forward sampler may be bad.");

      if (node.PriorName() != "dnormvar")
        return;

      // FIXME
      if (node.IsBounded())
        return;

      GraphTypes::LikelihoodChildIterator it_offspring, it_offspring_end;
      boost::tie(it_offspring, it_offspring_end)
          = graph_.GetLikelihoodChildren(nodeId_);

      IsConjugateNormalVarLinearVisitor child_vis(graph_, nodeId_);

      for (; it_offspring != it_offspring_end; ++it_offspring)
      {
        graph_.VisitNode(*it_offspring, child_vis);
        canSample_ = child_vis.IsConjugate();
        if (!canSample_)
          break;
      }
    }

  public:
    Bool CanSample() const
    {
      return canSample_;
    }

    CanSampleNormalVarLinearVisitor(const Graph & graph) :
      graph_(graph), canSample_(false)
    {
    }
  };

  Bool ConjugateNormalVarLinearFactory::Create(const Graph & graph,
                                               NodeId nodeId,
                                               BaseType::CreatedPtr & pNodeSamplerInstance) const
  {
    CanSampleNormalVarLinearVisitor can_sample_vis(graph);

    graph.VisitNode(nodeId, can_sample_vis);

    Bool flag_created = can_sample_vis.CanSample();

    if (flag_created)
    {
      pNodeSamplerInstance
          = NodeSamplerFactory::CreatedPtr(new CreatedType(graph));
    }

    return flag_created;
  }

  ConjugateNormalVarLinearFactory::Ptr
      ConjugateNormalVarLinearFactory::pConjugateNormalVarLinearFactoryInstance_(new ConjugateNormalVarLinearFactory());

}

