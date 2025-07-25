//===-- lib/runtime/edit-input.h --------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef FLANG_RT_RUNTIME_EDIT_INPUT_H_
#define FLANG_RT_RUNTIME_EDIT_INPUT_H_

#include "flang-rt/runtime/format.h"
#include "flang-rt/runtime/io-stmt.h"
#include "flang/Decimal/decimal.h"

namespace Fortran::runtime::io {

RT_OFFLOAD_API_GROUP_BEGIN

RT_API_ATTRS bool EditIntegerInput(
    IoStatementState &, const DataEdit &, void *, int kind, bool isSigned);

template <int KIND>
RT_API_ATTRS bool EditRealInput(IoStatementState &, const DataEdit &, void *);

RT_API_ATTRS bool EditLogicalInput(
    IoStatementState &, const DataEdit &, bool &);

template <typename CHAR>
RT_API_ATTRS bool EditCharacterInput(
    IoStatementState &, const DataEdit &, CHAR *, std::size_t);

extern template RT_API_ATTRS bool EditRealInput<2>(
    IoStatementState &, const DataEdit &, void *);
extern template RT_API_ATTRS bool EditRealInput<3>(
    IoStatementState &, const DataEdit &, void *);
extern template RT_API_ATTRS bool EditRealInput<4>(
    IoStatementState &, const DataEdit &, void *);
extern template RT_API_ATTRS bool EditRealInput<8>(
    IoStatementState &, const DataEdit &, void *);
extern template RT_API_ATTRS bool EditRealInput<10>(
    IoStatementState &, const DataEdit &, void *);
// TODO: double/double
extern template RT_API_ATTRS bool EditRealInput<16>(
    IoStatementState &, const DataEdit &, void *);

extern template RT_API_ATTRS bool EditCharacterInput(
    IoStatementState &, const DataEdit &, char *, std::size_t);
extern template RT_API_ATTRS bool EditCharacterInput(
    IoStatementState &, const DataEdit &, char16_t *, std::size_t);
extern template RT_API_ATTRS bool EditCharacterInput(
    IoStatementState &, const DataEdit &, char32_t *, std::size_t);

RT_OFFLOAD_API_GROUP_END

} // namespace Fortran::runtime::io
#endif // FLANG_RT_RUNTIME_EDIT_INPUT_H_
