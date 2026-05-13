module TOGMoveOctahedron

using LoopOS: @whiletrue
using TOGZMQAPIServer: push!
using TOGOctahedron: Octahedron
using TOG: T, 𝕋

CHANGEΔ = T(0.01) # todo make dependent on coordinates

function start(socketlocation, o::Octahedron, ω::𝕋)
    TOGZMQAPIServer.start(socketlocation)
    push!(μ -> move!(o, μ))
    push!(μ -> focus!(o, μ))
    push!(ρ -> scale!(o, ρ))
    push!(θ -> rotate!(o, θ))
    push!(v -> speed!(o, v))
    push!(δ -> accelerate!(o, δ))
    push!(δ -> jerk!(o, δ))
    push!(_ -> present!(o, ω))
    push!(_ -> freezetime!(o))
    push!(δ -> speeduptime!(o, δ))
    push!(δ -> slowdowntime!(o, δ))
    @async @whiletrue step!(o, ω)
end

function step!(o::Octahedron, ω::𝕋)
    o.∂Ο ? present!(o, ω) : o.Ο += o.vΟ
    μ = o.ẑeroμ .+ o.v * (o.ẑeroμ .- o.ôneμ)
    move!(g, μ)
end
valid(o::Octahedron) = valid(o.ẑeroμ, o.ôneμ, o.ρ, o.θ, o.norm)
function valid(ẑeroμ, ôneμ, ρ, θ, norm)
    _, _, _, _, _, _, _, _, _, μ, ρ = pyramid(ẑeroμ, ôneμ, ρ, θ, norm)
    all(zero(T) .≤ μ .- ρ .≤ μ .+ ρ .≤ one(T))
end
function move!(o::Octahedron, ẑeroμ)
    valid(ẑeroμ, o.ôneμ, o.ρ, o.θ, o.norm) || return
    o.ẑeroμ = ẑeroμ
end
function focus!(o::Octahedron, ôneμ)
    valid(o.ẑeroμ, ôneμ, o.ρ, o.θ, o.norm) || return
    o.ôneμ = ôneμ
end
function scale!(o::Octahedron, ρ)
    valid(o) || return
    o.ρ = ρ
end
function rotate!(o::Octahedron, θ)
    valid(o) || return
    g.θ = θ
end

scale!(o::Octahedron, i, δ) = scale!(o, ntuple(ĩ -> begin
        ĩ == i && return o.ρ[ĩ] + δ
        o.ρ[ĩ]
    end, length(o.ρ)))
move!(o::Octahedron, i, δ) =
    move!(o, SVector(ntuple(ĩ -> begin
            ĩ == i && return o.ẑeroμ[ĩ] + δ
            o.ẑeroμ[ĩ]
        end, length(o.ẑeroμ))))
focus!(o::Octahedron, i, δ) = focus!(o, SVector(ntuple(ĩ -> begin
        ĩ == i && return o.ôneμ[ĩ] + δ
        o.ôneμ[ĩ]
    end, length(o.ône.μ))))

focusup!(o::Octahedron, i) = focus!(o, i, CHANGEΔ)
focusdown!(o::Octahedron, i) = focus!(o, i, -CHANGEΔ)
moveup!(o::Octahedron, i) = move!(o, i, CHANGEΔ)
movedown!(o::Octahedron, i) = move!(o, i, -CHANGEΔ)
jerkup!(o::Octahedron) = jerk!(o, CHANGEΔ)
jerkdown!(o::Octahedron) = jerk!(o, -CHANGEΔ)
scaleup!(o::Octahedron, i) = scale!(o, i, CHANGEΔ)
scaledown!(o::Octahedron, i) = scale!(o, i, -CHANGEΔ)
rotateup!(o::Octahedron) = rotate!(o, o.θ + CHANGEΔ)
rotatedown!(o::Octahedron) = rotate!(o, o.θ - CHANGEΔ)

speed!(o::Octahedron, v) = o.v = clamp(v, zero(o.v), one(o.v))
accelerate!(o::Octahedron, δ) = speed!(o, iszero(o.v) ? δ : o.v * exp(δ))
jerk!(o::Octahedron, δ) = accelerate!(o, o.v * exp(δ))

present!(o::Octahedron, ω::𝕋) = o.Ο = ω.Ο[ω]
freezetime!(o::Octahedron) = o.vΟ = zero(o.vΟ)
speeduptime!(o::Octahedron, δ) = o.vΟ += δ
slowdowntime!(o::Octahedron, δ) = o.vΟ -= δ

end
