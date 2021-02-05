
using StructExtender, Test

@testset "StructExtender" begin

    # tests work by explicilty redefing the @extend-ed struct, which
    # will be an error if its not exact the same
        
    # docstring example
    @test_nowarn @eval module $(gensym())
        using StructExtender
        struct Foo{X,Y}
            x :: X
            y :: Y
        end
        @extends struct Bar{X,Y,Z}
            Foo{X,Y}...
            z :: Z
        end
        struct Bar{X,Y,Z}
            x :: X
            y :: Y
            z :: Z
        end
    end

    # composite type in Foo, swap Y/X
    @test_nowarn @eval module $(gensym())
        using StructExtender
        struct Foo{X<:Real,Y}
            x :: X
            y :: Complex{Y}
        end
        @extends struct Bar{X,Y,Z}
            Foo{Y,X}...
            z :: Z
        end
        struct Bar{X,Y,Z}
            x :: Y
            y :: Complex{X}
            z :: Z
        end
    end

    # multiple splices / order
    @test_nowarn @eval module $(gensym())
        using StructExtender
        struct X x end
        struct Z z end
        @extends struct Bar
            X...
            y
            Z...
        end
        struct Bar
            x
            y
            z
        end
    end

    # non-concrete field
    @test_nowarn @eval module $(gensym())
        using StructExtender
        struct Foo{T}
            x :: Array{T,N} where {N}
        end
        @extends struct Bar{T}
            Foo{T}...
            y
        end
        struct Bar{T}
            x :: Array{T,N} where {N}
            y
        end
    end


    # mutable structs, with supertype
    @test_nowarn @eval module $(gensym())
        using StructExtender
        mutable struct Foo <: Real
            x
        end
        @extends mutable struct Bar <: Number
            Foo...
            y
        end
        mutable struct Bar <: Number
            x
            y
        end
    end

end


