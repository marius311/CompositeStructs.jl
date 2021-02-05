
# StructExtender.jl

![runtests](https://github.com/marius311/StructExtender.jl/workflows/runtests/badge.svg)

Splices the fields of one struct into another. E.g.:


```julia
struct Foo{X,Y}
    x :: X
    y :: Y
end

@extends struct Bar{X,Y,Z}
    Foo{X,Y}...
    z :: Z
end

# equivalent to defining:
struct Bar{X,Y,Z}
    x :: X
    y :: Y
    z :: Z
end
```


Spliced types must not have any free type parameters. Multiple types
can be spliced and in any order. 

Extending structs like this can mimic inheritance, and can be powerful if combined with giving both the original and extended struct a common abstract supertype (which the user is free to specify if desired, using normal Julia syntax).

## Note

This package is fairly similar to [Mixers.jl](https://github.com/rafaqz/Mixers.jl) and [Classes.jl](https://github.com/rjplevin/Classes.jl), but it can "extend" any struct, not just ones which were originally decorated with special macros (as is the case in those packages). It lacks the automatic creation of an OOP abstract type hierarchy of Classes.jl, instead leaving this to the user to specify explicitly. Inspired by [this](https://discourse.julialang.org/t/eval-scoping-in-macros-or-removing-eval-completely/54602/3?u=marius311) discourse comment.