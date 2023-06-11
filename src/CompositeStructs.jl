module CompositeStructs

using Core: apply_type
using Base: datatype_fieldtypes, unwrap_unionall
using MacroTools

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
to_expr(t::DataType) = isempty(t.parameters) ? :($(t.name.module).$(t.name.name)) : :($(t.name.module).$(t.name.name){$(map(to_expr,t.parameters)...)})
to_expr(t::TypeVar) = t.name
to_expr(t::Symbol) = QuoteNode(t)
to_expr(t::UnionAll) = :($(to_expr(t.body)) where {$(t.var.lb) <: $(t.var.name) <: $(t.var.ub)})
to_expr(t) = t

# given an expression like :(Complex{T}) and a module in which the
# relevant symbols are defined, return an array with the struct's
# fields and their type signatures, in this case: [:(re::T), (im::T)]
function reconstruct_fields(__module__, ex)
    t = reconstruct_type(__module__, ex)
    (t isa UnionAll) && error("Spliced type $ex must not have any free type parameters.")
    map(zip(fieldnames(t),datatype_fieldtypes(t))) do (x,T)
        :($x::$(to_expr(T)))
    end
end

@doc join(readlines(joinpath(@__DIR__, "../README.md"))[6:end], "\n") 
macro composite(ex)

    if !(
        ((iskwdef = @capture(ex, @kwdef(structdef_) | Base.@kwdef(structdef_))) || @capture(ex, structdef_)) && 
        @capture(structdef, struct ParentTypeDecl_ parent_body__ end | mutable struct ParentTypeDecl_ parent_body__ end) &&
        @capture(ParentTypeDecl, (ParentType_ <: _) | ParentType_) &&
        @capture(ParentType, ParentName_{ParentTypeArgs__} | ParentName_)
    )
        error("Invalid @composite syntax.")
    end

    generic_child_constructors = []
    concrete_child_constructors = []
    parent_body′ = []
    explicit_parent_fields = []
    constructor_args = []

    # seem to be a bug if you put these in a single @capture
    _field_name(ex) = @capture(ex,name_Symbol::T_=val_) || @capture(ex,name_Symbol::T_) || @capture(ex,name_Symbol=val_) || @capture(ex,name_Symbol) ? name : nothing
    _field_kw(ex)   = @capture(ex,((name_::T_=val_) | (name_=val_))) ? Expr(:kw, name, val) : _field_name(ex)
    _field_decl(ex) = iskwdef && @capture(ex,(decl_ = val_)) ? decl : ex
    _strip_type_bound(ex) = @capture(ex, T_ <: _) ? T : ex

    for x in parent_body
        if @capture(x, ChildType_...) && @capture(ChildType, ChildName_{__} | ChildName_)
            child_fields = (reconstruct_fields(__module__, ChildType)...,)
            child_field_names = _field_name.(child_fields)
            append!(parent_body′, child_fields)
            child_instance = gensym()
            push!(generic_child_constructors,  :($child_instance = $ChildName(; filter(((k,_),)->(k in $child_field_names), kw)...)))
            push!(concrete_child_constructors, :($child_instance = $ChildType(; filter(((k,_),)->(k in $child_field_names), kw)...)))
            for f in child_field_names
                push!(constructor_args, :($child_instance.$f))
            end
        elseif _field_name(x) != nothing
            push!(explicit_parent_fields, x)
            push!(constructor_args, _field_name(x))
            push!(parent_body′, _field_decl(x))
        else
            push!(parent_body′, x)
        end
    end

    structdef.args[3] = :(begin $(parent_body′...) end)

    if !iskwdef
        esc(structdef)
    else
        ret = quote Core.@__doc__ $structdef end
        push!(ret.args, quote
            function $ParentName(;$(_field_kw.(explicit_parent_fields)...), kw...)
                $(generic_child_constructors...)
                $ParentName($(constructor_args...))
            end
        end)
        if ParentTypeArgs!=nothing
            ParentTypeArgsStripped = map(_strip_type_bound, ParentTypeArgs)
            push!(ret.args, quote
                function $ParentName{$(ParentTypeArgsStripped...)}(;$(_field_kw.(explicit_parent_fields)...), kw...) where {$(ParentTypeArgs...)}
                    $(concrete_child_constructors...)
                    $ParentName{$(ParentTypeArgsStripped...)}($(constructor_args...))
                end
            end)
        end
        esc(ret)
    end

end

end
