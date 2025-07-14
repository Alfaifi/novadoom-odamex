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

#include "i_system.h" // needed for WORD
#include "m_stacktrace.h"
#include <cstddef>
#include <functional>
#include <unordered_map>
#include <vector>
#include <typeinfo>

template <class ObjType, class IdxType>
class DoomObjectContainer;

//----------------------------------------------------------------------------------------------
// DoomObjectContainer replaces the global doom object pointers (states, mobjinfo,
// sprnames) with multi-use objects that can handle negative indices. It also
// auto-resizes, similar to vector, and provides a way to get the size and capacity.
// Existing code cannot rely on an index being greater than the number of types now
// because dehacked does not enforce contiguous indices i.e. frame 405 could jump to frame
// 1055. Because of this, iterators should be used when traversing the container.
//----------------------------------------------------------------------------------------------

template <class ObjType, class IdxType = int32_t>
class DoomObjectContainer
{

	typedef std::unordered_map<IdxType, ObjType*> LookupTable;
	typedef std::vector<ObjType> DoomObjectContainerData;
	typedef DoomObjectContainer<ObjType, IdxType> DoomObjectContainerType;

	DoomObjectContainerData container;
	LookupTable lookup_table;

  public:
	typedef typename DoomObjectContainerData::reference ObjReference;
	typedef typename DoomObjectContainerData::const_reference ConstObjReference;
	typedef typename LookupTable::iterator iterator;
	typedef typename LookupTable::const_iterator const_iterator;

	explicit DoomObjectContainer();
	explicit DoomObjectContainer(size_t count);
	~DoomObjectContainer();

	ObjReference operator[](int);
	ConstObjReference operator[](int) const;
	bool operator==(const ObjType* p) const;
	bool operator!=(const ObjType* p) const;
	// convert to ObjType* to allow pointer arithmetic
	operator const ObjType*() const;
	operator ObjType*();
	// direct access similar to STL data()
	ObjType* data();
	const ObjType* data() const;

	size_t capacity() const;
	size_t size() const;
	void clear();
	void resize(size_t count);
	void reserve(size_t new_cap);
	void insert(const ObjType& obj, IdxType idx);
	void append(const DoomObjectContainerType& dObjContainer);

	iterator begin();
	iterator end();
	const_iterator cbegin();
	const_iterator cend();
	iterator find(IdxType idx);
	const_iterator find(IdxType idx) const;
	bool contains(IdxType idx) const;

	friend ObjType operator-(ObjType obj, DoomObjectContainerType& container);
	friend ObjType operator+(DoomObjectContainerType& container, WORD ofs);
};

//----------------------------------------------------------------------------------------------

// Construction and Destruction

template <class ObjType, class IdxType>
DoomObjectContainer<ObjType, IdxType>::DoomObjectContainer() {}

template <class ObjType, class IdxType>
DoomObjectContainer<ObjType, IdxType>::DoomObjectContainer(size_t count)
{
	this->container.reserve(count);
}

template <class ObjType, class IdxType>
DoomObjectContainer<ObjType, IdxType>::~DoomObjectContainer()
{
	clear();
}

// Operators

template <class ObjType, class IdxType>
typename DoomObjectContainer<ObjType, IdxType>::ObjReference DoomObjectContainer<
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
typename DoomObjectContainer<ObjType, IdxType>::ConstObjReference DoomObjectContainer<
    ObjType, IdxType>::operator[](int idx) const
{
    const_iterator it = this->lookup_table.find(idx);
    if (it == this->end())
    {
    	I_Error("Attempt to access invalid {} at idx {}\n{}", typeid(ObjType).name(), idx, M_GetStacktrace());
    }
    return it->second;
}

template <class ObjType, class IdxType>
bool DoomObjectContainer<ObjType, IdxType>::operator==(const ObjType* p) const
{
	return this->container().data() == p;
}

template <class ObjType, class IdxType>
bool DoomObjectContainer<ObjType, IdxType>::operator!=(const ObjType* p) const
{
	return this->container().data() != p;
}

template <class ObjType, class IdxType>
DoomObjectContainer<ObjType, IdxType>::operator const ObjType*() const
{
	return const_cast<ObjType>(this->container.data());
}
template <class ObjType, class IdxType>
DoomObjectContainer<ObjType, IdxType>::operator ObjType*()
{
	return this->container.data();
}

template <class ObjType, class IdxType>
ObjType operator-(ObjType obj, DoomObjectContainer<ObjType, IdxType>& container)
{
	return obj - container.data();
}
template <class ObjType, class IdxType>
ObjType operator+(DoomObjectContainer<ObjType, IdxType>& container, WORD ofs)
{
	return container.data() + ofs;
}

// data functions for quicker access to all objects presently stored

template <class ObjType, class IdxType>
ObjType* DoomObjectContainer<ObjType, IdxType>::data()
{
	return this->container.data();
}

template <class ObjType, class IdxType>
const ObjType* DoomObjectContainer<ObjType, IdxType>::data() const
{
	return this->container.data();
}

// Capacity and Size

template <class ObjType, class IdxType>
size_t DoomObjectContainer<ObjType, IdxType>::size() const
{
	return this->container.size();
}

template <class ObjType, class IdxType>
size_t DoomObjectContainer<ObjType, IdxType>::capacity() const
{
	return this->container.capacity();
}

template <class ObjType, class IdxType>
void DoomObjectContainer<ObjType, IdxType>::clear()
{
	// for (auto& obj : this->container)
	// {
	// 	this->ff(obj);
	// }
	this->container.clear();
	this->lookup_table.clear();
}

// Allocation changes

template <class ObjType, class IdxType>
void DoomObjectContainer<ObjType, IdxType>::resize(size_t count)
{
	this->container.resize(count);
}

template <class ObjType, class IdxType>
void DoomObjectContainer<ObjType, IdxType>::reserve(size_t new_cap)
{
	this->container.reserve(new_cap);
}

// Insertion

template <class ObjType, class IdxType>
void DoomObjectContainer<ObjType, IdxType>::insert(const ObjType& obj, IdxType idx)
{
	this->container.insert(this->container.end(), obj);
	this->lookup_table[idx] = &container.back();
}

// TODO: more of a copy construct in a sense
template <class ObjType, class IdxType>
void DoomObjectContainer<ObjType, IdxType>::append(
    const DoomObjectContainer<ObjType, IdxType>& dObjContainer)
{
	for (DoomObjectContainerType::iterator it = dObjContainer.lookup_table.begin();
	     it != dObjContainer.lookup_table.end(); ++it)
	{
		IdxType idx = it->first;
		ObjType obj = it->second;
		this->insert(idx, obj);
	}
}

// Iterators

template <class ObjType, class IdxType>
typename DoomObjectContainer<ObjType, IdxType>::iterator DoomObjectContainer<ObjType, IdxType>::begin()
{
	return lookup_table.begin();
}

template <class ObjType, class IdxType>
typename DoomObjectContainer<ObjType, IdxType>::iterator DoomObjectContainer<ObjType, IdxType>::end()
{
	return lookup_table.end();
}

template <class ObjType, class IdxType>
typename DoomObjectContainer<ObjType, IdxType>::const_iterator DoomObjectContainer<ObjType, IdxType>::cbegin()
{
	return lookup_table.begin();
}

template <class ObjType, class IdxType>
typename DoomObjectContainer<ObjType, IdxType>::const_iterator DoomObjectContainer<ObjType, IdxType>::cend()
{
	return lookup_table.end();
}

// Lookup

template <class ObjType, class IdxType>
typename DoomObjectContainer<ObjType, IdxType>::iterator DoomObjectContainer<
    ObjType, IdxType>::find(IdxType idx)
{
	typename LookupTable::iterator it = this->lookup_table.find(idx);
	if (it != this->lookup_table.end())
	{
		return it;
	}
	return this->lookup_table.end();
}

template <class ObjType, class IdxType>
typename DoomObjectContainer<ObjType, IdxType>::const_iterator DoomObjectContainer<
    ObjType, IdxType>::find(IdxType idx) const
{
	typename LookupTable::iterator it = this->lookup_table.find(idx);
	if (it != this->lookup_table.end())
	{
		return it;
	}
	return this->lookup_table.end();
}

template<class ObjType, class IdxType>
bool DoomObjectContainer<ObjType, IdxType>::contains(IdxType idx) const
{
	return this->find(idx) != this->end();
}

//----------------------------------------------------------------------------------------------
