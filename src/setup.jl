# setup.jl
# functions involved in setting up the models

"""
    protest_treatmentcategories(x)

(For use as input to match!)
Protest treatment history categories.
We look at total count in the pre-treatment crossover
period for both the treated unit and its (potential) match.
If the totals, for each, in the same period fall into the same cateory,
we allow the match.
"""
function protest_treatmentcategories(x)
  if x == 0; g = 0 end
  if (x == 1) | (x == 2); g = 1 end
  if (x > 2) & (x < 10); g = 2 end
  if (x >= 10); g = 3 end
  return g
end

"""
    rally_treatmentcategories(x)

(For use as input to match!)
Rally treatment history categories.
We look at total count in the pre-treatment crossover
period for both the treated unit and its (potential) match.
If the totals, for each, in the same period fall into the same cateory,
we allow the match.

The exposures are accounted for directly in match!
"""
function rally_treatmentcategories(x)
  return x <= 0 ? 0 : 1
end

"""
    covariateset(vn::VariableNames, outcome::Symbol; modeltype::String = "epi")

Return the covariates for the specified model type ("epi", "nomob", "full").
"""
function covariateset(
  vn::VariableNames, outcome::Symbol;
  modeltype::Symbol = :epi
)

  epi = modeltype == :epi
  nomob = modeltype == :nomob
  full = modeltype == :full

  deathrte = outcome == :death_rte
  caserte = outcome == :case_rte
  rt = outcome == :Rt

  if epi & deathrte
    return [vn.cdr, vn.pd, vn.fc]
  elseif epi & caserte
    return [vn.ccr, vn.pd, vn.fc]
  elseif nomob & deathrte
    return [vn.cdr, vn.fc, vn.pd, vn.pbl, vn.phi, vn.ts16, vn.mil, vn.p65];
  elseif nomob & caserte
    return [vn.ccr, vn.fc, vn.pd, vn.pbl, vn.phi, vn.ts16, vn.mil, vn.p65];
  elseif full & deathrte
    return [
      vn.cdr, vn.fc, vn.pd, vn.res, vn.groc,
      vn.rec, vn.pbl, vn.phi, vn.ts16, vn.mil, vn.p65
    ];
  elseif full & caserte
    return [
      vn.ccr, vn.fc, vn.pd, vn.res, vn.groc,
      vn.rec, vn.pbl, vn.phi, vn.ts16, vn.mil, vn.p65
    ];
  elseif full & rt
    return [
      vn.rt, vn.fc, vn.pd, vn.res, vn.groc,
      vn.rec, vn.pbl, vn.phi, vn.ts16, vn.mil, vn.p65
    ];
  elseif nomob & rt
    return [vn.rt, vn.fc, vn.pd, vn.pbl, vn.phi, vn.ts16, vn.mil, vn.p65];
  elseif epi & rt
    return [vn.rt, vn.pd, vn.fc]
  end
end

