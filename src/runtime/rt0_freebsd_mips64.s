// Copyright 2015 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// +build freebsd
// +build mips64

#include "textflag.h"

TEXT _rt0_mips64_freebsd(SB),NOSPLIT,$0
	JMP	_main<>(SB)

TEXT _rt0_mips64le_freebsd(SB),NOSPLIT,$0
	JMP	_main<>(SB)

TEXT _main<>(SB),NOSPLIT|NOFRAME,$0
	// Pointer to beginning of stack info in R4
	ADDV	$8, R4, R5 // argv
	MOVV	0(R4), R4 // argc
	JMP	main(SB)

TEXT main(SB),NOSPLIT|NOFRAME,$0
	// in external linking, glibc jumps to main with argc in R4
	// and argv in R5

	// initialize REGSB = PC&0xffffffff00000000
	BGEZAL	R0, 1(PC)
	SRLV	$32, R31, RSB
	SLLV	$32, RSB

	MOVV	$runtime·rt0_go(SB), R1
	JMP	(R1)
