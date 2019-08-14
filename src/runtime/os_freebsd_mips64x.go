// Copyright 2015 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// +build freebsd
// +build mips64 mips64le

package runtime

// XXX-AM: do the same as linux mips64?
// var randomNumber uint32

func nanotime() int64

func walltime() (sec int64, nsec int32)

//go:nosplit
func cputicks() int64 {
	// Currently cputicks() is used in blocking profiler and to seed fastrand().
	// nanotime() is a poor approximation of CPU ticks that is enough for the profiler.
	// randomNumber provides better seeding of fastrand.
	return nanotime() //+ int64(randomNumber)
}
