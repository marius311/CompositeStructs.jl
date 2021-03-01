module CompositeStructs

using Core: apply_type
using Base: datatype_fieldtypes, unwrap_unionall
using Base.Meta: isexpr

export @composite

# given an expression like :(Complex{T}) and a module in which the
# relevant symbols are defined, reconstruct a type object without
# calling @eval
reconstruct_type(__module__, s::Symbol) = getfield(__module__, s)
function reconstruct_type(__module__, ex)
    isexpr(ex, :curly) || error("Invalid @composite syntax.")
    foldl((t,x) -> apply_type(t, TypeVar(x)), ex.args[2:end], init=reconstruct_type(__module__,ex.args[1]))
end

# convert a type or UnionAll back to an expression
to_expr(t::DataType) = isempty(t.parameters) ? t.name.name : :($(t.name.name){$(map(to_expr,t.parameters)...)})
to_expr(t::TypeVar) = t.name
to_expr(t::Symbol) = t
to_expr(t::UnionAll) = :($(to_expr(t.body)) where {$(t.var.lb) <: $(t.var.name) <: $(t.var.ub)})

# given an expression like :(Complex{T}) and a module in which the
# relevant symbols are defined, return an array with the struct's
# fields and their type signatures, in this case: [:(re::T), (im::T)]
function reconstruct_fields(__module__, ex)
    t = reconstruct_type(__module__, ex)
    (t isa UnionAll) && error("Spliced type must not have any free type parameters.")
    map(zip(fieldnames(t),datatype_fieldtypes(t))) do (x,T)
        :($x::$(to_expr(T)))
    end
end

"""

    @composite [mutable] struct ... end

Splices the fields of one struct into another. E.g.:

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


Spliced types must not have any free type parameters. Multiple types
can be spliced and in any order. 

"""
macro composite(structdef)
    fields = []
    for f in structdef.args[3].args
        isexpr(f, :(...)) ? append!(fields, reconstruct_fields(__module__, f.args[1])) : push!(fields, f)
    end
    structdef.args[3] = :(begin $(fields...) end)
    esc(structdef)
end

end
