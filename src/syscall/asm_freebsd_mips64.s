// Copyright 2019 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// +build freebsd
// +build mips64 mips64le

#include "textflag.h"
#include "funcdata.h"

//
// System call support for Mips64, FreeBSD
// XXX-AM: This is essentially the same as linux mips64?	
//

// func Syscall(trap, a1, a2, a3 uintptr) (r1, r2, errno uintptr);
// func Syscall6(trap, a1, a2, a3, a4, a5, a6 uintptr) (r1, r2, errno uintptr);
// func Syscall9(trap, a1, a2, a3, a4, a5, a6, a7, a8, a9 uintptr) (r1, r2, errno uintptr)

TEXT	·Syscall(SB),NOSPLIT,$0-56
	JAL runtime·entersyscall(SB)
	MOVV	trap+0(FP), R2	// v0 syscall num
	MOVV	a1+8(FP), R4	// a0
	MOVV	a2+16(FP), R5	// a1
	MOVV	a3+24(FP), R6	// a2
	MOVV	R0, R7		// a3
	MOVV	R0, R8		// a4
	MOVV	R0, R9		// a5
	SYSCALL
	BEQ	R7, ok		// check for error
	MOVV	$-1, R1
	MOVV	R1, r1+32(FP)	// return val 1
	MOVV	R0, r2+40(FP)	// return val 2
	MOVV	R2, err+48(FP)	// errno
	JAL runtime·exitsyscall(SB)
	RET
ok:
	MOVV	R2, r1+32(FP)	// return val 1
	MOVV	R3, r2+40(FP)	// return val 2
	MOVV	R0, err+48(FP)	// errno
	JAL runtime·exitsyscall(SB)
	RET

TEXT	·Syscall6(SB),NOSPLIT,$0-80
	JAL runtime·entersyscall(SB)
	MOVV	trap+0(FP), R2	// v0
	MOVV	a1+8(FP), R4	// a0
	MOVV	a2+16(FP), R5	// a1
	MOVV	a3+24(FP), R6	// a2
	MOVV	a4+32(FP), R7	// a3
	MOVV	a5+40(FP), R8	// a4
	MOVV	a6+48(FP), R9	// a5
	SYSCALL
	BEQ	R7, ok6
	MOVV	$-1, R1
	MOVV	R1, r1+56(FP)	// return val 1
	MOVV	R0, r2+64(FP)	// return val 2
	MOVV	R2, err+72(FP)	// errno
	JAL runtime·exitsyscall(SB)
	RET
ok6:
	MOVV	R2, r1+56(FP)	// return val 1
	MOVV	R3, r2+64(FP)	// return val 2
	MOVV	R0, err+72(FP)	// errno
	JAL runtime·exitsyscall(SB)
	RET

TEXT	·RawSyscall(SB),NOSPLIT,$0-56
	MOVV	trap+0(FP), R2	// v0 syscall num
	MOVV	a1+8(FP), R4	// a0
	MOVV	a2+16(FP), R5	// a1
	MOVV	a3+24(FP), R6	// a2
	MOVV	R0, R7		// a3
	MOVV	R0, R8		// a4
	MOVV	R0, R9		// a5
	SYSCALL
	BEQ	R7, okraw	// check for error
	MOVV	$-1, R1
	MOVV	R1, r1+32(FP)	// return val 1
	MOVV	R0, r2+40(FP)	// return val 2
	MOVV	R2, err+48(FP)	// errno
	RET
okraw:
	MOVV	R2, r1+32(FP)	// return val 1
	MOVV	R3, r2+40(FP)	// return val 2
	MOVV	R0, err+48(FP)	// errno
	RET

TEXT	·RawSyscall6(SB),NOSPLIT,$0-80
	MOVV	trap+0(FP), R2	// v0
	MOVV	a1+8(FP), R4	// a0
	MOVV	a2+16(FP), R5	// a1
	MOVV	a3+24(FP), R6	// a2
	MOVV	a4+32(FP), R7	// a3
	MOVV	a5+40(FP), R8	// a4
	MOVV	a6+48(FP), R9	// a5
	SYSCALL
	BEQ	R7, okraw6
	MOVV	$-1, R1
	MOVV	R1, r1+56(FP)	// return val 1
	MOVV	R0, r2+64(FP)	// return val 2
	MOVV	R2, err+72(FP)	// errno
	RET
okraw6:
	MOVV	R2, r1+56(FP)	// return val 1
	MOVV	R3, r2+64(FP)	// return val 2
	MOVV	R0, err+72(FP)	// errno
	RET

TEXT ·Syscall9(SB),NOSPLIT,$8-104
	NO_LOCAL_POINTERS
	JAL	runtime·entersyscall(SB)
	MOVV	trap+0(FP), R2	// v0
	MOVV	a1+8(FP), R4	// a0
	MOVV	a2+16(FP), R5	// a1
	MOVV	a3+24(FP), R6	// a2
	MOVV	a4+32(FP), R7	// a3
	MOVV	a5+40(FP), R8	// a4
	MOVV	a6+48(FP), R9	// a5
	MOVV	a7+56(FP), R10	// a6
	MOVV	a8+64(FP), R11	// a7
	MOVV	a9+72(FP), R1	// a9 as stack arg
	MOVV	R1, 16(R29)
	SYSCALL
	BEQ	R7, ok9
	MOVV	$-1, R1
	MOVW	R1, r1+80(FP)	// r1
	MOVW	R0, r2+88(FP)	// r2
	MOVW	R2, err+96(FP)	// errno
	JAL	runtime·exitsyscall(SB)
	RET
ok9:
	MOVW	R2, r1+80(FP)	// r1
	MOVW	R3, r2+88(FP)	// r2
	MOVW	R0, err+96(FP)	// errno
	JAL	runtime·exitsyscall(SB)
	RET
