; NOTE: Assertions have been autogenerated by utils/update_mir_test_checks.py
; RUN: llc -mtriple=amdgcn-mesa-mesa3d -global-isel -stop-after=irtranslator -o - %s | FileCheck %s

declare { float, i1 } @llvm.amdgcn.div.scale.f32(float, float, i1)

define amdgpu_ps void @test_div_scale(float %arg0, float %arg1) {
  ; CHECK-LABEL: name: test_div_scale
  ; CHECK: bb.1 (%ir-block.0):
  ; CHECK-NEXT:   liveins: $vgpr0, $vgpr1
  ; CHECK-NEXT: {{  $}}
  ; CHECK-NEXT:   [[COPY:%[0-9]+]]:_(s32) = COPY $vgpr0
  ; CHECK-NEXT:   [[COPY1:%[0-9]+]]:_(s32) = COPY $vgpr1
  ; CHECK-NEXT:   [[DEF:%[0-9]+]]:_(p1) = G_IMPLICIT_DEF
  ; CHECK-NEXT:   [[INT:%[0-9]+]]:_(s32), [[INT1:%[0-9]+]]:_(s1) = G_INTRINSIC intrinsic(@llvm.amdgcn.div.scale), [[COPY]](s32), [[COPY1]](s32), -1
  ; CHECK-NEXT:   [[SEXT:%[0-9]+]]:_(s32) = G_SEXT [[INT1]](s1)
  ; CHECK-NEXT:   G_STORE [[INT]](s32), [[DEF]](p1) :: (store (s32) into `ptr addrspace(1) poison`, addrspace 1)
  ; CHECK-NEXT:   G_STORE [[SEXT]](s32), [[DEF]](p1) :: (store (s32) into `ptr addrspace(1) poison`, addrspace 1)
  ; CHECK-NEXT:   S_ENDPGM 0
  %call = call { float, i1 } @llvm.amdgcn.div.scale.f32(float %arg0, float %arg1, i1 true)
  %extract0 = extractvalue { float, i1 } %call, 0
  %extract1 = extractvalue { float, i1 } %call, 1
  %ext = sext i1 %extract1 to i32
  store float %extract0, ptr addrspace(1) poison
  store i32 %ext, ptr addrspace(1) poison
  ret void
}
