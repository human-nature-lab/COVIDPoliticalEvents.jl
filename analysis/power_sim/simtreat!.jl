# simtreat!.jl

function simtreat!(outcomes, m, rate_jump, outmap, randomunit, jumpdist)
    # modify the data
    # ((tt, tu), mtch) = collect(zip(m.observations, m.matches))[cnti]
    # (φ, f) = collect(enumerate(m.F))[cntj]
    # cnti = 0
    # cntj = 0
    for ((tt, tu), mtch) in zip(m.observations, m.matches)
        # cnti += 1
        # cntj = 0
        for (φ, f) in enumerate(m.F)
            # cntj += 1

            mus = m.ids[mtch.mus[:, φ]];

            if length(mus) < 1
                continue
            else
                foc = if randomunit | (length(mus) <= 1)
                    pick = rand(mus)

                    # transform the picked matches' by the simulated treatment
                    # using the randomly picked match unit

                    foc = outcomes[get(outmap, (tt + f, pick), 0)[1]];
                    # foc = outcomes[get(outmap, (tt, tu, pick, f), 0.0)]
                    
                    # replace the treated observation values with the selected match's transformed values

                    outcomes[get(outmap, (tt + m.reference, tu), 0)[1]] = outcomes[get(outmap, (tt + m.reference, pick), 0)[1]];

                    # outcomes[outmap[(tt, tu, tu, m.reference)]] = outcomes[outmap[(tt, tu, pick, m.reference)]]

                    foc
                else
                    # transform the picked matches' by the simulated treatment
                    # using the average value of the matches
                    foc = 0.0
                    for mu in mus
                        foc += outcomes[get(outmap, (tt + f, mu), 0)[1]]
                    end
                    foc = foc / length(mus)

                    ##
                    # replace the treated observation values with the 
                    # average value of the matches for the reference
                    refval = 0.0
                    for mu in mus
                        refval += outcomes[get(outmap, (tt + m.reference, mu), 0)[1]]
                        # refval += outcomes[outmap[(tt, tu, mu, m.reference)]]
                    end
                    refval = refval / length(mus)

                    outcomes[get(outmap, (tt + m.reference, tu), 0)[1]] = refval
                    # outcomes[outmap[(tt, tu, tu, m.reference)]] = refval
                    ##

                    foc
                end
                
                # outcomes[outmap[(tt, tu, tu, f)]]
                outcomes[get(outmap, (tt + f, tu), 0)[1]] = if isnothing(jumpdist)
                    # add the constant rate jump
                    foc + rate_jump
                else
                    # add the random rate jump
                    foc + rand(jumpdist)
                end
            end
        end
    end
end