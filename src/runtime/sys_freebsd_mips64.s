// Copyright 2012 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//
// System calls and other sys.stuff for ARM, FreeBSD
// /usr/src/sys/kern/syscalls.master for syscall numbers.
//

#include "go_asm.h"
#include "go_tls.h"
#include "textflag.h"

// for n64, we do not support n32 at this time
#define SYS_BASE 0x0

#define SYS_exit (SYS_BASE + 1)
#define SYS_read (SYS_BASE + 3)
#define SYS_write (SYS_BASE + 4)
#define SYS_open (SYS_BASE + 5)
#define SYS_close (SYS_BASE + 6)
#define SYS_getpid (SYS_BASE + 20)
#define SYS_kill (SYS_BASE + 37)
#define SYS_sigaltstack (SYS_BASE + 53)
#define SYS_munmap (SYS_BASE + 73)
#define SYS_madvise (SYS_BASE + 75)
#define SYS_setitimer (SYS_BASE + 83)
#define SYS_fcntl (SYS_BASE + 92)
#define SYS___sysctl (SYS_BASE + 202)
#define SYS_nanosleep (SYS_BASE + 240)
#define SYS_clock_gettime (SYS_BASE + 232)
#define SYS_sched_yield (SYS_BASE + 331)
#define SYS_sigprocmask (SYS_BASE + 340)
#define SYS_kqueue (SYS_BASE + 362)
#define SYS_kevent (SYS_BASE + 363)
#define SYS_sigaction (SYS_BASE + 416)
#define SYS_thr_exit (SYS_BASE + 431)
#define SYS_thr_self (SYS_BASE + 432)
#define SYS_thr_kill (SYS_BASE + 433)
#define SYS__umtx_op (SYS_BASE + 454)
#define SYS_thr_new (SYS_BASE + 455)
#define SYS_mmap (SYS_BASE + 477)
#define SYS_cpuset_getaffinity (SYS_BASE + 487)

// func sys_umtx_op(obj *byte, op int32, val uint32, uaddr1 *byte, uaddr2 *byte) (int32)
TEXT runtime·sys_umtx_op(SB),NOSPLIT,$0
	MOVV	obj+0(FP), R4		// a0
	MOVW	op+8(FP), R5		// a1
	MOVW	val+12(FP), R6		// a2
	MOVV	uaddr1+16(FP), R7	// a3
	MOVV	uaddr2+24(FP), R8	// a4
	MOVV	$SYS__umtx_op, R2	// v0
	SYSCALL
	MOVW	R2, ret+40(FP)
	RET

// func thr_new(param *Thr_param, param_size int32) (int32)
TEXT runtime·thr_new(SB),NOSPLIT,$0
	MOVV	param+0(FP), R4		// a0
	MOVW	size+8(FP), R5		// a1
	MOVV	$SYS_thr_new, R2	// v0
	SYSCALL
	MOVW	R2, ret+16(FP)
	RET

// Set up go thread local state
// thr_start is set as start_func of struct thr_param, it entered by
// the kernel with args (struct *m mp)
TEXT runtime·thr_start(SB),NOSPLIT,$0
	// set up g
	MOVV m_g0(R4), g
	MOVV R4, g_m(g)
	JAL runtime·emptyfunc(SB) // fault if stack check is wrong
	JAL runtime·mstart(SB)

	MOVW $2, R8  // crash (not reached)
	MOVW R8, (R8)
	RET

// func exit(code int32)
TEXT runtime·exit(SB),NOSPLIT|NOFRAME,$0
	MOVW	code+0(FP), R4	// a0
	MOVV	$SYS_exit, R2	// v0
	SYSCALL
	RET

// func exitThread(wait *uint32)
TEXT runtime·exitThread(SB),NOSPLIT,$0-4
	MOVV	wait+0(FP), R1
	MOVW	$0, R2
	SYNC
	MOVW	R2, (R1)
	SYNC
	MOVV	$0, R4	// a0 *state = NULL
	MOVV	$SYS_thr_exit, R2	// v0
	SYSCALL
	JMP	0(PC)

// func open(path *byte, flags int32, mode int32) (int32)
TEXT runtime·open(SB),NOSPLIT|NOFRAME,$0
	MOVV	path+0(FP), R4	// a0
	MOVW	flags+8(FP), R5	// a1
	MOVW	mode+16(FP), R6	// a2
	MOVV	$SYS_open, R2	// v0
	SYSCALL
	BEQ	R7, 2(PC)
	MOVW	$-1, R2
	MOVW	R2, ret+24(FP)
	RET

// func read(fd int32, buf *byte, nbyte uint32) (int32)
TEXT runtime·read(SB),NOSPLIT|NOFRAME,$0
	MOVW	fd+0(FP), R4	// a0
	MOVV	buf+8(FP), R5	// a1
	MOVW	nbyte+16(FP), R6// a2
	MOVV	$SYS_read, R2	// v0
	SYSCALL
	BEQ	R7, 2(PC)
	MOVW	$-1, R2
	MOVW	R2, ret+24(FP)
	RET

// func write(fd int64, buf *byte, nbyte uint32) (int32)
TEXT runtime·write(SB),NOSPLIT|NOFRAME,$0
	MOVV	fd+0(FP), R4	// a0
	MOVV	buf+8(FP), R5	// a1
	MOVW	nbyte+16(FP), R6// a2
	MOVV	$SYS_write, R2	// v0
	SYSCALL
	BEQ	R7, 2(PC)
	MOVW	$-1, R2
	MOVW	R2, ret+24(FP)
	RET

// func close(fd int) (int32)
TEXT runtime·closefd(SB),NOSPLIT|NOFRAME,$0
	MOVW	fd+0(FP), R4	// a0
	MOVV	$SYS_close, R2	// v0
	SYSCALL
	BEQ	R7, 2(PC)
	MOVW	$-1, R2
	MOVW	R2, ret+8(FP)
	RET

// kill current thread
TEXT runtime·raise(SB),NOSPLIT,$8
	// thr_self(&0(R29))
	MOVW $0(R29), R4		// a0 id = &0(R29)
	MOVW $SYS_thr_self, R2	// v0
	SYSCALL
	// thr_kill(self, SIGPIPE)
	MOVW 0(R29), R4		// a0 id
	MOVW sig+0(FP), R5	// a1 signal
	MOVW $SYS_thr_kill, R2	// v0
	SYSCALL
	RET

// kill current process
// func raiseproc(signal int32)
TEXT runtime·raiseproc(SB),NOSPLIT,$0
	MOVV	$SYS_getpid, R2
	SYSCALL
	MOVV	R2, R4		// a0 pid
	MOVW	sig+0(FP), R5	// a1 signal
	MOVV	$SYS_kill, R2
	SYSCALL
	RET

// func setitimer(which int32, itv *ITimerval, otv *ITimerval) (int32)
TEXT runtime·setitimer(SB), NOSPLIT|NOFRAME, $0
	MOVW mode+0(FP), R4	// a0
	MOVV new+8(FP), R5	// a1
	MOVV old+16(FP), R6	// a2
	MOVV $SYS_setitimer, R2	// v0
	SYSCALL
	MOVW R2, ret+24(FP)
	RET

// func walltime() (sec int64, nsec int32)
TEXT runtime·walltime(SB), NOSPLIT, $32-16
	MOVW $0, R4		// a0 CLOCK_REALTIME
	MOVV $0(R29), R5		// a1 local Timespec
	MOVV $SYS_clock_gettime, R2	// v0
	SYSCALL

	MOVV 0(R29), R4 // sec
	MOVV 8(R29), R5 // nsec

	MOVV R4, sec+0(FP)
	MOVW R5, nsec+8(FP)
	RET

// func nanotime() int64
TEXT runtime·nanotime(SB), NOSPLIT, $32
	MOVW $4, R4		// a0 CLOCK_MONOTONIC
	MOVV $0(R29), R5	// a1 local Timespec
	MOVV $SYS_clock_gettime, R2	// v0
	SYSCALL

	MOVV 0(R29), R4	// sec
	MOVW 8(R29), R5	// nsec

	MOVV $1000000000, R6
	MULVU R6, R4
	MOVV LO, R4
	ADDVU R5, R4

	MOVV R4, ret+0(FP)
	RET

// func sigaction(sig int64, act *Sigaction, oact *Sigaction) (int32)
TEXT runtime·asmSigaction(SB),NOSPLIT|NOFRAME,$0
	MOVV sig+0(FP), R4	// a0
	MOVV new+8(FP), R5	// a1
	MOVV old+16(FP), R6	// a2
	MOVV $SYS_sigaction, R2	// v0
	SYSCALL
	BEQ	R7, 2(PC)
	MOVW	$-1, R2
	MOVW	R2, ret+24(FP)
	RET

TEXT runtime·sigtramp(SB),NOSPLIT,$12
	// initialize REGSB = PC&0xffffffff00000000
	BGEZAL	R0, 1(PC)
	SRLV	$32, R31, RSB
	SLLV	$32, RSB

	// this might be called in external code context,
	// where g is not set.
	MOVB	runtime·iscgo(SB), R1
	BEQ	R1, 2(PC)
	JAL	runtime·load_g(SB)

	MOVW	R4, 8(R29)
	MOVV	R5, 16(R29)
	MOVV	R6, 24(R29)
	MOVV	$runtime·sigtrampgo(SB), R1
	JAL	(R1)
	RET

// func mmap(addr *byte, len uint64, prot int32, flags int32, fd int32, pos uint32) (*byte, int32)
TEXT runtime·mmap(SB),NOSPLIT|NOFRAME,$0
	MOVV addr+0(FP), R4		// a0
	MOVV len+8(FP), R5		// a1
	MOVW prot+16(FP), R6		// a2
	MOVW flags+20(FP), R7		// a3
	MOVW fd+24(FP), R8		// a4
	MOVW pos+28(FP), R9		// a5

	MOVV $SYS_mmap, R2		// v0
	SYSCALL
	BEQ	R7, ok			// check for error
	MOVV	$0, p+32(FP)
	MOVV	R2, err+40(FP)
	RET
ok:
	MOVV	R2, p+32(FP)
	MOVV	$0, err+40(FP)
	RET

// func munmap(addr *byte, len uint64)
TEXT runtime·munmap(SB),NOSPLIT,$0
	MOVV	addr+0(FP), R4	// a0
	MOVV	len+8(FP), R5	// a1
	MOVV	$SYS_munmap, R2	// v0
	SYSCALL
	BEQ	R7, 2(PC)	// check for error
	MOVV	R0, 0xf3(R0)	// crash
	RET

// func madvise(addr *byte, len uint64, behav int32) (int32)
TEXT runtime·madvise(SB),NOSPLIT,$0
	MOVV	addr+0(FP), R4		// a0
	MOVV	len+8(FP), R5		// a1
	MOVW	behav+16(FP), R6	// a2
	MOVV	$SYS_madvise, R2	// v0
	SYSCALL
	MOVW	R2, ret+24(FP)
	RET

// func int sigaltstack(ss *Sigaltstack, oss *Sigaltstack) (int32)
TEXT runtime·sigaltstack(SB),NOSPLIT|NOFRAME,$0
	MOVV	new+0(FP), R4	// a0
	MOVV	old+8(FP), R5	// a1
	MOVV	$SYS_sigaltstack, R2	// v0
	SYSCALL
	BEQ	R7, 2(PC)	// check for error
	MOVV	R0, 0xf1(R0)	// crash
	RET

// ?
TEXT runtime·sigfwd(SB),NOSPLIT,$0-16
	MOVW	sig+8(FP), R4	// a0
	MOVV	info+16(FP), R5	// a1
	MOVV	ctx+24(FP), R6	// a2
	MOVV	fn+0(FP), R25	// t9
	JAL	(R25)
	RET	

TEXT runtime·usleep(SB),NOSPLIT,$16-4
	MOVWU	usec+0(FP), R3
	MOVV	R3, R5
	MOVW	$1000000, R4
	DIVVU	R4, R3
	MOVV	LO, R3
	MOVV	R3, 8(R29)
	MOVW	$1000, R4
	MULVU	R3, R4
	MOVV	LO, R4
	SUBVU	R4, R5
	MOVV	R5, 16(R29)

	// nanosleep(&ts, 0)
	ADDV	$8, R29, R4
	MOVW	$0, R5
	MOVV	$SYS_nanosleep, R2
	SYSCALL
	RET

// func sysctl(name *int, namelen uint32, old *byte, oldlenp *uint64, new *byte, newlen uint64) (int32)
TEXT runtime·sysctl(SB),NOSPLIT,$0
	MOVV name+0(FP), R4	// a0
	MOVW namelen+8(FP), R5	// a1
	MOVV old+16(FP), R6	// a2
	MOVV oldlenp+24(FP), R7	// a3
	MOVV new+32(FP), R8	// a4
	MOVV nowlen+40(FP), R9	// a5	
	MOVV $SYS___sysctl, R2	// v0
	SYSCALL
	BEQ	R7, 2(PC)
	SUBU	R2, R0, R2	// negate error code
	MOVW	R2, ret+48(FP)
	RET

// func sched_yield(void) (void)
TEXT runtime·osyield(SB),NOSPLIT|NOFRAME,$0
	MOVV	$SYS_sched_yield, R2
	SYSCALL
	RET

// func int sigprocmask(how int32, set *Sigset, oset *Sigset) (int32)
TEXT runtime·sigprocmask(SB),NOSPLIT,$0
	MOVW	how+0(FP), R4		// a0
	MOVV	set+8(FP), R5		// a1
	MOVV	oset+16(FP), R6		// a2
	MOVV	$SYS_sigprocmask, R2	// v0
	SYSCALL
	BEQ	R7, 2(PC)		// check for error
	MOVW	R0, 0xf1(R0)	// crash
	RET

// func kqueue(void) (int32)
TEXT runtime·kqueue(SB),NOSPLIT,$0
	MOVV $SYS_kqueue, R2	// v0
	SYSCALL
	BEQ	R7, 2(PC)
	SUBU	R2, R0, R2
	MOVW	R2, ret+0(FP)
	RET

// kevent(kq int32, changelist *Kevent, nchanges int32, eventlist *Kevent, nevents int32, timeout *Timespec) (int32)
TEXT runtime·kevent(SB),NOSPLIT,$0
	MOVW kq+0(FP), R4		// a0
	MOVV changelist+8(FP), R5	// a1
	MOVW nchanges+16(FP), R6	// a2
	MOVV eventlist+24(FP), R7	// a3
	MOVW nevents+32(FP), R8		// a4
	MOVV timeout+40(FP), R9		// a5
	MOVV $SYS_kevent, R2		// v0
	SYSCALL
	BEQ	R7, 2(PC)		// check for error
	SUBU	R2, R0, R2
	MOVW	R2, ret+48(FP)
	RET

// void runtime·closeonexec(int32 fd)
TEXT runtime·closeonexec(SB),NOSPLIT,$0
	MOVW    fd+0(FP), R4  // fd
	MOVV    $2, R5  // F_SETFD
	MOVV    $1, R6  // FD_CLOEXEC
	MOVV	$SYS_fcntl, R2
	SYSCALL
	RET

// func cpuset_getaffinity(level int32, which int32, id int64, size int64, mask *byte) int32
TEXT runtime·cpuset_getaffinity(SB), NOSPLIT, $0-28
	MOVW	level+0(FP), R4	// a0
	MOVW	which+8(FP), R5	// a1
	MOVV	id+16(FP), R6	// a2
	MOVV	size+24(FP), R7	// a3
	MOVV	mask+32(FP), R8	// a4
	MOVV	$SYS_cpuset_getaffinity, R2	// v0
	SYSCALL
	BEQ	R7, 2(PC)	// check for error
	SUBU	R2, R0, R2
	MOVW	R2, ret+40(FP)
	RET
