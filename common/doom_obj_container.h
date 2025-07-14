// Emacs style mode select   -*- C++ -*-
//-----------------------------------------------------------------------------
//
// $Id$
//
// Copyright (C) 2006-2025 by The Odamex Team.
// Copyright (C) 2024-2025 by Christian Bernard.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// DESCRIPTION:
//  DoomObjectContainer - replaces arrays for sprnames, mobjinfo, states, etc
//
//-----------------------------------------------------------------------------

//----------------------------------------------------------------------------------------------
// odamex enum definitions with negative indices (similar to id24 specification) are in
// info.h using negative indices prevents overriding during dehacked (though id24 allows
// this)
//
// id24 allows 0x80000000-0x8FFFFFFF (abbreviated as 0x8000-0x8FFF) for negative indices
// for source port implementation id24 spec no longer uses enum to define the indices for
// doom objects, but until that is implemented enums will continue to be used
//----------------------------------------------------------------------------------------------

#pragma once

#include "i_system.h"
#include "version.h"
#include "m_stacktrace.h"
#include <nonstd/span.hpp>
#include <functional>
#include <unordered_map>
#include <vector>
#include <typeinfo>

//----------------------------------------------------------------------------------------------
// DoomObjectContainer is a wrapper around std::unordered_map that provides an operator[]
// that cleanly errors with a helpful message when attempts to access a nonexistent element
// are made, as well as insertionmethods tailored to the types of structures the default objects
// are definied within
//----------------------------------------------------------------------------------------------

template <class ObjType, class IdxType = int32_t>
class DoomObjectContainer
{

	typedef std::unordered_map<IdxType, ObjType> LookupTable;
	typedef DoomObjectContainer<ObjType, IdxType> DoomObjectContainerType;

	LookupTable lookup_table;

  public:
	typedef typename LookupTable::iterator iterator;
	typedef typename LookupTable::const_iterator const_iterator;

	explicit DoomObjectContainer();
	explicit DoomObjectContainer(size_t count);
	~DoomObjectContainer();
	DoomObjectContainer& operator=(const DoomObjectContainer& other) = default;
	DoomObjectContainer& operator=(DoomObjectContainer&& other) = default;

	ObjType& operator[](int);
	const ObjType& operator[](int) const;

	size_t capacity() const;
	size_t size() const;
	void clear();
	void reserve(size_t new_cap);
	ObjType& insert(const ObjType& obj, IdxType idx);
	void insert(nonstd::span<ObjType> objs, IdxType start_idx);
	template <typename T = ObjType, typename = std::enable_if_t<std::is_same_v<T, std::string>>>
	void insert(nonstd::span<const char*> objs, IdxType start_idx);
	void append(const DoomObjectContainerType& dObjContainer);

	iterator begin();
	iterator end();
	const_iterator begin() const;
	const_iterator end() const;
	const_iterator cbegin() const;
	const_iterator cend() const;
	iterator find(IdxType idx);
	const_iterator find(IdxType idx) const;
	bool contains(IdxType idx) const;
};

//----------------------------------------------------------------------------------------------

// Construction and Destruction

template <class ObjType, class IdxType>
DoomObjectContainer<ObjType, IdxType>::DoomObjectContainer() {}

template <class ObjType, class IdxType>
DoomObjectContainer<ObjType, IdxType>::DoomObjectContainer(size_t count)
{
	this->lookup_table.reserve(count);
}

template <class ObjType, class IdxType>
DoomObjectContainer<ObjType, IdxType>::~DoomObjectContainer()
{
	clear();
}

// Operators

template <class ObjType, class IdxType>
ObjType& DoomObjectContainer<
    ObjType, IdxType>::operator[](int idx)
{
	iterator it = this->lookup_table.find(idx);
    if (it == this->end())
    {
	    I_Error("Attempt to access invalid {} at idx {}\n{}", typeid(ObjType).name(), idx, M_GetStacktrace());
    }
    return it->second;
}

template <class ObjType, class IdxType>
const ObjType& DoomObjectContainer<
    ObjType, IdxType>::operator[](int idx) const
{
    const_iterator it = this->lookup_table.find(idx);
    if (it == this->end())
    {
    	I_Error("Attempt to access invalid {} at idx {}\n{}", typeid(ObjType).name(), idx, M_GetStacktrace());
    }
    return it->second;
}

// Capacity and Size

template <class ObjType, class IdxType>
size_t DoomObjectContainer<ObjType, IdxType>::size() const
{
	return this->lookup_table.size();
}

template <class ObjType, class IdxType>
void DoomObjectContainer<ObjType, IdxType>::clear()
{
	this->lookup_table.clear();
}

// Allocation changes

template <class ObjType, class IdxType>
void DoomObjectContainer<ObjType, IdxType>::reserve(size_t new_cap)
{
	this->lookup_table.reserve(new_cap);
}

// Insertion

template <class ObjType, class IdxType>
ObjType& DoomObjectContainer<ObjType, IdxType>::insert(const ObjType& obj, IdxType idx)
{
	return this->lookup_table[idx] = obj;
}

template <class ObjType, class IdxType>
void DoomObjectContainer<ObjType, IdxType>::insert(nonstd::span<ObjType> objs, IdxType start_idx)
{
	IdxType idx = start_idx;
	for (const auto& obj : objs)
		this->lookup_table[idx++] = obj;
}

template <class ObjType, class IdxType>
template <typename T, typename>
void DoomObjectContainer<ObjType, IdxType>::insert(nonstd::span<const char*> objs, IdxType start_idx)
{
	IdxType idx = start_idx;
	for (const auto& obj : objs)
		this->lookup_table[idx++] = obj == nullptr ? "" : obj;
}

// TODO: more of a copy construct in a sense
template <class ObjType, class IdxType>
void DoomObjectContainer<ObjType, IdxType>::append(
    const DoomObjectContainer<ObjType, IdxType>& dObjContainer)
{
	for (const auto& [idx, obj] : dObjContainer.lookup_table)
	{
		this->insert(*obj, idx);
	}
}

// Iterators

template <class ObjType, class IdxType>
typename DoomObjectContainer<ObjType, IdxType>::iterator DoomObjectContainer<ObjType, IdxType>::begin()
{
	return this->lookup_table.begin();
}

template <class ObjType, class IdxType>
typename DoomObjectContainer<ObjType, IdxType>::iterator DoomObjectContainer<ObjType, IdxType>::end()
{
	return this->lookup_table.end();
}

template <class ObjType, class IdxType>
typename DoomObjectContainer<ObjType, IdxType>::const_iterator DoomObjectContainer<ObjType, IdxType>::begin() const
{
	return this->lookup_table.begin();
}

template <class ObjType, class IdxType>
typename DoomObjectContainer<ObjType, IdxType>::const_iterator DoomObjectContainer<ObjType, IdxType>::end() const
{
	return this->lookup_table.end();
}

template <class ObjType, class IdxType>
typename DoomObjectContainer<ObjType, IdxType>::const_iterator DoomObjectContainer<ObjType, IdxType>::cbegin() const
{
	return this->lookup_table.begin();
}

template <class ObjType, class IdxType>
typename DoomObjectContainer<ObjType, IdxType>::const_iterator DoomObjectContainer<ObjType, IdxType>::cend() const
{
	return this->lookup_table.end();
}

// Lookup

template <class ObjType, class IdxType>
typename DoomObjectContainer<ObjType, IdxType>::iterator DoomObjectContainer<
    ObjType, IdxType>::find(IdxType idx)
{
	return this->lookup_table.find(idx);
}

template <class ObjType, class IdxType>
typename DoomObjectContainer<ObjType, IdxType>::const_iterator DoomObjectContainer<
    ObjType, IdxType>::find(IdxType idx) const
{
	return this->lookup_table.find(idx);
}

template<class ObjType, class IdxType>
bool DoomObjectContainer<ObjType, IdxType>::contains(IdxType idx) const
{
	return this->find(idx) != this->end();
}

//----------------------------------------------------------------------------------------------
