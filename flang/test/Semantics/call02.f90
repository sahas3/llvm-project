! RUN: %python %S/test_errors.py %s %flang_fc1 -pedantic
! 15.5.1 procedure reference constraints and restrictions

subroutine s01(elem, subr)
  interface
    !ERROR: A dummy procedure may not be ELEMENTAL
    elemental real function elem(x)
      real, intent(in), value :: x
    end function
    subroutine subr(dummy)
      !PORTABILITY: A dummy procedure should not have an ELEMENTAL intrinsic as its interface [-Wportability]
      procedure(sin) :: dummy
    end subroutine
    subroutine badsubr(dummy)
      import :: elem
      !ERROR: A dummy procedure may not be ELEMENTAL
      procedure(elem) :: dummy
    end subroutine
    subroutine optionalsubr(dummy)
      !PORTABILITY: A dummy procedure should not have an ELEMENTAL intrinsic as its interface [-Wportability]
      procedure(sin), optional :: dummy
    end subroutine
    subroutine ptrsubr(dummy)
      !PORTABILITY: A dummy procedure should not have an ELEMENTAL intrinsic as its interface [-Wportability]
      procedure(sin), pointer, intent(in) :: dummy
    end subroutine
  end interface
  intrinsic :: cos
  call subr(cos) ! not an error
  !ERROR: Non-intrinsic ELEMENTAL procedure 'elem' may not be passed as an actual argument
  call subr(elem) ! C1533
  !ERROR: Actual argument associated with procedure dummy argument 'dummy=' is a null pointer
  call subr(null())
  call optionalsubr(null()) ! ok
  call ptrsubr(null()) ! ok
  !ERROR: Actual argument associated with procedure dummy argument 'dummy=' is typeless
  call subr(B"1010")
end subroutine

subroutine s02
  !ERROR: Non-intrinsic ELEMENTAL procedure 'elem' may not be passed as an actual argument
  call sub(elem)
 contains
  elemental integer function elem()
    elem = 1
  end function
end

subroutine s03
  interface
    subroutine sub1(p)
      procedure(real) :: p
    end subroutine
  end interface
  sf(x) = x + 1.
  !ERROR: Statement function 'sf' may not be passed as an actual argument
  call sub1(sf)
  !ERROR: Statement function 'sf' may not be passed as an actual argument
  call sub2(sf)
end

module m01
  procedure(sin) :: elem01
  interface
    elemental real function elem02(x)
      real, value :: x
    end function
    subroutine callme(f)
      external f
    end subroutine
  end interface
 contains
  elemental real function elem03(x)
    real, value :: x
    elem03 = 0.
  end function
  subroutine test
    intrinsic :: cos
    call callme(cos) ! not an error
    !ERROR: Non-intrinsic ELEMENTAL procedure 'elem01' may not be passed as an actual argument
    call callme(elem01) ! C1533
    !ERROR: Non-intrinsic ELEMENTAL procedure 'elem02' may not be passed as an actual argument
    call callme(elem02) ! C1533
    !ERROR: Non-intrinsic ELEMENTAL procedure 'elem03' may not be passed as an actual argument
    call callme(elem03) ! C1533
    !ERROR: Non-intrinsic ELEMENTAL procedure 'elem04' may not be passed as an actual argument
    call callme(elem04) ! C1533
   contains
    elemental real function elem04(x)
      real, value :: x
      elem04 = 0.
    end function
  end subroutine
end module

module m02
  type :: t
    integer, pointer :: ptr
  end type
  type(t) :: coarray[*]
 contains
  subroutine callee(x)
    type(t), intent(in) :: x
  end subroutine
  subroutine test
    !ERROR: Coindexed object 'coarray' with POINTER ultimate component '%ptr' cannot be associated with dummy argument 'x='
    call callee(coarray[1]) ! C1537
  end subroutine
end module

module m03
 contains
  subroutine test
    !ERROR: Non-intrinsic ELEMENTAL procedure 'elem' may not be passed as an actual argument
    call sub(elem)
   contains
    elemental integer function elem()
      elem = 1
    end function
  end
end

program p03
  logical :: l
  call s1(index)
  l = index .eq. 0  ! index is an object entity, not an intrinsic
  call s2(sin)
  !ERROR: Actual argument associated with procedure dummy argument 'p=' is not a procedure
  call s3(cos)
contains
  subroutine s2(x)
    real :: x
  end
  subroutine s3(p)
    procedure(real) :: p
  end
end

subroutine p04
  implicit none
  !ERROR: No explicit type declared for 'index'
  call s1(index)
end

subroutine p05
  integer :: a1(2), a2, a3
  !ERROR: In an elemental procedure reference with at least one array argument, actual argument a2 that corresponds to an INTENT(OUT) or INTENT(INOUT) dummy argument must be an array
  !ERROR: In an elemental procedure reference with at least one array argument, actual argument a3 that corresponds to an INTENT(OUT) or INTENT(INOUT) dummy argument must be an array
  call s1(a1, a2, a3)
contains
  elemental subroutine s1(a, b, c)
    integer, intent(in) :: a
    integer, intent(out) :: b
    integer, intent(inout) :: c
    b = a
    c = a
  end
end
