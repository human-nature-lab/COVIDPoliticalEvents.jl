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
    covariateset(
      vn::VariableNames, reference_outcome::Symbol; modeltype::String = "epi"
    )

Return the covariates for the specified model type ("epi", "nomob", "full").
"""
function covariateset(
  vn::VariableNames, reference_outcome::Symbol;
  modeltype::Symbol = :epi
)

  epi = modeltype == :epi
  nomob = modeltype == :nomob
  full = modeltype == :full

  outmatch = if ((reference_outcome == :death_rte) | (reference_outcome == vn.cdr))
    vn.cdr
  elseif ((reference_outcome == :case_rte) | (reference_outcome == vn.ccr))
    vn.ccr
  elseif reference_outcome == :deathscum
    :deathscum
  elseif reference_outcome == :casescum
    :casescum
  elseif reference_outcome == :Rt
    :Rt
  else
    error("reference_outcome not specified")
  end

  if epi
    return [outmatch, vn.pd, vn.fc]
  elseif nomob
    return [outmatch, vn.fc, vn.pd, vn.pbl, vn.phi, vn.ts16, vn.mil, vn.p65];
  elseif full
    return [
      outmatch, vn.fc, vn.pd, vn.res, vn.groc,
      vn.rec, vn.pbl, vn.phi, vn.ts16, vn.mil, vn.p65
    ];
  end
end

