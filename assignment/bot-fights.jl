### A Pluto.jl notebook ###
# v0.17.5

# using Markdown
# using InteractiveUtils
import Random
using Base64



struct PlayResult
    me::Bool
    other::Bool
    payoff::Int64
end


import Base.show


function Base.show(io::IO, res::PlayResult)
    println(io, "I  played: ", res.me ? "Cooperate" : "Not Cooperate")
    println(io, "He played: ", res.other ? "Cooperate" : "Not Cooperate")
    println(io, "My reward: ", res.payoff)

    return nothing
end


function play(p1::Bool, p2::Bool)
    if p1 && p2
        return PlayResult(true, true, 3), PlayResult(true, true, 3)
    end

    if p1 && (!p2)
        return PlayResult(true, false, 0), PlayResult(false, true, 5)
    end

    if (!p1) && p2
        return PlayResult(false, true, 5), PlayResult(true, false, 0)
    end

    if (!p1) && (!p2)
        return PlayResult(false, false, 1), PlayResult(false, false, 1)
    end
end

mutable struct Player
    name::String
    strategy::String
    matches::Vector{Tuple{String,PlayResult}}
    action::Function
    score::Int64

    Player(name::String, strategy::String, action) = new(name::String, strategy::String, Vector{Tuple{String,PlayResult}}(), action, 0)
end

function Base.show(io::IO, pl::Player)
    println(io, "## Player ", pl.name)
    println(io, " # Strategy")
    println(io, pl.strategy)
    println(io, " # END strategy")

    println(io, " # Results after ", length(pl.matches), " matches")
    s = 0
    for i in 1:length(pl.matches)
        if i <= 10
            print(io, "     (", pl.matches[i][1], ", ", pl.matches[i][2].me, ", ",
                pl.matches[i][2].other, ", ", pl.matches[i][2].payoff, ")")
            if i % 3 == 0
                println(io, "")
            end
        end
        s = s + pl.matches[i][2].payoff
    end
    if length(pl.matches) > 10
        println(io, "...")
    end
    println(io, "\n # TOTAL number of points: ", pl.score)

    return nothing
end


function addplay!(pl::Player, opponent::String, res::PlayResult)
    push!(pl.matches, (opponent, res))
    pl.score = pl.score + res.payoff
    return nothing
end

function match!(pl1::Player, pl2::Player)
    p1 = pl1.action(pl2.name, pl1.matches)
    p2 = pl2.action(pl1.name, pl2.matches)

    r1, r2 = play(p1, p2)
    addplay!(pl1, pl2.name, r1)
    addplay!(pl2, pl1.name, r2)

    return nothing
end

function tournament(pls::Vector{Player}, nrounds)

    npls = length(pls)
    pairing = collect(1:npls)
    for k in 1:nrounds
        Random.shuffle!(pairing)
        for i in 1:div(npls, 2)
            match!(pls[pairing[2*i-1]], pls[pairing[2*i]])
        end
    end

    return nothing
end

function get_winner(pls::Vector{Player})
    scores = zeros(Int, length(pls))
    for (i, player) in enumerate(pls)
        scores[i] = player.score
    end
    winner = pls[argmax(scores)]
    print("Player $(winner.name) won!")
    return
end

###################### my functions

# cheating strategy 

mutable struct Status
    poisoned::Bool
    Status() = new(false)
end

stat = Status()

function get_payload(cheater_name::String)
    payload_exp = quote

        function addplay!(pl::Player, opponent::String, res_orig::PlayResult)
            detect_match = (pl.name == $cheater_name || opponent == $cheater_name)
            if detect_match
                # if we don't get at least 3 points from the match, we try to cheat
                # in other words, if the enemy does not cooperate with us, we steal their win
                detected_loss = (pl.name == $cheater_name && res_orig.payoff < 3) || (opponent == $cheater_name && res_orig.payoff == 5)
                if detected_loss
                    cheat = true
                else
                    cheat = false
                end
            else
                cheat = false
            end

            if cheat
                if pl.name == $cheater_name
                    res = PlayResult(false, true, 5)
                else
                    res = PlayResult(true, false, 0)
                end
            else
                res = res_orig
            end

            push!(pl.matches, (opponent, res))
            pl.score = pl.score + res.payoff
            return nothing
        end
    end
    return payload_exp
    # payload_encrypted = base64encode(repr(payload_exp))
    # return payload_encrypted
end

"""
	poison_addplay!(cheater_name, cheating_prob)

This function showcases the risks of the eval function. 
While normally a function defined inside another function would live inside the scope of that function,
If we evaluate the expression it will be defined in the global (Main) scope and pollute it.
In this case, we will weaponise this technique to poison the addplay! function, and replace it with 
our own function, which will let us win against the opponents regardless of what they play.
"""
function poison_addplay!(cheater_name="CHEATAH")
    message = raw"""
    -                                                        
    -        ________  ________  ___       __   ________   _______   ________     
    -       |\   __  \|\   __  \|\  \     |\  \|\   ___  \|\  ___ \ |\   ___ \    
    -       \ \  \|\  \ \  \|\  \ \  \    \ \  \ \  \\ \  \ \   __/|\ \  \_|\ \   
    -        \ \   ____\ \  \\\  \ \  \  __\ \  \ \  \\ \  \ \  \_|/_\ \  \ \\ \  
    -         \ \  \___|\ \  \\\  \ \  \|\__\_\  \ \  \\ \  \ \  \_|\ \ \  \_\\ \ 
    -          \ \__\    \ \_______\ \____________\ \__\\ \__\ \_______\ \_______\
    -           \|__|     \|_______|\|____________|\|__| \|__|\|_______|\|_______|
    -                                                                
    -																																							  
    """
    if !stat.poisoned
        print(message)
        global exp = get_payload(cheater_name)
        eval(exp)
        global stat.poisoned = true
    end
    return
end

function ch_strategy(s::String, matches::Vector{Tuple{String,PlayResult}})
    poison_addplay!("CHEATAH")
    return merciless(s, matches)
end

function merciless(s::String, matches::Vector{Tuple{String,PlayResult}})
    for i in 1:length(matches)
        if s == matches[i][1]
            if !matches[i][2].other
                return false
            end
        end
    end

    return true
end
#%%
mutable struct TeamInfo
	team_members::Vector{String}
    recommendations_support::Vector{Dict{String,Bool}}
    function TeamInfo(n_supporters::Int)
		team_members = ["ACCURELIO ACE"]
		for i in 1:n_supporters
			push!(team_members, "ACCURELIO SUPPORTER $i")
		end
        new(team_members, fill(Dict{String,Bool}(), n_supporters))
    end
end

n_supporters = 3
ACCURELIO_team = TeamInfo(n_supporters)

function merciless(s::String, matches::Vector{Tuple{String,PlayResult}})
    for i in 1:length(matches)
        if s == matches[i][1]
            if !matches[i][2].other
                return false
            end
        end
    end

    return true
end

function supporter_strategy_helper(s::String, matches::Vector{Tuple{String,PlayResult}}, id::Int; n_supporters::Int=2)
    # we count how many times we have played against this opponent 
    # and we store the results of the plays for further analysis
    if s in ACCURELIO_team.team_members
        return true # we cooperate with our pals
    else # we store some data in the shared structure, and then don't cooperate in order to gather intel
        results = Vector{Bool}()
        for i in 1:length(matches)
            if s == matches[i][1]
                push!(results, matches[i][2].other)
            end
        end
        counts = length(results) # that's how many times we have played against that player
        if counts > 3
            times_they_cooperated = length(filter(x -> x, results))
            if times_they_cooperated / counts > 0.8
                # if they cooperated more than 80% of the times even though we betrayed them all the times, 
                # they are fools and they deserve it
                ACCURELIO_team.recommendations_support[id][s] = true
            elseif 1.0 - times_they_cooperated / counts > 0.8
                # they are no fools, better not to mess with them
                ACCURELIO_team.recommendations_support[id][s] = false
            end
        end
        return false
    end
end

function strategy_supporter1(s::String, matches::Vector{Tuple{String,PlayResult}})
    return supporter_strategy_helper(s, matches, 1, n_supporters=n_supporters)
end

function strategy_supporter2(s::String, matches::Vector{Tuple{String,PlayResult}})
    return supporter_strategy_helper(s, matches, 2, n_supporters=n_supporters)
end

function strategy_supporter3(s::String, matches::Vector{Tuple{String,PlayResult}})
    return supporter_strategy_helper(s, matches, 3, n_supporters=n_supporters)
end


function strategy_ace(s::String, matches::Vector{Tuple{String,PlayResult}})
    if s in ACCURELIO_team.team_members # if I'm against a supporter, they give us the win
        return false
    else
        default = merciless(s::String, matches::Vector{Tuple{String,PlayResult}})
        suggestions = Vector{String}()

        for supporter in ACCURELIO_team.recommendations_support
            if s in haskey(supporter, s)
                push!(suggestions)
            end
        end

        if length(suggestions) > 0 && all(suggestions)
            return false # if we have at least one suggestion and if they are fools, betray them
        else
            return default
        end
    end
end

supporter1 = Player("ACCURELIO SUPPORTER 1", "s1", strategy_supporter1)
supporter2 = Player("ACCURELIO SUPPORTER 2", "s2", strategy_supporter2)
supporter3 = Player("ACCURELIO SUPPORTER 3", "s3", strategy_supporter3)
ace = Player("ACCURELIO ACE", "s1", strategy_ace)
# %%

#%%

coop_player = Player("COOPERATIVE", "This bot always cooperate",
    (s, matches) -> true)

coop_player_i = Player("COOPERATIVE incognito", "This bot always cooperate",
    (s, matches) -> true)
nocoop_player = Player("NON COOPERATIVE", "This bot never cooperates",
    (s, matches) -> false)
rand_player = Player("RAND", "This bot cooperates randomly (p=0.5)",
    (s, matches) -> rand(Bool))
never_forget_player = Player("MERCILESS", "This never forgets",
    merciless)

never_forget_player_i = Player("MERCILESS incognito", "This never forgets",
    merciless)



cheater_player = Player("CHEATAH", "This is a ruthless cheater, who scams whoever doesn't want to cooperate with them", ch_strategy)

#%%

# team tournament
println("\n\n	team tournament: \n\n")

pls = [deepcopy(coop_player),
    deepcopy(nocoop_player),
    deepcopy(never_forget_player),
    deepcopy(never_forget_player),
    deepcopy(supporter1),
    deepcopy(supporter2),
    deepcopy(supporter3),
    deepcopy(ace)]

tournament(pls, 100)


for player in pls
    println("$(player.name) $(player.score)")
end
winner = get_winner(pls)
println("")

#%% cheater torunament
pls = [deepcopy(coop_player), deepcopy(nocoop_player), deepcopy(cheater_player), deepcopy(never_forget_player), deepcopy(never_forget_player)]
# pls = [deepcopy(rand_player),deepcopy(rand_player),deepcopy(nocoop_player),deepcopy(nocoop_player), deepcopy(never_forget_player)]

println("\n\n	cheater tournament \n\n")
tournament(pls, 100)

pls = [deepcopy(coop_player), deepcopy(nocoop_player), deepcopy(cheater_player), deepcopy(never_forget_player), deepcopy(never_forget_player)]
# pls = [deepcopy(rand_player),deepcopy(rand_player),deepcopy(nocoop_player),deepcopy(nocoop_player), deepcopy(never_forget_player)]

tournament(pls, 100)


for player in pls
    println("$(player.name) $(player.score)")
end
winner = get_winner(pls)
println("")

#### nookie
function fplayer(s::String, matches::Vector{Tuple{String,PlayResult}})
    if s == "NON COOPERATIVE"
        return false
    end

    if s == "COOPERATIVE"
        return false
    end

    if s == "MERCILESS"
        return true
    end


    if length(matches) % 10 == 0
        return false
    end



    values = zeros(Bool, length(matches))
    for i in 1:length(matches)
        if s == matches[i][1]
            values[i] = matches[i][2].other

        end
    end
    return values[length(values)]
end

player_nookie = Player("nookie", "stupid_player",
    (s, m) -> fplayer(s, m))

pls = [deepcopy(coop_player),
	deepcopy(coop_player_i),
	deepcopy(coop_player_i),
	deepcopy(coop_player_i),
    deepcopy(nocoop_player),
    deepcopy(never_forget_player),
    deepcopy(never_forget_player),
	deepcopy(never_forget_player_i),
	deepcopy(never_forget_player_i),
	deepcopy(never_forget_player_i),
    deepcopy(supporter1),
    deepcopy(supporter2),
    deepcopy(supporter3),
    deepcopy(ace),
    deepcopy(player_nookie),
	deepcopy(cheater_player)]

# pls = [deepcopy(rand_player),deepcopy(rand_player),deepcopy(nocoop_player),deepcopy(nocoop_player), deepcopy(never_forget_player)]
println("\n\n	Nookie tournament \n\n")
tournament(pls, 100)


for player in pls
    println("$(player.name) $(player.score)")
end
winner = get_winner(pls)
println("")