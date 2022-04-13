# plotting.jl

function mk_covpal(vn::VariableNames)

  pal = TSCSMethods.gen_colors(vn.N);

  variablecolors = Dict(
    vn.cdr => pal[3],
    vn.ccr => pal[5],
    vn.fc => pal[2],
    vn.pd => pal[1],
    vn.res => pal[4],
    vn.groc => pal[12],
    vn.rec => pal[6],
    vn.pbl => pal[7],
    vn.phi => pal[8],
    vn.ts16 => pal[9],
    vn.mil => pal[10],
    vn.p65 => pal[11],
    vn.rare => TSCSMethods.gen_colors(13)[13]
  );
  return variablecolors
end

# old stuff, possibly needed

function labdict(model)
  svl = Symbol(string(model.stratvar) * " Stratum")
  dd = unique(model.matches[!, [svl, :stratlab]])
  dd = Dict(dd[!, svl] .=> dd[!, :stratlab])
  return dd
end

function extrtinfo!(UC, model, mname; refpth = false)
  stratified = length(string(model.stratvar)) > 0 ? true : false

  speci = namespec(mname);
  eventype = nameevent(mname);
  calval = contains(mname, "cal") ? "yes" : "no"
  calbool = contains(mname, "cal")

  if !(refpth == false) & calbool & stratified
    refmod = JLD2.load_object(refpth * replace(mname, "cal" => "") * ".jld2")
  end

  if !stratified
    # [name, stratum, label, type, value]
    push!(
      UC,
      [eventype, speci, calval, mname, -1, "", "n", model.treatednum]
    )
    push!(UC,
      [eventype, speci, calval, mname, -1, "", "l", model.treatedleft]
    )
  elseif stratified
    if (refpth == false) | !calbool
      # makes it way slow, refine beforehand
      # if !calbool
      #   TSCSMethods.refine!(model);
      # end
      ldict = labdict(model);
    else
      # makes it way slow, refine beforehand
      # TSCSMethods.refine!(refmod);
      ldict = labdict(refmod);
    end

    for (k1, v1) in model.treatednum
      push!(
        UC,
        [eventype, speci, calval, mname, k1, ldict[k1], "n", v1]
      )
    end
    for (k2, v2) in model.treatedleft
      push!(
        UC,
        [eventype, speci, calval, mname, k2, ldict[k2], "l", v2]
      )
    end
  end
  return unique(UC)
end

function UCdf()
  trt = DataFrame(
    event = String[],
    specification = String[],
    caliper = String[],
    name = String[],
    stratum = Int64[],
    label = String[],
    type = String[],
    value = Int64[],
  );
  return trt
end

function mktrtnumdf(UC)
  trt = DataFrame(
      name = String[],
      stratum = Int64[],
      type = String[],
      value = Int64[],
  );

  # k =  "ga voting added_death_rte_Trump 2016 Vote Share__model";
  # v = UC[k];

  for (k, v) in UC
      if typeof(v) == Tuple{Int64, Int64}
          push!(trt, [k, 1, "n", v[1]])
          push!(trt, [k, 1, "l", v[2]])
      else
          for (k1, v1) in v[1]
              push!(trt, [k, k1, "n", v1])
          end
          for (k2, v2) in v[2]
              push!(trt, [k, k2, "l", v2])
          end
      end
  end
  return trt
end

function namespec(obs)
  if contains(obs, "epi.")
    ot = "Epi."
  elseif contains(obs, "no mob.")
    ot = "No Mob."
  elseif contains(obs, "added")
    ot = "Added."
  else
    ot = "Full"
  end
  return ot
end

function nameevent(obs)
  if contains(obs, "ga")
    ot = "GA Special"
  elseif contains(obs, "voting") & !contains(obs, "ga")
    ot = "Primary"
  elseif contains(obs, "trump")
    ot = "Trump Rally"
  elseif contains(obs, "protest")
    ot = "BLM Protest"
  end
  return ot
end
