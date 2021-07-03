
Mini Scheme
===========

Mini-Scheme is a Scheme/Lisp like programming language underlying Wyrm.
Mini-Scheme provides an implementation platform for the Wyrm programming
language that can be bootstrapped with a full-fledged Scheme implementation.
Additionally, the Wyrm programming language utilizes MiniScheme as a 
representative language during the compilation phase.

A small shim provides portability of underlying operating or language concepts
between the Wyrm runtime and more standard Scheme implementations(e.g. Chicken
Scheme). 

The following scheme primitives are supported:
    - define
    - define-syntax
    - let (internal define allowed)
    - lambda
    - integer types (but only at native processor word size)

The 'wyrm' namespace provides functionality intended for implementation of the
bootstrap wyrm compiler. The namespace is not available unless explicitly
imported by a mini scheme application.

The '%_wrt' namespace provides access to low level built-in definitions for
the wyrm compiler. A subset of the namespace is available within the
bootstrap wyrm compiler.

The '%_platform' namespace provides access to low level platform primitives
and information. The namespace contents are specific to the operating
mode of the current compiler / intepreter.

