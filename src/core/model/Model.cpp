#include "model/Model.hpp"
#include "model/Monitor.hpp"
#include "common/Accumulator.hpp"
#include "common/ArrayAccumulator.hpp"
#include "sampler/GetNodeValueVisitor.hpp"
#include "graph/StochasticNode.hpp"

namespace Biips
{

  void Model::SetDefaultFilterMonitors()
  {
    for (NodeId id = 0; id < pGraph_->GetSize(); ++id)
    {
      if (pGraph_->GetNode(id).GetType() != STOCHASTIC)
        continue;

      // FIXME: Never add observed nodes, they won't be monitored !!
      if (pGraph_->GetObserved()[id])
        continue;

      // Monitor all unobserved stochastic nodes
      filterMonitorsMap_[id];

      // and its unobserved direct parents
      GraphTypes::ParentIterator it_parents, it_parents_end;
      boost::tie(it_parents, it_parents_end) = pGraph_->GetParents(id);
      for (; it_parents != it_parents_end; ++it_parents)
      {
        // FIXME: Never add observed nodes, they won't be monitored !!
        if (pGraph_->GetObserved()[*it_parents])
          continue;

        filterMonitorsMap_[*it_parents];
      }
    }

    defaultMonitorsSet_ = true;
  }

  Bool Model::SetFilterMonitor(NodeId nodeId)
  {
    // FIXME: it is no use monitoring observed nodes
    if (pGraph_->GetObserved()[nodeId])
      return false;

    filterMonitorsMap_[nodeId];
    return true;
  }

  Bool Model::SetBackwardSmoothMonitor(NodeId nodeId)
  {
    SetFilterMonitor(nodeId);

    // FIXME: it is no use monitoring observed nodes
    if (pGraph_->GetObserved()[nodeId])
      return false;

    backwardSmoothMonitorsMap_[nodeId];
    return true;
  }

  Bool Model::SetGenTreeSmoothMonitor(NodeId nodeId)
  {
    // FIXME: it is no use monitoring observed nodes
    if (pGraph_->GetObserved()[nodeId])
      return false;

    genTreeSmoothMonitoredNodeIds_.insert(nodeId);
    return true;
  }

  void Model::ClearFilterMonitors(Bool release_only)
  {
    filterMonitors_.clear();
    if (release_only)
    {
      for (std::map<NodeId, Monitor*>::iterator it_monitors =
          filterMonitorsMap_.begin(); it_monitors != filterMonitorsMap_.end();
          ++it_monitors)
      {
        it_monitors->second = NULL;
      }
      return;
    }
    filterMonitorsMap_.clear();
    defaultMonitorsSet_ = false;
  }

  void Model::ClearGenTreeSmoothMonitors(Bool release_only)
  {
    pGenTreeSmoothMonitor_.reset();
    if (release_only)
      return;
    genTreeSmoothMonitoredNodeIds_.clear();
  }

  void Model::ClearBackwardSmoothMonitors(Bool release_only)
  {
    backwardSmoothMonitors_.clear();
    if (release_only)
    {
      backwardSmoothMonitors_.clear();
      for (std::map<NodeId, Monitor*>::iterator it_monitors =
          backwardSmoothMonitorsMap_.begin(); it_monitors != backwardSmoothMonitorsMap_.end();
          ++it_monitors)
      {
        it_monitors->second = NULL;
      }
      return;
    }
    backwardSmoothMonitorsMap_.clear();
  }

  const ForwardSampler & Model::Sampler() const
  {
    if (!pSampler_)
      throw LogicError("Can not acces a Null ForwardSampler.");

    return *pSampler_;
  }

  const BackwardSmoother & Model::Smoother() const
  {
    if (!pSmoother_)
      throw LogicError("Can not acces a Null BackwardSmoother.");

    return *pSmoother_;
  }

  void Model::BuildSampler()
  {
    pSampler_.reset(new ForwardSampler(*pGraph_));

    pSampler_->Build();
  }

  void Model::InitSampler(Size nParticles,
                          Rng * pRng,
                          const String & rsType,
                          Scalar threshold)
  {
    // release monitors
    ClearFilterMonitors(true);
    ClearGenTreeSmoothMonitors(true);
    ClearBackwardSmoothMonitors(true);

    pSampler_->Initialize(nParticles, pRng, rsType, threshold);

    if (pSampler_->NIterations() == 0)
      return;

    // lock GenTreeSmooth monitored nodes
    for (std::set<NodeId>::const_iterator it_nodes =
        genTreeSmoothMonitoredNodeIds_.begin();
        it_nodes != genTreeSmoothMonitoredNodeIds_.end(); ++it_nodes)
      pSampler_->LockNode(*it_nodes);

    Size t = pSampler_->Iteration();

    // nodes sampled at the current iteration
    Types<NodeId>::Array sampled_nodes = pSampler_->LastSampledNodes();
    // conditional nodes (observed stochastic parents and children) at the current iteration
    Types<NodeId>::Array cond_nodes = pSampler_->ConditionalNodes();

    // Filter Monitors
    NodeId node_id = NULL_NODEID;
    // We create a monitor object even if no nodes are monitored
    // used to get the filtering conditionals
    FilterMonitor * p_monitor = new FilterMonitor(t, sampled_nodes, cond_nodes);
    filterMonitors_.push_back(boost::shared_ptr<Monitor>(p_monitor));
    pSampler_->InitMonitor(*p_monitor);
    for (Size i = 0; i < sampled_nodes.size(); ++i)
    {
      node_id = sampled_nodes[i];
      if (filterMonitorsMap_.count(node_id))
      {
        pSampler_->MonitorNode(node_id, *p_monitor);
        filterMonitorsMap_[node_id] = p_monitor;
      }
    }

    if (!pSampler_->AtEnd())
    {
      // release memory
      pSampler_->ReleaseNodes();
      return;
    }

    // Smooth tree Monitors
    p_monitor = new FilterMonitor(t, sampled_nodes, cond_nodes);
    pGenTreeSmoothMonitor_.reset(p_monitor);
    pSampler_->InitMonitor(*p_monitor);
    for (std::set<NodeId>::const_iterator it_ids =
        genTreeSmoothMonitoredNodeIds_.begin();
        it_ids != genTreeSmoothMonitoredNodeIds_.end(); ++it_ids)
    {
      pSampler_->MonitorNode(*it_ids, *p_monitor);
      pSampler_->UnlockNode(*it_ids);
    }

    // release memory
    pSampler_->UnlockAllNodes();
    pSampler_->ReleaseNodes();
  }

  void Model::IterateSampler()
  {
    if (!pSampler_)
      throw LogicError("Can not iterate a Null ForwardSampler.");

    pSampler_->Iterate();

    Size t = pSampler_->Iteration();

    // nodes sampled at the current iteration
    Types<NodeId>::Array sampled_nodes = pSampler_->LastSampledNodes();
    // conditional nodes (observed stochastic parents and children) at the current iteration
    Types<NodeId>::Array cond_nodes = pSampler_->ConditionalNodes();

    // Filter Monitors
    NodeId node_id = NULL_NODEID;
    // We create a monitor object even if no nodes are monitored
    // used to get the filtering conditionals
    FilterMonitor * p_monitor = new FilterMonitor(t, sampled_nodes, cond_nodes);
    filterMonitors_.push_back(boost::shared_ptr<Monitor>(p_monitor));
    pSampler_->InitMonitor(*p_monitor);
    for (Size i = 0; i < sampled_nodes.size(); ++i)
    {
      node_id = sampled_nodes[i];
      if (filterMonitorsMap_.count(node_id))
      {
        pSampler_->MonitorNode(node_id, *p_monitor);
        filterMonitorsMap_[node_id] = p_monitor;
      }
    }

    if (!pSampler_->AtEnd())
    {
      // release memory
      pSampler_->ReleaseNodes();
      return;
    }

    // Smooth tree Monitors
    p_monitor = new FilterMonitor(t, sampled_nodes, cond_nodes);
    pGenTreeSmoothMonitor_.reset(p_monitor);
    pSampler_->InitMonitor(*p_monitor);
    for (std::set<NodeId>::const_iterator it_ids =
        genTreeSmoothMonitoredNodeIds_.begin();
        it_ids != genTreeSmoothMonitoredNodeIds_.end(); ++it_ids)
    {
      pSampler_->MonitorNode(*it_ids, *p_monitor);
      pSampler_->UnlockNode(*it_ids);
    }

    // release memory
    pSampler_->UnlockAllNodes();
    pSampler_->ReleaseNodes();
  }

  void Model::InitBackwardSmoother()
  {
    // release monitors
    ClearBackwardSmoothMonitors(true);

    if (!defaultMonitorsSet_)
      throw LogicError("Can not initiate backward smoother: default monitors not set.");

    if (!pSampler_)
      throw LogicError("Can not initiate backward smoother: no ForwardSampler.");

    Types<Monitor*>::Array f_monitors(filterMonitors_.size());
    for (Size i = 0; i < f_monitors.size(); ++i)
      f_monitors[i] = filterMonitors_[i].get();
    pSmoother_.reset(new BackwardSmoother(*pGraph_,
                                          f_monitors,
                                          pSampler_->GetNodeSamplingIterations()));

    pSmoother_->Initialize();

    Types<NodeId>::Array updated_nodes = pSmoother_->LastUpdatedNodes();
    Size t = pSmoother_->Iteration();

    // Smooth Monitors
    NodeId node_id = NULL_NODEID;
    // FIXME Do we create monitor object even if no nodes are monitored ?
    SmoothMonitor * p_monitor = new SmoothMonitor(t, updated_nodes);
    backwardSmoothMonitors_.push_back(boost::shared_ptr<Monitor>(p_monitor));
    pSmoother_->InitMonitor(*p_monitor);
    for (Size i = 0; i < updated_nodes.size(); ++i)
    {
      node_id = updated_nodes[i];
      if (backwardSmoothMonitorsMap_.count(node_id))
      {
        pSmoother_->MonitorNode(node_id, *p_monitor);
        backwardSmoothMonitorsMap_[node_id] = p_monitor;
      }
    }

  }

  void Model::IterateBackwardSmoother()
  {
    if (!pSmoother_)
      throw LogicError("Can not iterate backward smoother: not initialized.");

    pSmoother_->IterateBack();

    Types<NodeId>::Array updated_nodes = pSmoother_->LastUpdatedNodes();
    Size t = pSmoother_->Iteration();

    // Smooth Monitors
    NodeId node_id = NULL_NODEID;
    // FIXME Do we create monitor object even if no nodes are monitored ?
    SmoothMonitor * p_monitor = new SmoothMonitor(t, updated_nodes);
    backwardSmoothMonitors_.push_back(boost::shared_ptr<Monitor>(p_monitor));
    pSmoother_->InitMonitor(*p_monitor);
    for (Size i = 0; i < updated_nodes.size(); ++i)
    {
      node_id = updated_nodes[i];
      if (backwardSmoothMonitorsMap_.count(node_id))
      {
        pSmoother_->MonitorNode(node_id, *p_monitor);
        backwardSmoothMonitorsMap_[node_id] = p_monitor;
      }
    }

  }

  MultiArray Model::extractMonitorStat(NodeId nodeId,
                                       StatTag statFeature,
                                       const std::map<NodeId, Monitor*> & monitorsMap) const
  {
    if (monitorsMap.find(nodeId) == monitorsMap.end())
      throw LogicError("Node is not yet monitored.");

    ArrayAccumulator array_acc;
    array_acc.AddFeature(statFeature);

    monitorsMap.at(nodeId)->Accumulate(nodeId,
                                       array_acc,
                                       pGraph_->GetNode(nodeId).DimPtr());

    MultiArray stat_marray;

    switch (statFeature)
    {
      case SUM:
        stat_marray = array_acc.Sum();
        break;
      case MEAN:
        stat_marray = array_acc.Mean();
        break;
      case VARIANCE:
        stat_marray = array_acc.Variance();
        break;
      case MOMENT2:
        stat_marray = array_acc.Moment<2>();
        break;
      case MOMENT3:
        stat_marray = array_acc.Moment<3>();
        break;
      case MOMENT4:
        stat_marray = array_acc.Moment<4>();
        break;
      case SKEWNESS:
        stat_marray = array_acc.Skewness();
        break;
      case KURTOSIS:
        stat_marray = array_acc.Kurtosis();
        break;
      default:
        break;
    }

    return stat_marray;
  }

  MultiArray Model::ExtractFilterStat(NodeId nodeId, StatTag statFeature) const
  {
    if (!pSampler_)
      throw LogicError("Can not extract filter statistic: no ForwardSampler.");

    return extractMonitorStat(nodeId, statFeature, filterMonitorsMap_);
  }

  MultiArray Model::ExtractBackwardSmoothStat(NodeId nodeId, StatTag statFeature) const
  {
    if (!pSampler_)
      throw LogicError("Can not extract backward smoother statistic: no ForwardSampler.");

    return extractMonitorStat(nodeId, statFeature, backwardSmoothMonitorsMap_);
  }

  // TODO manage discrete variable cases
  Histogram Model::extractMonitorPdf(NodeId nodeId,
                                     Size numBins,
                                     Scalar cacheFraction,
                                     const std::map<NodeId, Monitor*> & monitorsMap) const
  {
    if (!pSampler_)
      throw LogicError("Can not extract filter pdf: no ForwardSampler.");

    if (!pGraph_->GetNode(nodeId).Dim().IsScalar())
      throw LogicError("Can not extract filter pdf: node is not scalar.");

    if (monitorsMap.find(nodeId) == monitorsMap.end())
      throw LogicError("Node is not yet monitored.");

    DensityAccumulator dens_acc(roundSize(pSampler_->NParticles()
                                          * cacheFraction),
                                numBins);

    monitorsMap.at(nodeId)->Accumulate(nodeId, dens_acc);

    return dens_acc.Density();
  }

  // TODO manage discrete variable cases
  Histogram Model::ExtractFilterPdf(NodeId nodeId,
                                    Size numBins,
                                    Scalar cacheFraction) const
  {
    if (!pSampler_)
      throw LogicError("Can not extract filter pdf: no ForwardSampler.");

    return extractMonitorPdf(nodeId, numBins, cacheFraction, filterMonitorsMap_);
  }

  // TODO manage discrete variable cases
  Histogram Model::ExtractBackwardSmoothPdf(NodeId nodeId,
                                    Size numBins,
                                    Scalar cacheFraction) const
  {
    if (!pSampler_)
      throw LogicError("Can not extract backward smooth pdf: no ForwardSampler.");

    return extractMonitorPdf(nodeId, numBins, cacheFraction, backwardSmoothMonitorsMap_);
  }

  // FIXME Still valid after optimization ?
  MultiArray Model::ExtractGenTreeSmoothStat(NodeId nodeId,
                                          StatTag statFeature) const
  {
    if (!pSampler_)
      throw LogicError("Can not extract smooth statistic: no ForwardSampler.");

    ArrayAccumulator elem_acc;
    elem_acc.AddFeature(statFeature);

    pSampler_->Accumulate(nodeId, elem_acc);

    MultiArray stat_marray;

    switch (statFeature)
    {
      case SUM:
        stat_marray = elem_acc.Sum();
        break;
      case MEAN:
        stat_marray = elem_acc.Mean();
        break;
      case VARIANCE:
        stat_marray = elem_acc.Variance();
        break;
      case MOMENT2:
        stat_marray = elem_acc.Moment<2>();
        break;
      case MOMENT3:
        stat_marray = elem_acc.Moment<3>();
        break;
      case MOMENT4:
        stat_marray = elem_acc.Moment<4>();
        break;
      case SKEWNESS:
        stat_marray = elem_acc.Skewness();
        break;
      case KURTOSIS:
        stat_marray = elem_acc.Kurtosis();
        break;
      default:
        break;
    }

    return stat_marray;
  }

  // TODO manage dicrete variable cases
  // FIXME Still valid after optimization ?
  Histogram Model::ExtractGenTreeSmoothPdf(NodeId nodeId,
                                        Size numBins,
                                        Scalar cacheFraction) const
  {
    if (!pSampler_)
      throw LogicError("Can not extract smooth pdf: no ForwardSampler.");

    if (!pGraph_->GetNode(nodeId).Dim().IsScalar())
      throw LogicError("Can not extract smooth pdf: node is not scalar.");

    DensityAccumulator dens_acc(roundSize(pSampler_->NParticles()
                                          * cacheFraction),
                                numBins);

    pSampler_->Accumulate(nodeId, dens_acc);

    return dens_acc.Density();
  }

  class LogPriorDensityVisitor: public ConstNodeVisitor
  {
  protected:
    const Graph & graph_;
    Scalar prior_;
  public:
    virtual void visit(const ConstantNode & node)
    {
      prior_ = BIIPS_REALNA;
    }

    virtual void visit(const LogicalNode & node)
    {
      prior_ = BIIPS_REALNA;
    }

    virtual void visit(const StochasticNode & node)
    {
      NumArray x(node.DimPtr().get(), graph_.GetValues()[nodeId_].get());
      NumArray::Array parents(node.Parents().size());
      for (Size i = 0; i < node.Parents().size(); ++i)
      {
        NodeId par_id = node.Parents()[i];
        parents[i].SetPtr(graph_.GetNode(par_id).DimPtr().get(),
                          graph_.GetValues()[par_id].get());
      }
      NumArray::Pair bounds;
      if (node.PriorPtr()->CanBound())
      {
        if (node.IsLowerBounded())
          bounds.first.SetPtr(graph_.GetNode(node.Lower()).DimPtr().get(),
                              graph_.GetValues()[node.Lower()].get());

        if (node.IsUpperBounded())
          bounds.second.SetPtr(graph_.GetNode(node.Upper()).DimPtr().get(),
                               graph_.GetValues()[node.Upper()].get());
      }

      try {
        prior_ = node.LogPriorDensity(x, parents, bounds);
      }
      catch (RuntimeError & except) {
        throw NodeError(nodeId_, String(except.what()));
      }
    }

    Scalar GetPrior() const
    {
      return prior_;
    }

    explicit LogPriorDensityVisitor(const Graph & graph) :
        graph_(graph), prior_(BIIPS_REALNA)
    {
    }
  };

  Scalar Model::GetLogPriorDensity(NodeId nodeId) const
  {
    // constant and stochastic will be assigned NA

    // check node is observed
    if (!pGraph_->GetObserved()[nodeId])
      throw RuntimeError("Can not get prior density: node is not observed.");

    if (pGraph_->GetNode(nodeId).GetType() == STOCHASTIC)
    {
      // check parents of stochastic nodes are observed
      GraphTypes::ParentIterator it_parent, it_parent_end;
      boost::tie(it_parent, it_parent_end) = pGraph_->GetParents(nodeId);
      for (; it_parent != it_parent_end; ++it_parent)
      {
        if (!pGraph_->GetObserved()[*it_parent])
          throw RuntimeError("Can not get prior density: node has unobserved parents.");
      }
    }

    LogPriorDensityVisitor log_prior_vis(*pGraph_);
    pGraph_->VisitNode(nodeId, log_prior_vis);

    return log_prior_vis.GetPrior();
  }

  Types<ValArray>::Pair Model::GetFixedSupport(NodeId nodeId) const
  {
    if (pGraph_->GetNode(nodeId).GetType() != STOCHASTIC)
      throw RuntimeError("Can not get fixed support: node is not stochastic.");

    // check that support is fixed
    if (!isSupportFixed(nodeId, *pGraph_))
      throw NodeError(nodeId, "Can not get fixed support: node distribution support is not fixed.");

    Size len = pGraph_->GetNode(nodeId).DimPtr()->Length();
    ValArray lower(len), upper(len);
    getFixedSupportValues(lower, upper, nodeId, *pGraph_);

    return std::make_pair(lower, upper);
  }
}
