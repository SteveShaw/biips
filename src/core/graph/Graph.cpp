#include <boost/graph/topological_sort.hpp>
#include <boost/graph/depth_first_search.hpp>
#include <boost/graph/graph_utility.hpp>

#include "graph/Graph.hpp"
#include "sampler/DataNodeSampler.hpp"
#include "graph/ConstantNode.hpp"
#include "graph/AggNode.hpp"
#include "graph/FuncNode.hpp"
#include "graph/StochasticNode.hpp"
#include "distribution/DistError.hpp"
#include "sampler/NodesRelationVisitor.hpp"

namespace Biips
{

  NodeId Graph::AddConstantNode(const DimArray::Ptr & pDim,
                                const Types<StorageType>::Ptr & pValue)
  {
    if (!pDim)
      throw LogicError("Can not add constant node: DimArray::Ptr is NULL.");

    if (!pValue)
      throw LogicError("Can not add constant node: value pointer is NULL.");

    if (pDim->Length() != pValue->size())
      throw LogicError("Can not add constant node: values size does not match dimension.");

    Node::Ptr new_node(new ConstantNode(pDim));
    NodeId node_id = boost::add_vertex(parentsGraph_);
    boost::put(boost::vertex_node_ptr, parentsGraph_, node_id, new_node);
    boost::put(boost::vertex_observed, parentsGraph_, node_id, true);
    boost::put(boost::vertex_value, parentsGraph_, node_id, pValue);

    // set dicreteness
    Bool discrete = true;
    for (Size i = 0; i < pValue->size(); ++i)
    {
      if (!checkInteger((*pValue)[i]))
      {
        discrete = false;
        break;
      }
    }
    boost::put(boost::vertex_discrete, parentsGraph_, node_id, discrete);

    nodesSummaryMap_[CONSTANT] += 1;
    builtFlag_ = false; // TODO also set to false when SetParameter is called
    return node_id;
  }

  NodeId Graph::AddAggNode(const DimArray::Ptr & pDim,
                           const Types<NodeId>::Array & parameters,
                           const Types<Size>::Array & offsets)
  {
    Node::Ptr new_node(new AggNode(pDim, parameters, offsets));
    NodeId node_id = boost::add_vertex(parentsGraph_);

    boost::put(boost::vertex_node_ptr, parentsGraph_, node_id, new_node);

    for (Size i = 0; i < parameters.size(); ++i)
    {
      boost::add_edge(node_id, parameters[i], parentsGraph_); // TODO check parameters
    }

    Bool observed = false;
    for (Size i = 0; i < parameters.size(); ++i)
    {
      if (GetObserved()[parameters[i]])
        observed = true;
      else
      {
        observed = false;
        break;
      }
    }

    boost::put(boost::vertex_observed, parentsGraph_, node_id, observed);
    if (observed)
      SampleValue(node_id, NULL, true);

    //set discreteness
    Bool discrete = true;
    for (Size i = 0; i < parameters.size(); ++i)
    {
      if (!GetDiscrete()[parameters[i]])
      {
        discrete = false;
        break;
      }
    }
    boost::put(boost::vertex_discrete, parentsGraph_, node_id, discrete);

    nodesSummaryMap_[LOGICAL] += 1;
    if (!observed)
      unobsNodesSummaryMap_[LOGICAL] += 1;

    builtFlag_ = false;
    return node_id;
  }

  // TODO: to be exposed like getParamValues
  Types<DimArray::Ptr>::Array Graph::getParamDims(const Types<NodeId>::Array parameters) const
  {
    Types<DimArray::Ptr>::Array param_dims(parameters.size());
    for (Size i = 0; i < parameters.size(); ++i)
      param_dims[i] = GetNode(parameters[i]).DimPtr();

    return param_dims;
  }

  NodeId Graph::AddLogicalNode(const Function::Ptr & pFunc,
                               const Types<NodeId>::Array & parameters)
  {
    Types<DimArray::Ptr>::Array param_dims = getParamDims(parameters);

    if (!pFunc)
      throw LogicError("Can not add logical node: Function::Ptr is NULL.");

    DimArray::Ptr pDim(new DimArray(pFunc->Dim(param_dims)));

    Node::Ptr new_node(new FuncNode(pDim, pFunc, parameters));
    NodeId node_id = boost::add_vertex(parentsGraph_);
    boost::put(boost::vertex_node_ptr, parentsGraph_, node_id, new_node);

    for (Size i = 0; i < parameters.size(); ++i)
    {
      boost::add_edge(node_id, parameters[i], parentsGraph_); // TODO check parameters
    }

    Bool observed = false;
    for (Size i = 0; i < parameters.size(); ++i)
    {
      if (GetObserved()[parameters[i]])
        observed = true;
      else
      {
        observed = false;
        break;
      }
    }

    boost::put(boost::vertex_observed, parentsGraph_, node_id, observed);
    if (observed)
      SampleValue(node_id, NULL, true);

    //set discreteness
    Flags mask(parameters.size());
    for (Size i = 0; i < parameters.size(); ++i)
      mask[i] = GetDiscrete()[parameters[i]];

    boost::put(boost::vertex_discrete,
               parentsGraph_,
               node_id,
               pFunc->IsDiscreteValued(mask));

    nodesSummaryMap_[LOGICAL] += 1;
    if (!observed)
      unobsNodesSummaryMap_[LOGICAL] += 1;

    builtFlag_ = false;
    return node_id;
  }

  NodeId Graph::AddStochasticNode(const Distribution::Ptr & pDist,
                                  const Types<NodeId>::Array & parameters,
                                  Bool observed,
                                  NodeId lower,
                                  NodeId upper)
  {
    Types<DimArray::Ptr>::Array param_dims = getParamDims(parameters);

    if (!pDist)
      throw LogicError("Can not add stochastic node: Distribution::Ptr is NULL.");

    DimArray::Ptr pDim(new DimArray(pDist->Dim(param_dims)));

    Node::Ptr new_node(new StochasticNode(pDim,
                                          pDist,
                                          parameters,
                                          lower,
                                          upper));
    NodeId node_id = boost::add_vertex(parentsGraph_);
    boost::put(boost::vertex_node_ptr, parentsGraph_, node_id, new_node);
    boost::put(boost::vertex_observed, parentsGraph_, node_id, observed);

    for (Size i = 0; i < parameters.size(); ++i)
    {
      boost::add_edge(node_id, parameters[i], parentsGraph_); // TODO check parameters (discreteness)
    }

    //check boundaries
    if (lower != NULL_NODEID)
    {
      if (!pDist->CanBound())
        throw DistError(pDist, "Distribution cannot be bounded");
      if (*(GetNode(lower).DimPtr()) != (*pDim))
        throw DistError(pDist, "Dimension mismatch when setting lower bounds");

      boost::add_edge(node_id, lower, parentsGraph_);
    }
    if (upper != NULL_NODEID)
    {
      if (!pDist->CanBound())
        throw DistError(pDist, "Distribution cannot be bounded");
      if (*(GetNode(lower).DimPtr()) != (*pDim))
        throw DistError(pDist, "Dimension mismatch when setting upper bounds");

      boost::add_edge(node_id, upper, parentsGraph_);
    }

    //check discreteness of parents
    Flags mask(parameters.size());
    for (Size i = 0; i < parameters.size(); ++i)
      mask[i] = GetDiscrete()[parameters[i]];
    if (!pDist->CheckParamDiscrete(mask))
      throw DistError(pDist, "Failed check for discrete-valued parameters");

    //set discreteness
    boost::put(boost::vertex_discrete,
               parentsGraph_,
               node_id,
               pDist->IsDiscreteValued(mask));

    nodesSummaryMap_[STOCHASTIC] += 1;
    if (!observed)
      unobsNodesSummaryMap_[STOCHASTIC] += 1;

    builtFlag_ = false;
    return node_id;
  }

  NodeId Graph::AddStochasticNode(const Distribution::Ptr & pDist,
                                  const Types<NodeId>::Array & parameters,
                                  const Types<StorageType>::Ptr & pObsValue,
                                  NodeId lower,
                                  NodeId upper)
  {
    NodeId node_id = AddStochasticNode(pDist,
                                       parameters,
                                       Bool(pObsValue),
                                       lower,
                                       upper);

    if (!pObsValue)
      throw LogicError("Can not add stochastic node: observed value pointer is NULL.");

    if (pObsValue->size() != GetNode(node_id).Dim().Length())
      throw LogicError("Can not add stochastic node: observed value size does not match dimension.");

    SetObsValue(node_id, pObsValue, true);

    return node_id;
  }

  void Graph::UpdateDiscreteness(NodeId nodeId,
                                 std::map<Size, NodeId> & stoChildrenByRank)
  {
    Bool discrete_changed = false;
    switch (GetNode(nodeId).GetType())
    {
      case CONSTANT:
      {
        // Change discreteness if necessary
        if (GetDiscrete()[nodeId])
        {
          for (Size i = 0; i < GetValues()[nodeId]->size(); ++i)
          {
            if (!checkInteger((*GetValues()[nodeId])[i]))
            {
              boost::put(boost::vertex_discrete, parentsGraph_, nodeId, false);
              discrete_changed = true;
              break;
            }
          }
        }

        break;
      }

      case LOGICAL:
      {
        // Change discreteness if necessary
        if (GetDiscrete()[nodeId])
        {
          Bool discrete = true;
          const LogicalNode & l_node =
              static_cast<const LogicalNode &>(GetNode(nodeId));
          const Types<NodeId>::Array & parameters = l_node.Parents();

          if (l_node.IsFunction()) // FuncNode
          {
            Flags mask(parameters.size());
            for (Size i = 0; i < parameters.size(); ++i)
              mask[i] = GetDiscrete()[parameters[i]];
            const FuncNode & f_node = static_cast<const FuncNode &>(l_node);
            discrete = f_node.FuncPtr()->IsDiscreteValued(mask);
          }
          else // AggregateNode
          {
            for (Size i = 0; i < parameters.size(); ++i)
            {
              if (!GetDiscrete()[parameters[i]])
              {
                discrete = false;
                break;
              }
            }
          }

          boost::put(boost::vertex_discrete, parentsGraph_, nodeId, discrete);
          discrete_changed = !discrete;
        }
        break;
      }

      case STOCHASTIC:
      {
        // FIXME: lazy copy-paste from AddStochasticNode
        // Check discreteness of parents
        const StochasticNode & s_node =
            static_cast<const StochasticNode &>(GetNode(nodeId));

        const Types<NodeId>::Array & parameters = s_node.Parents();
        Flags mask(parameters.size());
        for (Size i = 0; i < parameters.size(); ++i)
          mask[i] = GetDiscrete()[parameters[i]];
        if (!s_node.PriorPtr()->CheckParamDiscrete(mask))
          throw DistError(s_node.PriorPtr(),
                          "Failed check for discrete-valued parameters");

        // Change discreteness if necessary
        if (GetDiscrete()[nodeId])
        {
          Bool discrete = s_node.PriorPtr()->IsDiscreteValued(mask);
          boost::put(boost::vertex_discrete, parentsGraph_, nodeId, discrete);

          if (discrete)
          {
            // check value discreteness
            for (Size i = 0; i < GetValues()[nodeId]->size(); ++i)
            {
              if (!checkInteger((*GetValues()[nodeId])[i]))
                throw RuntimeError("Can not set observed value: value is not discrete.");
            }
          }
          discrete_changed = !discrete;
        }

        break;

        // FIXME: this can invalidate some assigned samplers ?
      }

      default:
        break;
    }

    if (discrete_changed)
    {
      GraphTypes::ChildIterator it_child, it_child_end;
      boost::tie(it_child, it_child_end) = GetChildren(nodeId);
      for (; it_child != it_child_end; ++it_child)
      {
        if (GetNode(*it_child).GetType() == STOCHASTIC)
        {
          Size rank = GetRanks()[*it_child];
          stoChildrenByRank[rank] = *it_child;
        }
      }
    }
  }

  void Graph::GetLogicalChildrenByRank(NodeId nodeId,
                                       std::map<Size, NodeId> & logicChildrenByRank)
  {
    if (!builtFlag_)
      throw LogicError("GetLogicalChildrenByRank: Graph not built.");

    ChildIterator it_child, it_child_end;
    boost::tie(it_child, it_child_end) = GetChildren(nodeId);
    for (; it_child != it_child_end; ++it_child)
    {
      if (GetNode(*it_child).GetType() == LOGICAL && GetObserved()[*it_child])
      {
        Size rank = GetRanks()[*it_child];
        logicChildrenByRank[rank] = *it_child;
        GetLogicalChildrenByRank(*it_child, logicChildrenByRank);
      }
    }
  }

  void Graph::PopNode()
  {
    if (Empty())
      throw LogicError("Can not pop node: the graph is empty.");

    NodeId last_node_id = GetSize() - 1;

    ChildIterator it_children, it_children_end;
    boost::tie(it_children, it_children_end) = GetChildren(last_node_id);
    if (it_children != it_children_end)
      throw LogicError("Last inserted node can not have children.");

    boost::clear_vertex(last_node_id, parentsGraph_);

    switch (GetNode(last_node_id).GetType())
    {
      case CONSTANT:
        nodesSummaryMap_[CONSTANT] -= 1;
        break;
      case LOGICAL:
        nodesSummaryMap_[LOGICAL] -= 1;
        if (!GetObserved()[last_node_id])
          unobsNodesSummaryMap_[LOGICAL] -= 1;
        break;
      case STOCHASTIC:
        nodesSummaryMap_[STOCHASTIC] -= 1;
        if (!GetObserved()[last_node_id])
          unobsNodesSummaryMap_[STOCHASTIC] -= 1;
        break;
      default:
        throw LogicError("Unknown node type.");
        break;

    }
    boost::remove_vertex(last_node_id, parentsGraph_);

    builtFlag_ = false;
  }

  class TopologicalSortVisitor: public ConstNodeVisitor
  {
  protected:
    typedef TopologicalSortVisitor SelfType;
    typedef Types<SelfType>::Ptr Ptr;

    const Graph & graph_;
    Types<NodeId>::Array & topoSort_;
    Types<Size>::Array & ranks_;
    Size offspringLevel_;
    Size rank_;
    Types<Size>::Array parentsInserted_;

    virtual void visit(const ConstantNode & node)
    {
      if (ranks_[nodeId_] != BIIPS_SIZENA)
        throw LogicError("TopologicalSortVisitor can not visit a constant node twice.");

      topoSort_.push_back(nodeId_);
      ranks_[nodeId_] = rank_++;

      // visit the logical children
      GraphTypes::ChildIterator it_children, it_children_end;
      boost::tie(it_children, it_children_end) = graph_.GetChildren(nodeId_);

      ++offspringLevel_;
      for (; it_children != it_children_end; ++it_children)
      {
        parentsInserted_[*it_children]++;
        graph_.VisitNode(*it_children, *this);
      }
      --offspringLevel_;
    }

    virtual void visit(const StochasticNode & node)
    {
      // avoid visiting twice
      if (ranks_[nodeId_] != BIIPS_SIZENA)
        return;

      // unobserved can not be visited as children
      if (offspringLevel_ && !graph_.GetObserved()[nodeId_])
        return;

      // check if all its parents have been inserted
      if (parentsInserted_[nodeId_] != node.Parents().size())
        return;

      topoSort_.push_back(nodeId_);
      ranks_[nodeId_] = rank_++;

      // visit the logical children
      GraphTypes::ChildIterator it_children, it_children_end;
      boost::tie(it_children, it_children_end) = graph_.GetChildren(nodeId_);

      ++offspringLevel_;
      for (; it_children != it_children_end; ++it_children)
      {
        parentsInserted_[*it_children]++;
        graph_.VisitNode(*it_children, *this);
      }
      --offspringLevel_;
    }

    virtual void visit(const LogicalNode & node)
    {
      if (!offspringLevel_)
        return;

      // avoid visiting twice
      if (ranks_[nodeId_] != BIIPS_SIZENA)
        return;

      if (topoSort_.empty())
        throw LogicError("BuildNodeIdSequenceVisitor can not push LogicalNode in empty node id sequence.");

      // check if all its parents have been inserted
      if (parentsInserted_[nodeId_] != node.Parents().size())
        return;

      topoSort_.push_back(nodeId_);
      ranks_[nodeId_] = rank_++;

      // visit the logical children
      GraphTypes::ChildIterator it_children, it_children_end;
      boost::tie(it_children, it_children_end) = graph_.GetChildren(nodeId_);

      ++offspringLevel_;
      for (; it_children != it_children_end; ++it_children)
      {
        parentsInserted_[*it_children]++;
        graph_.VisitNode(*it_children, *this);
      }
      --offspringLevel_;
    }

  public:

    TopologicalSortVisitor(const Graph & graph,
                           Types<NodeId>::Array & topoSort,
                           Types<Size>::Array & ranks) :
        graph_(graph), topoSort_(topoSort), ranks_(ranks), offspringLevel_(0), rank_(0), parentsInserted_(graph.GetSize(),
                                                                                                          0)
    {
    }
  };

  void Graph::topologicalSort()
  {
    // TODO : optimize
    topoSort_.resize(GetSize());
    for (NodeId id = 0; id < GetSize(); ++id)
      topoSort_[id] = id;
    ranks_.assign(GetSize(), BIIPS_SIZENA);

    if (!dataGraph_)
    {
      Types<NodeId>::Array temp_sort;
      TopologicalSortVisitor topo_vis(*this, temp_sort, ranks_);
      VisitGraph(topo_vis);

      if (temp_sort.size() != GetSize())
        throw LogicError("Topological sort missing nodes.");

      topoSort_.swap(temp_sort);
    }
  }

  void Graph::buildStochasticParents()
  {
    ParentIterator it_direct_parents, it_direct_parents_end;

    stochasticParents_.clear();
    stochasticParents_.resize(GetSize());

    for (Types<NodeId>::ConstIterator it_nodes = topoSort_.begin();
        it_nodes != topoSort_.end(); ++it_nodes)
    {
      boost::tie(it_direct_parents, it_direct_parents_end) =
          boost::adjacent_vertices(*it_nodes, parentsGraph_);
      for (; it_direct_parents != it_direct_parents_end; ++it_direct_parents)
      {
        if (GetNode(*it_direct_parents).GetType() == STOCHASTIC)
          stochasticParents_[*it_nodes].insert(*it_direct_parents);
        else
          stochasticParents_[*it_nodes].insert(stochasticParents_[*it_direct_parents].begin(),
                                               stochasticParents_[*it_direct_parents].end());
      }
    }
  }

  void Graph::buildStochasticChildren()
  {
    ChildIterator it_direct_children, it_direct_children_end;

    stochasticChildren_.clear();
    stochasticChildren_.resize(GetSize());

    for (Types<NodeId>::Array::const_reverse_iterator rit_nodes =
        topoSort_.rbegin(); rit_nodes != topoSort_.rend(); ++rit_nodes)
    {
      boost::tie(it_direct_children, it_direct_children_end) =
          boost::adjacent_vertices(*rit_nodes, childrenGraph_);
      for (; it_direct_children != it_direct_children_end; ++it_direct_children)
      {
        if (GetNode(*it_direct_children).GetType() == STOCHASTIC)
          stochasticChildren_[*rit_nodes].insert(*it_direct_children);
        else
          stochasticChildren_[*rit_nodes].insert(stochasticChildren_[*it_direct_children].begin(),
                                                 stochasticChildren_[*it_direct_children].end());
      }
    }
  }

  struct cycle_detector: public boost::dfs_visitor<>
  {
    cycle_detector(bool& has_cycle) :
        m_has_cycle(has_cycle)
    {
    }

    template<class Edge, class Graph>
    void back_edge(Edge, Graph&)
    {
      m_has_cycle = true;
    }
  protected:
    bool& m_has_cycle;
  };

  Bool Graph::HasCycle() const
  {
    // are there any cycles in the graph?
    Bool has_cycle = false;
    cycle_detector vis(has_cycle);
    boost::depth_first_search(parentsGraph_, boost::visitor(vis));
    return has_cycle;
  }

  void Graph::buildLikelihoodChildren()
  {
    likelihoodChildren_.clear();
    likelihoodChildren_.resize(GetSize());

    for (Types<NodeId>::ConstIterator it_nodes = topoSort_.begin();
        it_nodes != topoSort_.end(); ++it_nodes)
    {
      if (GetNode(*it_nodes).GetType() != STOCHASTIC)
        continue;

      StochasticChildIterator it_offspring, it_offspring_end;
      boost::tie(it_offspring, it_offspring_end) =
          GetStochasticChildren(*it_nodes);
      for (; it_offspring != it_offspring_end; ++it_offspring)
      {
        if (!GetObserved()[*it_offspring])
          continue;
        if (anyUnknownParent(*it_offspring, *it_nodes, *this))
          continue;
        likelihoodChildren_[*it_nodes].insert(*it_offspring);
      }
    }
  }

  void Graph::Build()
  {
    if (builtFlag_)
      throw LogicError("Can not build graph: already built.");

    // check acyclic
    if (HasCycle())
      throw RuntimeError("Can not build graph: has a cycle.");

    topologicalSort();

    if (!dataGraph_)
    {
      buildStochasticParents();
      buildStochasticChildren();
    }

    builtFlag_ = true;

    if (!dataGraph_)
      buildLikelihoodChildren();
  }

  Types<Graph::ParentIterator>::Pair Graph::GetParents(NodeId nodeId) const
  {
    return boost::adjacent_vertices(nodeId, parentsGraph_);
  }

  Types<Graph::ChildIterator>::Pair Graph::GetChildren(NodeId nodeId) const
  {
    return boost::adjacent_vertices(nodeId, childrenGraph_);
  }

  Types<Graph::StochasticParentIterator>::Pair Graph::GetStochasticParents(NodeId nodeId) const
  {
    if (!builtFlag_)
      throw LogicError("Can not access a graph that is not built.");

    return std::make_pair(stochasticParents_.at(nodeId).begin(),
                          stochasticParents_.at(nodeId).end());
  }

  Types<Graph::StochasticChildIterator>::Pair Graph::GetStochasticChildren(NodeId nodeId) const
  {
    if (!builtFlag_)
      throw LogicError("Can not access a graph that is not built.");

    return std::make_pair(stochasticChildren_.at(nodeId).begin(),
                          stochasticChildren_.at(nodeId).end());
  }

  Types<Graph::LikelihoodChildIterator>::Pair Graph::GetLikelihoodChildren(NodeId nodeId) const
  {
    if (!builtFlag_)
      throw LogicError("Can not access a graph that is not built.");
    return std::make_pair(likelihoodChildren_.at(nodeId).begin(),
                          likelihoodChildren_.at(nodeId).end());
  }

  Types<NodeId>::ConstIteratorPair Graph::GetSortedNodes() const
  {
    if (!builtFlag_)
      throw LogicError("Can not access a graph that is not built.");

    return iterRange(topoSort_);
  }

  void Graph::VisitNode(NodeId nodeId, NodeVisitor & vis)
  {
    vis.SetNodeId(nodeId);
    Node & node = *boost::get(boost::vertex_node_ptr, parentsGraph_, nodeId);
    switch (node.GetType())
    {
      case CONSTANT:
        vis.Visit(static_cast<ConstantNode &>(node));
        break;
      case LOGICAL:
        vis.Visit(static_cast<LogicalNode &>(node));
        break;
      case STOCHASTIC:
        vis.Visit(static_cast<StochasticNode &>(node));
        break;
      default:
        break;
    }
  }

  void Graph::VisitNode(NodeId nodeId, ConstNodeVisitor & vis) const
  {
    vis.SetNodeId(nodeId);
    const Node & node = GetNode(nodeId);
    switch (node.GetType())
    {
      case CONSTANT:
        vis.Visit(static_cast<const ConstantNode &>(node));
        break;
      case LOGICAL:
        vis.Visit(static_cast<const LogicalNode &>(node));
        break;
      case STOCHASTIC:
        vis.Visit(static_cast<const StochasticNode &>(node));
        break;
      default:
        break;
    }
  }

  void Graph::VisitGraph(NodeVisitor & vis)
  {
    for (Types<NodeId>::ConstIterator it_nodes = topoSort_.begin();
        it_nodes != topoSort_.end(); ++it_nodes)
    {
      VisitNode(*it_nodes, vis);
    }
  }

  void Graph::VisitGraph(ConstNodeVisitor & vis) const
  {
    for (Types<NodeId>::ConstIterator it_nodes = topoSort_.begin();
        it_nodes != topoSort_.end(); ++it_nodes)
    {
      VisitNode(*it_nodes, vis);
    }
  }

  NodeValues Graph::SampleValues(Rng * pRng) const
  {
    const ConstValuesPropertyMap & values_map = boost::get(boost::vertex_value,
                                                           parentsGraph_);
    const ConstObservedPropertyMap & observed_map =
        boost::get(boost::vertex_observed, parentsGraph_);

    NodeValues node_values(GetSize());
    Flags sampled_flags(GetSize());
    for (Size id=0; id<GetSize(); ++id)
    {
      node_values[id] = values_map[id];
      sampled_flags[id] = observed_map[id];
    }

    DataNodeSampler sample_node_vis(*this);
    sample_node_vis.SetMembers(node_values, sampled_flags, pRng);
    VisitGraph(sample_node_vis);
    return node_values;
  }

  ValArray::Ptr Graph::SampleValue(NodeId nodeId, Rng * pRng, Bool setObsValue)
  {
    if (GetNode(nodeId).GetType() == CONSTANT)
      throw LogicError("Can't sample value: node is constant.");

    const ValuesPropertyMap & values_map = boost::get(boost::vertex_value,
                                                      parentsGraph_);
    const ObservedPropertyMap & observed_map =
        boost::get(boost::vertex_observed, parentsGraph_);

    NodeValues node_values(GetSize());
    Flags sampled_flags(GetSize());
    for (Size id=0; id<GetSize(); ++id)
    {
      node_values[id] = values_map[id];
      sampled_flags[id] = observed_map[id];
    }

    // force the node evaluation by the NodeSampler
    sampled_flags[nodeId] = false;

    DataNodeSampler sample_node_vis(*this);
    sample_node_vis.SetMembers(node_values, sampled_flags, pRng);
    VisitNode(nodeId, sample_node_vis);

    ValArray::Ptr pVal = node_values.at(nodeId);
    if (setObsValue)
      SetObsValue(nodeId, pVal, false);

    return pVal;
  }

  // this function is used to assign an observed value to
  // a stochastic node when doing Particle MCMC
  void Graph::SetObserved(NodeId nodeId)
  {
    boost::put(boost::vertex_observed, parentsGraph_, nodeId, true);
    // allocate memory: temporary NA value
    ValArray::Ptr p_val(new ValArray(GetNode(nodeId).Dim().Length(),
                                     BIIPS_REALNA));
    SetObsValue(nodeId, p_val, false);

    // set logical children observed
    ChildIterator it_child, it_child_end;
    boost::tie(it_child, it_child_end) = GetChildren(nodeId);
    for (; it_child != it_child_end; ++it_child)
    {
      if (GetNode(*it_child).GetType() != LOGICAL)
        continue;

      // check parents are all observed
      Bool all_obs = true;
      ParentIterator it_par, it_par_end;
      boost::tie(it_par, it_par_end) = GetParents(*it_child);
      for (; it_par != it_par_end; ++it_par)
      {
        if (!GetObserved()[*it_par])
        {
          all_obs = false;
          break;
        }
      }

      if (all_obs)
        SetObserved(*it_child);
    }
  }

  void Graph::SetUnobserved(NodeId nodeId)
  {
    if (GetNode(nodeId).GetType() == CONSTANT)
      throw LogicError(String("Can't set node unobserved, node is constant. id: ")
                       + print(nodeId));

    if (!GetObserved()[nodeId])
      return;

    ValArray::Ptr p_val; // null value pointer
    boost::put(boost::vertex_value, parentsGraph_, nodeId, p_val);
    boost::put(boost::vertex_observed, parentsGraph_, nodeId, false);

    // set logical children unobserved
    ChildIterator it_child, it_child_end;
    boost::tie(it_child, it_child_end) = GetChildren(nodeId);
    for (; it_child != it_child_end; ++it_child)
    {
      if (GetNode(*it_child).GetType() != LOGICAL)
        continue;

      SetUnobserved(*it_child);
    }
  }

  void Graph::SetObsValue(NodeId nodeId,
                          const ValArray::Ptr & pObsValue,
                          Bool stochOnly)
  {
    if (stochOnly)
      if (GetNode(nodeId).GetType() != STOCHASTIC)
        throw LogicError(String("Can't set value, node is not stochastic. node id: ")
                         + print(nodeId));

    if (!GetObserved()[nodeId])
      throw LogicError(String("Can't set value, node is not observed. node id: ")
                       + print(nodeId));

    if (stochOnly && pObsValue && GetDiscrete()[nodeId])
    {
      // check discreteness
      for (Size i = 0; i < pObsValue->size(); ++i)
      {
        if (isNA((*pObsValue)[i]))
          throw LogicError("Can not set observed value. value is missing.");
        if (!checkInteger((*pObsValue)[i]))
          throw RuntimeError("Can not set observed value. value is not discrete:" + print((*pObsValue)[i]));
      }
    }
    boost::put(boost::vertex_value, parentsGraph_, nodeId, pObsValue);
  }

  class SetObsValuesVisitor: public NodeVisitor
  {
  protected:
    typedef GraphTypes::ConstNodeValuesMap NodeValuesMap;

    Graph & graph_;
    const NodeValuesMap & nodeValuesMap_;

    virtual void visit(ConstantNode & node)
    {
    }
    virtual void visit(LogicalNode & node)
    {
    }
    virtual void visit(StochasticNode & node)
    {
      if (graph_.GetObserved()[nodeId_])
        graph_.SetObsValue(nodeId_, nodeValuesMap_[nodeId_], true);
    }

  public:

    explicit SetObsValuesVisitor(Graph & graph, const NodeValues & nodeValues) :
        graph_(graph), nodeValuesMap_(nodeValues)
    {
    }
  };

  void Graph::SetObsValues(const NodeValues & nodeValues)
  {
    SetObsValuesVisitor set_obs_vis(*this, nodeValues);
    VisitGraph(set_obs_vis);
  }

  void Graph::PrintGraph(std::ostream & os) const
  {
    boost::print_graph(parentsGraph_);
  }

  Graph::Graph(Bool dataGraph) :
      childrenGraph_(parentsGraph_), builtFlag_(false), dataGraph_(dataGraph)
  {
    nodesSummaryMap_[CONSTANT] = 0;
    nodesSummaryMap_[STOCHASTIC] = 0;
    nodesSummaryMap_[LOGICAL] = 0;
    unobsNodesSummaryMap_[STOCHASTIC] = 0;
    unobsNodesSummaryMap_[LOGICAL] = 0;
  }

  void Graph::PrintGraphviz(std::ostream & os) const
  {
    VertexPropertyWriter vpw(*this);
    PrintGraphviz(os, vpw);
  }

  void VertexPropertyWriter::operator()(std::ostream & out, NodeId id) const
  {
    out << "[label=\"" << label(id) << "\"";
    out << ", shape=\"" << shape(id) << "\"";
    out << ", style=\"" << style(id) << "\"";
    out << ", color=\"" << color(id) << "\"";
    out << ", fillcolor=\"" << "gray" << "\"";

    out << "]";
  }

  class GetLabelVisitor: public ConstNodeVisitor
  {
  protected:
    const Graph & graph_;
    String label_;

    virtual void visit(const ConstantNode & node)
    {
      label_.clear();
    }

    virtual void visit(const StochasticNode & node)
    {
      label_ = node.PriorName() + "\\n";
    }

    virtual void visit(const LogicalNode & node)
    {
      label_ = node.FuncName() + "\\n";
    }

  public:

    const String & GetLabel() const
    {
      return label_;
    }

    explicit GetLabelVisitor(const Graph & graph) :
        graph_(graph)
    {
    }
  };

  String VertexPropertyWriter::label(NodeId id) const
  {
    GetLabelVisitor get_label_vis(graph_);
    graph_.VisitNode(id, get_label_vis);
    String ans = get_label_vis.GetLabel();

    std::ostringstream oss;
    oss << id;
    ans += oss.str();

    return ans;
  }

  String VertexPropertyWriter::shape(NodeId id) const
  {
    String ans;
    switch (graph_.GetNode(id).GetType())
    {
      case CONSTANT:
        ans = "box";
        break;
      case LOGICAL:
        ans = "box";
        break;
      case STOCHASTIC:
        ans = "ellipse";
        break;
      default:
        break;
    }
    return ans;
  }

  String VertexPropertyWriter::color(NodeId id) const
  {
    String ans;
    switch (graph_.GetNode(id).GetType())
    {
      case CONSTANT:
        ans += "gray";
        break;
      case LOGICAL:
        break;
      case STOCHASTIC:
        break;
      default:
        break;
    }
    return ans;
  }

  String VertexPropertyWriter::style(NodeId id) const
  {
    String ans;
    switch (graph_.GetNode(id).GetType())
    {
      case CONSTANT:
        break;
      case LOGICAL:
        ans = "rounded";
        break;
      case STOCHASTIC:
        break;
      default:
        break;
    }

    if (graph_.GetObserved()[id])
    {
      ans += ", filled";
    }

    return ans;
  }

  const Types<Size>::Array & Graph::GetRanks() const
  {
    if (!builtFlag_)
      throw LogicError("Can not access a graph that is not built.");
    return ranks_;
  }
}
