; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --function-signature --check-attributes --check-globals
; RUN: opt -aa-pipeline=basic-aa -passes=attributor -attributor-manifest-internal  -attributor-annotate-decl-cs  -S < %s | FileCheck %s --check-prefixes=CHECK,TUNIT
; RUN: opt -aa-pipeline=basic-aa -passes=attributor-cgscc -attributor-manifest-internal  -attributor-annotate-decl-cs -S < %s | FileCheck %s --check-prefixes=CHECK,CGSCC
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"

; Test cases designed for the nosync function attribute.
; FIXME's are used to indicate problems and missing attributes.

; struct RT {
;   char A;
;   int B[10][20];
;   char C;
; };
; struct ST {
;   int X;
;   double Y;
;   struct RT Z;
; };
;
; int *foo(struct ST *s) {
;   return &s[1].Z.B[5][13];
; }

; TEST 1
; non-convergent and readnone implies nosync
%struct.RT = type { i8, [10 x [20 x i32]], i8 }
%struct.ST = type { i32, double, %struct.RT }

;.
; CHECK: @a = common global i32 0, align 4
;.
define ptr @foo(ptr %s) nounwind optsize ssp memory(none) uwtable {
; CHECK: Function Attrs: mustprogress nofree norecurse nosync nounwind optsize ssp willreturn memory(none) uwtable
; CHECK-LABEL: define {{[^@]+}}@foo
; CHECK-SAME: (ptr nofree readnone "no-capture-maybe-returned" [[S:%.*]]) #[[ATTR0:[0-9]+]] {
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[ARRAYIDX:%.*]] = getelementptr inbounds [[STRUCT_ST:%.*]], ptr [[S]], i64 1, i32 2, i32 1, i64 5, i64 13
; CHECK-NEXT:    ret ptr [[ARRAYIDX]]
;
entry:
  %arrayidx = getelementptr inbounds %struct.ST, ptr %s, i64 1, i32 2, i32 1, i64 5, i64 13
  ret ptr %arrayidx
}

; TEST 2
; atomic load with monotonic ordering
; int load_monotonic(_Atomic int *num) {
;   int n = atomic_load_explicit(num, memory_order_relaxed);
;   return n;
; }

define i32 @load_monotonic(ptr nocapture readonly %arg) norecurse nounwind uwtable {
; CHECK: Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: readwrite) uwtable
; CHECK-LABEL: define {{[^@]+}}@load_monotonic
; CHECK-SAME: (ptr nofree noundef nonnull readonly align 4 captures(none) dereferenceable(4) [[ARG:%.*]]) #[[ATTR1:[0-9]+]] {
; CHECK-NEXT:    [[I:%.*]] = load atomic i32, ptr [[ARG]] monotonic, align 4
; CHECK-NEXT:    ret i32 [[I]]
;
  %i = load atomic i32, ptr %arg monotonic, align 4
  ret i32 %i
}


; TEST 3
; atomic store with monotonic ordering.
; void store_monotonic(_Atomic int *num) {
;   atomic_load_explicit(num, memory_order_relaxed);
; }

define void @store_monotonic(ptr nocapture %arg) norecurse nounwind uwtable {
; CHECK: Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: readwrite) uwtable
; CHECK-LABEL: define {{[^@]+}}@store_monotonic
; CHECK-SAME: (ptr nofree noundef nonnull writeonly align 4 captures(none) dereferenceable(4) [[ARG:%.*]]) #[[ATTR1]] {
; CHECK-NEXT:    store atomic i32 10, ptr [[ARG]] monotonic, align 4
; CHECK-NEXT:    ret void
;
  store atomic i32 10, ptr %arg monotonic, align 4
  ret void
}

; TEST 4 - negative, should not deduce nosync
; atomic load with acquire ordering.
; int load_acquire(_Atomic int *num) {
;   int n = atomic_load_explicit(num, memory_order_acquire);
;   return n;
; }

define i32 @load_acquire(ptr nocapture readonly %arg) norecurse nounwind uwtable {
; CHECK: Function Attrs: mustprogress nofree norecurse nounwind willreturn memory(argmem: readwrite) uwtable
; CHECK-LABEL: define {{[^@]+}}@load_acquire
; CHECK-SAME: (ptr nofree noundef nonnull readonly align 4 captures(none) dereferenceable(4) [[ARG:%.*]]) #[[ATTR2:[0-9]+]] {
; CHECK-NEXT:    [[I:%.*]] = load atomic i32, ptr [[ARG]] acquire, align 4
; CHECK-NEXT:    ret i32 [[I]]
;
  %i = load atomic i32, ptr %arg acquire, align 4
  ret i32 %i
}

; TEST 5 - negative, should not deduce nosync
; atomic load with release ordering
; void load_release(_Atomic int *num) {
;   atomic_store_explicit(num, 10, memory_order_release);
; }

define void @load_release(ptr nocapture %arg) norecurse nounwind uwtable {
; CHECK: Function Attrs: mustprogress nofree norecurse nounwind willreturn memory(argmem: readwrite) uwtable
; CHECK-LABEL: define {{[^@]+}}@load_release
; CHECK-SAME: (ptr nofree noundef writeonly align 4 captures(none) [[ARG:%.*]]) #[[ATTR2]] {
; CHECK-NEXT:    store atomic volatile i32 10, ptr [[ARG]] release, align 4
; CHECK-NEXT:    ret void
;
  store atomic volatile i32 10, ptr %arg release, align 4
  ret void
}

; TEST 6 - negative volatile, relaxed atomic

define void @load_volatile_release(ptr nocapture %arg) norecurse nounwind uwtable {
; CHECK: Function Attrs: mustprogress nofree norecurse nounwind willreturn memory(argmem: readwrite) uwtable
; CHECK-LABEL: define {{[^@]+}}@load_volatile_release
; CHECK-SAME: (ptr nofree noundef writeonly align 4 captures(none) [[ARG:%.*]]) #[[ATTR2]] {
; CHECK-NEXT:    store atomic volatile i32 10, ptr [[ARG]] release, align 4
; CHECK-NEXT:    ret void
;
  store atomic volatile i32 10, ptr %arg release, align 4
  ret void
}

; TEST 7 - negative, should not deduce nosync
; volatile store.
; void volatile_store(volatile int *num) {
;   *num = 14;
; }

define void @volatile_store(ptr %arg) norecurse nounwind uwtable {
; CHECK: Function Attrs: mustprogress nofree norecurse nounwind willreturn memory(argmem: readwrite) uwtable
; CHECK-LABEL: define {{[^@]+}}@volatile_store
; CHECK-SAME: (ptr nofree noundef align 4 [[ARG:%.*]]) #[[ATTR2]] {
; CHECK-NEXT:    store volatile i32 14, ptr [[ARG]], align 4
; CHECK-NEXT:    ret void
;
  store volatile i32 14, ptr %arg, align 4
  ret void
}

; TEST 8 - negative, should not deduce nosync
; volatile load.
; int volatile_load(volatile int *num) {
;   int n = *num;
;   return n;
; }

define i32 @volatile_load(ptr %arg) norecurse nounwind uwtable {
; CHECK: Function Attrs: mustprogress nofree norecurse nounwind willreturn memory(argmem: readwrite) uwtable
; CHECK-LABEL: define {{[^@]+}}@volatile_load
; CHECK-SAME: (ptr nofree noundef align 4 [[ARG:%.*]]) #[[ATTR2]] {
; CHECK-NEXT:    [[I:%.*]] = load volatile i32, ptr [[ARG]], align 4
; CHECK-NEXT:    ret i32 [[I]]
;
  %i = load volatile i32, ptr %arg, align 4
  ret i32 %i
}

; TEST 9

; CHECK: Function Attrs: noinline nosync nounwind uwtable
declare void @nosync_function() noinline nounwind uwtable nosync

define void @call_nosync_function() noinline nounwind uwtable {
; CHECK: Function Attrs: noinline nosync nounwind uwtable
; CHECK-LABEL: define {{[^@]+}}@call_nosync_function
; CHECK-SAME: () #[[ATTR3:[0-9]+]] {
; CHECK-NEXT:    tail call void @nosync_function() #[[ATTR4:[0-9]+]]
; CHECK-NEXT:    ret void
;
  tail call void @nosync_function() noinline nounwind uwtable
  ret void
}

; TEST 10 - negative, should not deduce nosync

; CHECK: Function Attrs: noinline nounwind uwtable
declare void @might_sync() noinline nounwind uwtable

define void @call_might_sync() noinline nounwind uwtable {
; CHECK: Function Attrs: noinline nounwind uwtable
; CHECK-LABEL: define {{[^@]+}}@call_might_sync
; CHECK-SAME: () #[[ATTR4]] {
; CHECK-NEXT:    tail call void @might_sync() #[[ATTR4]]
; CHECK-NEXT:    ret void
;
  tail call void @might_sync() noinline nounwind uwtable
  ret void
}

; TEST 11 - positive, should deduce nosync
; volatile operation in same scc but dead. Call volatile_load defined in TEST 8.

define i32 @scc1(ptr %arg) noinline nounwind uwtable {
; CHECK: Function Attrs: nofree noinline nounwind memory(argmem: readwrite) uwtable
; CHECK-LABEL: define {{[^@]+}}@scc1
; CHECK-SAME: (ptr nofree [[ARG:%.*]]) #[[ATTR5:[0-9]+]] {
; CHECK-NEXT:    tail call void @scc2(ptr nofree [[ARG]]) #[[ATTR20:[0-9]+]]
; CHECK-NEXT:    [[VAL:%.*]] = tail call i32 @volatile_load(ptr nofree noundef align 4 [[ARG]]) #[[ATTR20]]
; CHECK-NEXT:    ret i32 [[VAL]]
;
  tail call void @scc2(ptr %arg)
  %val = tail call i32 @volatile_load(ptr %arg)
  ret i32 %val
}

define void @scc2(ptr %arg) noinline nounwind uwtable {
; CHECK: Function Attrs: nofree noinline nounwind memory(argmem: readwrite) uwtable
; CHECK-LABEL: define {{[^@]+}}@scc2
; CHECK-SAME: (ptr nofree [[ARG:%.*]]) #[[ATTR5]] {
; CHECK-NEXT:    [[I:%.*]] = tail call i32 @scc1(ptr nofree [[ARG]]) #[[ATTR20]]
; CHECK-NEXT:    ret void
;
  %i = tail call i32 @scc1(ptr %arg)
  ret void
}

; TEST 12 - fences, negative
;
; void foo1(int *a, std::atomic<bool> flag){
;   *a = 100;
;   atomic_thread_fence(std::memory_order_release);
;   flag.store(true, std::memory_order_relaxed);
; }
;
; void bar(int *a, std::atomic<bool> flag){
;   while(!flag.load(std::memory_order_relaxed))
;     ;
;
;   atomic_thread_fence(std::memory_order_acquire);
;   int b = *a;
; }

%"struct.std::atomic" = type { %"struct.std::__atomic_base" }
%"struct.std::__atomic_base" = type { i8 }

define void @foo1(ptr %arg, ptr %arg1) {
; CHECK: Function Attrs: mustprogress nofree norecurse nounwind willreturn
; CHECK-LABEL: define {{[^@]+}}@foo1
; CHECK-SAME: (ptr nofree noundef nonnull writeonly align 4 captures(none) dereferenceable(4) [[ARG:%.*]], ptr nofree noundef nonnull writeonly captures(none) dereferenceable(1) [[ARG1:%.*]]) #[[ATTR6:[0-9]+]] {
; CHECK-NEXT:    store i32 100, ptr [[ARG]], align 4
; CHECK-NEXT:    fence release
; CHECK-NEXT:    store atomic i8 1, ptr [[ARG1]] monotonic, align 1
; CHECK-NEXT:    ret void
;
  store i32 100, ptr %arg, align 4
  fence release
  store atomic i8 1, ptr %arg1 monotonic, align 1
  ret void
}

define void @bar(ptr %arg, ptr %arg1) {
; CHECK: Function Attrs: nofree norecurse nounwind
; CHECK-LABEL: define {{[^@]+}}@bar
; CHECK-SAME: (ptr nofree readnone captures(none) [[ARG:%.*]], ptr nofree nonnull readonly captures(none) dereferenceable(1) [[ARG1:%.*]]) #[[ATTR7:[0-9]+]] {
; CHECK-NEXT:    br label [[BB2:%.*]]
; CHECK:       bb2:
; CHECK-NEXT:    [[I3:%.*]] = load atomic i8, ptr [[ARG1]] monotonic, align 1
; CHECK-NEXT:    [[I4:%.*]] = and i8 [[I3]], 1
; CHECK-NEXT:    [[I5:%.*]] = icmp eq i8 [[I4]], 0
; CHECK-NEXT:    br i1 [[I5]], label [[BB2]], label [[BB6:%.*]]
; CHECK:       bb6:
; CHECK-NEXT:    fence acquire
; CHECK-NEXT:    ret void
;
  br label %bb2

bb2:
  %i3 = load atomic i8, ptr %arg1 monotonic, align 1
  %i4 = and i8 %i3, 1
  %i5 = icmp eq i8 %i4, 0
  br i1 %i5, label %bb2, label %bb6

bb6:
  fence acquire
  ret void
}

; TEST 13 - Fence syncscope("singlethread") seq_cst
define void @foo1_singlethread(ptr %arg, ptr %arg1) {
; CHECK: Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn
; CHECK-LABEL: define {{[^@]+}}@foo1_singlethread
; CHECK-SAME: (ptr nofree noundef nonnull writeonly align 4 captures(none) dereferenceable(4) [[ARG:%.*]], ptr nofree noundef nonnull writeonly captures(none) dereferenceable(1) [[ARG1:%.*]]) #[[ATTR8:[0-9]+]] {
; CHECK-NEXT:    store i32 100, ptr [[ARG]], align 4
; CHECK-NEXT:    fence syncscope("singlethread") release
; CHECK-NEXT:    store atomic i8 1, ptr [[ARG1]] monotonic, align 1
; CHECK-NEXT:    ret void
;
  store i32 100, ptr %arg, align 4
  fence syncscope("singlethread") release
  store atomic i8 1, ptr %arg1 monotonic, align 1
  ret void
}

define void @bar_singlethread(ptr %arg, ptr %arg1) {
; CHECK: Function Attrs: nofree norecurse nosync nounwind
; CHECK-LABEL: define {{[^@]+}}@bar_singlethread
; CHECK-SAME: (ptr nofree readnone captures(none) [[ARG:%.*]], ptr nofree nonnull readonly captures(none) dereferenceable(1) [[ARG1:%.*]]) #[[ATTR9:[0-9]+]] {
; CHECK-NEXT:    br label [[BB2:%.*]]
; CHECK:       bb2:
; CHECK-NEXT:    [[I3:%.*]] = load atomic i8, ptr [[ARG1]] monotonic, align 1
; CHECK-NEXT:    [[I4:%.*]] = and i8 [[I3]], 1
; CHECK-NEXT:    [[I5:%.*]] = icmp eq i8 [[I4]], 0
; CHECK-NEXT:    br i1 [[I5]], label [[BB2]], label [[BB6:%.*]]
; CHECK:       bb6:
; CHECK-NEXT:    fence syncscope("singlethread") acquire
; CHECK-NEXT:    ret void
;
  br label %bb2

bb2:
  %i3 = load atomic i8, ptr %arg1 monotonic, align 1
  %i4 = and i8 %i3, 1
  %i5 = icmp eq i8 %i4, 0
  br i1 %i5, label %bb2, label %bb6

bb6:
  fence syncscope("singlethread") acquire
  ret void
}

declare void @llvm.memcpy.p0.p0.i32(ptr %dest, ptr %src, i32 %len, i1 %isvolatile)
declare void @llvm.memset.p0.i32(ptr %dest, i8 %val, i32 %len, i1 %isvolatile)

; TEST 14 - negative, checking volatile intrinsics.

; It is odd to add nocapture but a result of the llvm.memcpy nocapture.
;
define i32 @memcpy_volatile(ptr %ptr1, ptr %ptr2) {
; CHECK: Function Attrs: mustprogress nofree norecurse nounwind willreturn memory(argmem: readwrite)
; CHECK-LABEL: define {{[^@]+}}@memcpy_volatile
; CHECK-SAME: (ptr nofree writeonly captures(none) [[PTR1:%.*]], ptr nofree readonly captures(none) [[PTR2:%.*]]) #[[ATTR12:[0-9]+]] {
; CHECK-NEXT:    call void @llvm.memcpy.p0.p0.i32(ptr nofree writeonly captures(none) [[PTR1]], ptr nofree readonly captures(none) [[PTR2]], i32 noundef 8, i1 noundef true) #[[ATTR21:[0-9]+]]
; CHECK-NEXT:    ret i32 4
;
  call void @llvm.memcpy.p0.p0.i32(ptr %ptr1, ptr %ptr2, i32 8, i1 true)
  ret i32 4
}

; TEST 15 - positive, non-volatile intrinsic.

; It is odd to add nocapture but a result of the llvm.memset nocapture.
;
define i32 @memset_non_volatile(ptr %ptr1, i8 %val) {
; CHECK: Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: write)
; CHECK-LABEL: define {{[^@]+}}@memset_non_volatile
; CHECK-SAME: (ptr nofree writeonly captures(none) [[PTR1:%.*]], i8 [[VAL:%.*]]) #[[ATTR13:[0-9]+]] {
; CHECK-NEXT:    call void @llvm.memset.p0.i32(ptr nofree writeonly captures(none) [[PTR1]], i8 [[VAL]], i32 noundef 8, i1 noundef false) #[[ATTR22:[0-9]+]]
; CHECK-NEXT:    ret i32 4
;
  call void @llvm.memset.p0.i32(ptr %ptr1, i8 %val, i32 8, i1 false)
  ret i32 4
}

; TEST 16 - negative, inline assembly.

define i32 @inline_asm_test(i32 %x) {
; CHECK-LABEL: define {{[^@]+}}@inline_asm_test
; CHECK-SAME: (i32 [[X:%.*]]) {
; CHECK-NEXT:    [[I:%.*]] = call i32 asm sideeffect "bswap $0", "=r,r"(i32 [[X]])
; CHECK-NEXT:    ret i32 4
;
  %i = call i32 asm sideeffect "bswap $0", "=r,r"(i32 %x)
  ret i32 4
}

declare void @readnone_test() convergent readnone

; TEST 17 - negative. Convergent
define void @convergent_readnone() {
; CHECK: Function Attrs: memory(none)
; CHECK-LABEL: define {{[^@]+}}@convergent_readnone
; CHECK-SAME: () #[[ATTR15:[0-9]+]] {
; CHECK-NEXT:    call void @readnone_test()
; CHECK-NEXT:    ret void
;
  call void @readnone_test()
  ret void
}

; CHECK: Function Attrs: nounwind
declare void @llvm.x86.sse2.clflush(ptr)
@a = common global i32 0, align 4

; TEST 18 - negative. Synchronizing intrinsic

define void @i_totally_sync() {
; CHECK: Function Attrs: nounwind
; CHECK-LABEL: define {{[^@]+}}@i_totally_sync
; CHECK-SAME: () #[[ATTR16:[0-9]+]] {
; CHECK-NEXT:    tail call void @llvm.x86.sse2.clflush(ptr noundef nonnull align 4 dereferenceable(4) @a)
; CHECK-NEXT:    ret void
;
  tail call void @llvm.x86.sse2.clflush(ptr @a)
  ret void
}

declare float @llvm.cos.f32(float %val) readnone

; TEST 19 - positive, readnone & non-convergent intrinsic.

define i32 @cos_test(float %x) {
; CHECK: Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none)
; CHECK-LABEL: define {{[^@]+}}@cos_test
; CHECK-SAME: (float [[X:%.*]]) #[[ATTR18:[0-9]+]] {
; CHECK-NEXT:    ret i32 4
;
  %i = call float @llvm.cos.f32(float %x)
  ret i32 4
}

define float @cos_test2(float %x) {
; CHECK: Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none)
; CHECK-LABEL: define {{[^@]+}}@cos_test2
; CHECK-SAME: (float [[X:%.*]]) #[[ATTR18]] {
; CHECK-NEXT:    [[C:%.*]] = call nofpclass(inf) float @llvm.cos.f32(float [[X]]) #[[ATTR23:[0-9]+]]
; CHECK-NEXT:    ret float [[C]]
;
  %c = call float @llvm.cos.f32(float %x)
  ret float %c
}

declare void @unknown()
define void @nosync_convergent_callee_test() {
; CHECK: Function Attrs: nosync memory(none)
; CHECK-LABEL: define {{[^@]+}}@nosync_convergent_callee_test
; CHECK-SAME: () #[[ATTR19:[0-9]+]] {
; CHECK-NEXT:    call void @unknown() #[[ATTR24:[0-9]+]]
; CHECK-NEXT:    ret void
;
  call void @unknown() nosync convergent readnone
  ret void
}
;.
; CHECK: attributes #[[ATTR0]] = { mustprogress nofree norecurse nosync nounwind optsize ssp willreturn memory(none) uwtable }
; CHECK: attributes #[[ATTR1]] = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: readwrite) uwtable }
; CHECK: attributes #[[ATTR2]] = { mustprogress nofree norecurse nounwind willreturn memory(argmem: readwrite) uwtable }
; CHECK: attributes #[[ATTR3]] = { noinline nosync nounwind uwtable }
; CHECK: attributes #[[ATTR4]] = { noinline nounwind uwtable }
; CHECK: attributes #[[ATTR5]] = { nofree noinline nounwind memory(argmem: readwrite) uwtable }
; CHECK: attributes #[[ATTR6]] = { mustprogress nofree norecurse nounwind willreturn }
; CHECK: attributes #[[ATTR7]] = { nofree norecurse nounwind }
; CHECK: attributes #[[ATTR8]] = { mustprogress nofree norecurse nosync nounwind willreturn }
; CHECK: attributes #[[ATTR9]] = { nofree norecurse nosync nounwind }
; CHECK: attributes #[[ATTR10:[0-9]+]] = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
; CHECK: attributes #[[ATTR11:[0-9]+]] = { nocallback nofree nounwind willreturn memory(argmem: write) }
; CHECK: attributes #[[ATTR12]] = { mustprogress nofree norecurse nounwind willreturn memory(argmem: readwrite) }
; CHECK: attributes #[[ATTR13]] = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: write) }
; CHECK: attributes #[[ATTR14:[0-9]+]] = { convergent memory(none) }
; CHECK: attributes #[[ATTR15]] = { memory(none) }
; CHECK: attributes #[[ATTR16]] = { nounwind }
; CHECK: attributes #[[ATTR17:[0-9]+]] = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
; CHECK: attributes #[[ATTR18]] = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) }
; CHECK: attributes #[[ATTR19]] = { nosync memory(none) }
; CHECK: attributes #[[ATTR20]] = { nofree nounwind }
; CHECK: attributes #[[ATTR21]] = { nofree willreturn }
; CHECK: attributes #[[ATTR22]] = { nofree willreturn memory(write) }
; CHECK: attributes #[[ATTR23]] = { nofree nosync willreturn }
; CHECK: attributes #[[ATTR24]] = { convergent nosync memory(none) }
;.
;; NOTE: These prefixes are unused and the list is autogenerated. Do not add tests below this line:
; CGSCC: {{.*}}
; TUNIT: {{.*}}
