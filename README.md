
# CompositeStructs.jl

![runtests](https://github.com/marius311/CompositeStructs.jl/workflows/runtests/badge.svg)

Creates a "composite" struct by splicing the fields of one struct into another. E.g.:


```julia
struct Foo{X,Y}
    x :: X
    y :: Y
end

@composite struct Bar{X,Y,Z}
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


If spliced types have type parameters, they must all be explicitly specified (like `X` and `Y` above). Multiple types can be spliced in any order, as long as no field names are duplicated. 

Compatible with `Base.@kwdef`, use `@composite @kwdef struct ... end`. The spliced types must themselves have a keyword constructor, and their defaults will propagate to the composite type:

```julia
@kwdef struct Foo
    x = 1
    y
end

@composite @kwdef struct Bar
    Foo...
    z = 3
end

Bar(y=2) # returns Bar(1,2,3)
```

The macro generates a standard struct, so there are no limitations on usage of composite structs (compositing can even be done recursively). 

Extending structs like this can mimic inheritance, and can be powerful if combined with giving both the original and extended struct a common abstract supertype (which the user is free to specify if desired, using normal Julia syntax).

## Note

This package is fairly similar to [Mixers.jl](https://github.com/rafaqz/Mixers.jl) and [Classes.jl](https://github.com/rjplevin/Classes.jl), but it can "extend" any struct, not just ones which were originally decorated with special macros (as is the case in those packages). It is also unique in its compatibility with `Base.@kwdef`. It lacks the automatic creation of an OOP abstract type hierarchy of Classes.jl, instead leaving this to the user to specify explicitly.  Inspired by [this](https://discourse.julialang.org/t/eval-scoping-in-macros-or-removing-eval-completely/54602/3?u=marius311) discourse comment.