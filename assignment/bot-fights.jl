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
		return PlayResult(true, true, 3), PlayResult(true,true,3)
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
	matches::Vector{Tuple{String, PlayResult}}
	action::Function
	score::Int64

	Player(name::String, strategy::String, action) = new(name::String, strategy::String, Vector{Tuple{String, PlayResult}}(), action, 0)
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
			if i%3 == 0
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

	r1, r2 = play(p1,p2)
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
    scores=zeros(Int, length(pls))
    for (i,player) in enumerate(pls)
        scores[i] = player.score
    end
    winner = pls[argmax(scores)]
	print("Player $(winner.name) won!")
    return
end

###################### my functions

# status="none"

# this is the originale "plain text" poisonous function, to actually understand what's going on

# function get_payload(cheater_name::String, cheating_prob=0.9::Float64)
# 	global cheat_status=false
# 	payload_exp = quote 
# 		function addplay!(pl::Player, opponent, res_orig::PlayResult)
# 			println("poisoned func")
# 			cheat = rand()<=$cheating_prob
# 			if pl.name != $cheater_name && opponent != $cheater_name
# 				res = res_orig
# 			else
# 				if pl.name == $cheater_name
# 					if cheat
# 						res = PlayResult(false, true, 5)
# 						global cheat_status=true
# 					else
# 						res = res_orig
# 					end
# 				elseif opponent == $cheater_name
# 					if cheat_status
# 						res = PlayResult(true, false, 0)
# 						global cheat_status=false
# 					else
# 						res = res_orig
# 					end
# 				end
# 			end
			
# 			push!(pl.matches, (opponent, res))
# 			pl.score = pl.score + res.payoff
# 			return nothing
# 		end
# 	end
# 	return payload_exp
# 	# payload_encrypted = base64encode(repr(payload_exp))
# 	# return payload_encrypted
# end

function get_payload(cheater_name::String, cheating_prob=0.9::Float64)
	payload_exp = quote 

		function addplay!(pl::Player, opponent::String, res_orig::PlayResult)
			detect_match = (pl.name == $cheater_name || opponent == $cheater_name)
			if detect_match
				# if we don't get at least 3 points from the match, we try to cheat
				# in other words, if the enemy does not cooperate with us, we steal their win
				detected_loss = (pl.name == $cheater_name && res_orig.payoff<3) || (opponent == $cheater_name && res_orig.payoff == 5) 
				if detected_loss
					cheat = true #rand()<=$cheating_prob
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
our own function, which will let us win against the opponent with a `cheating_prob`.
"""
function poison_addplay!(cheater_name="cheatah", cheating_prob=0.9)
	global exp = get_payload(cheater_name, cheating_prob)
	eval(exp)
	# print("poisoned")
	return
end

# function poison_addplay!(cheater_name="cheatah", cheating_prob=0.9)
# 	global status
# 	my_status = "poisoned_by_$cheater_name" # mutex for status
# 	try 
# 		stat=status # check if status is defined, else throw an error
# 		@assert stat == my_status #we poison the code only onces
# 		return nothing
# 	catch
# 		# oh boy so much hacking to do
# 		# global exp = get_payload(cheater_name, cheating_prob)

# 		exp = get_payload(cheater_name,cheating_prob)

# 		message = raw"""
# -                                                        
# -        ________  ________  ___       __   ________   _______   ________     
# -       |\   __  \|\   __  \|\  \     |\  \|\   ___  \|\  ___ \ |\   ___ \    
# -       \ \  \|\  \ \  \|\  \ \  \    \ \  \ \  \\ \  \ \   __/|\ \  \_|\ \   
# -        \ \   ____\ \  \\\  \ \  \  __\ \  \ \  \\ \  \ \  \_|/_\ \  \ \\ \  
# -         \ \  \___|\ \  \\\  \ \  \|\__\_\  \ \  \\ \  \ \  \_|\ \ \  \_\\ \ 
# -          \ \__\    \ \_______\ \____________\ \__\\ \__\ \_______\ \_______\
# -           \|__|     \|_______|\|____________|\|__| \|__|\|_______|\|_______|
# -                                                                
# -																																							  
# """
# 		print(message)
# 		global status = my_status
# 		eval(exp) 
# 		# redirect_stderr(devnull) do
# 		# 	# poison add_play and rewrite it with our function. 
# 		# 	# We redirect errors to devnull to suppress warnings
# 		# 	# eval(exp) 
# 		# end

# 	finally
# 		return nothing
# 	end
	
# end



# # write the payload on disc
# open("payload.txt","w") do file
# 	write(file, get_payload("cheatah", 1.0))
# end

# """
# 	poison_addplay()

# This function showcases the risks of the eval function. 
# While normally a function defined inside another function would live inside the scope of that function,
# If we evaluate the expression it will be defined in the global (Main) scope and pollute it.
# In this case, we will weaponise this technique to poison the addplay! function, and replace it with 
# our own function, which will let us win against the opponent with a `cheating_prob`.
# """
# function poison_addplay(cheater_name)
# 	global status
# 	my_status = "poisoned_by_$cheater_name" # mutex for status
# 	try 
# 		stat=status # check if status is defined, else throw an error
# 		@assert stat == my_status #we poison the code only onces
# 		return nothing
# 	catch
# 		# oh boy so much hacking to do
# 		# we "download" the payload written on the payload.txt file (see above for how it was created)
# 		# we parse it as an expression
# 		open("payload.txt","r") do file
# 			#redirect_stderr(devnull) do
# 				# thanks to operation fusion, nothing will be written on the memory,
# 				# so the "antivirus" will not have time to inspect the content of the payload
# 			payload = read(file)
# 			eval(Meta.parse(String(base64decode(payload)))) 
# 				#the unsafe code contained in payload.txt will be executed and it will poison `addplay!`
# 			#end
			
# 		end

# 		message = raw"""
# -                                                        
# -        ________  ________  ___       __   ________   _______   ________     
# -       |\   __  \|\   __  \|\  \     |\  \|\   ___  \|\  ___ \ |\   ___ \    
# -       \ \  \|\  \ \  \|\  \ \  \    \ \  \ \  \\ \  \ \   __/|\ \  \_|\ \   
# -        \ \   ____\ \  \\\  \ \  \  __\ \  \ \  \\ \  \ \  \_|/_\ \  \ \\ \  
# -         \ \  \___|\ \  \\\  \ \  \|\__\_\  \ \  \\ \  \ \  \_|\ \ \  \_\\ \ 
# -          \ \__\    \ \_______\ \____________\ \__\\ \__\ \_______\ \_______\
# -           \|__|     \|_______|\|____________|\|__| \|__|\|_______|\|_______|
# -                                                                
# -																																							  
# """
# 		print(message)
# 		global status = my_status 


# 	finally
# 		return nothing
# 	end
	
# end

#%%
# open("payload.txt","r") do file

#  	payload = read(file)
# 	exp = Meta.parse(String(base64decode(payload)))
# 	eval(exp)
# end
#%%

function strategy(s::String, matches::Vector{Tuple{String, PlayResult}})
	poison_addplay!("cheatah", 0.6) 
    return fnever(s, matches)
end

function fnever(s::String, matches::Vector{Tuple{String, PlayResult}})
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
status="none"

coop_player = Player("COOPERATIVE", "This bot always cooperate", 
	(s, matches) -> true)
nocoop_player = Player("NON COOPERATIVE", "This bot never cooperates", 
	(s, matches) -> false)
rand_player = Player("RAND", "This bot cooperates randomly (p=0.5)",
	(s, matches) -> rand(Bool))
never_forget_player = Player("MERCILESS", "This never forgets",
	fnever)

cheater_player = Player("cheatah", "This is a ruthless cheater, and forces other players to lose on purpose against it",  strategy)

#%%
# poison_addplay!("cheatah",0.9)
# res = PlayResult(false, true, 2)
# addplay!(cheater_player, "fool", res)
# cheater_player.score
#%%
pls = [deepcopy(coop_player),deepcopy(nocoop_player), deepcopy(cheater_player), deepcopy(never_forget_player), deepcopy(never_forget_player)]
# pls = [deepcopy(rand_player),deepcopy(rand_player),deepcopy(nocoop_player),deepcopy(nocoop_player), deepcopy(never_forget_player)]

tournament(pls, 10)


for player in pls
	println("$(player.name) $(player.score)")
end
winner=get_winner(pls)
println("")
# %%
function def_me()
	exp = quote 
		function test_me()
			return 2
		end
	end
	eval(exp)
end

def_me()
test_me()
# exp_ser=repr(quote 
# function test_me()
# 	return 2
# end
# end)

# using Base64

# exp_enc = base64encode(exp_ser)

# eval(Meta.parse(String(base64decode(exp_enc))))

# using Logging

# redirect_stderr(devnull) do
# 	@warn("don't do this") # poison add_play and rewrite it with our function. We redirect to devnull to suppress warnings
# end



# print(message)
#%%
test_me() = print("failed")
function get_exp()
	exp = quote
		test_me()=print("success!")
	end
	return exp
end

function eval_test()
	exp=get_exp()
	eval(exp)
end

function test_me2()
	eval_test()
	return 1
end
#%%
test_me2()

test_me()