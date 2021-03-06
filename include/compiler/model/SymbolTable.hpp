/*! \file SymbolTable.hpp
 * COPY: Adapted from JAGS SymTab class
 */

#ifndef BIIPS_SYMBOLTABLE_HPP_
#define BIIPS_SYMBOLTABLE_HPP_

#include "common/Types.hpp"
#include "model/NodeArray.hpp"

#include <map>

namespace Biips
{

  class Model;

  class SymbolTable
  {
  protected:
    Model & model_;
    std::map<String, NodeArray::Ptr> nodeArraysMap_;

    NodeArray & getNodeArray(const String & name)
    {
      return *(nodeArraysMap_.at(name));
    }

    void update_children(const std::map<Size, NodeId> & logicChildrenByRank,
                         std::map<Size, NodeId> & stoChildrenByRank,
                         Bool mcmc);
  public:
    explicit SymbolTable(Model & model);

    void AddVariable(const String & name, const DimArray & dim);

    void InsertNode(NodeId nodeId,
                    const String & name,
                    const IndexRange & range);

    const NodeArray & GetNodeArray(const String & name) const
    {
      return *(nodeArraysMap_.at(name));
    }

    NodeId GetNodeArraySubset(const String & name,
                              const IndexRange & subsetRange, Bool dropped = false) const
    {
      return nodeArraysMap_.at(name)->GetSubset(subsetRange, dropped);
    }

    Bool Contains(const String & name) const
    {
      return nodeArraysMap_.count(name);
    }

    Bool Contains(NodeId nodeId) const;

    const String & GetVariableName(NodeId nodeId) const;

    String GetName(NodeId nodeId) const;

    Size GetSize() const
    {
      return nodeArraysMap_.size();
    }

    Bool Empty() const
    {
      return nodeArraysMap_.empty();
    }

    /**
     * Creates constant nodes in all the NodeArrays in symbol table
     * with values from the given data table.
     *
     * @param dataMap Data table from which values will be read.
     *
     * @see NodeArray#SetData
     */
    void WriteData(const std::map<String, MultiArray> & dataMap);

    Bool ChangeData(const String & variable,
                    const IndexRange & range,
                    const MultiArray & data,
                    Bool & set_observed_nodes,
                    Bool mcmc);

    void SampleData(const String & variable,
                    const IndexRange & range,
                    MultiArray & data,
                    Rng * pRng);

    void RemoveData(const String & variable, const IndexRange & range);

    /**
     * Reads the current value of selected nodes in the symbol table and
     * writes the result to the data table.
     *
     * @param data_table Data table to which results will be written.
     * New entries will be created for the selected nodes.  However, a
     * new entry is not created if, in the symbol table, all nodes
     * corresponding to the selection are missing. Existing entries in
     * the data table will be overwritten.
     */
    void ReadData(std::map<String, MultiArray> & dataMap) const;
  };

}

#endif /* BIIPS_SYMBOLTABLE_HPP_ */
