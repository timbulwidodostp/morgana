*! version 1.0.0 ?????2023

/*
dev notes

- starting values need syncing, i.e. always fit the fixed effect model
  -> standard merlin model will use zero vector for a fixed effect only model
- confirm and sync which stmerlin models will be supported
- handling rcs() in equation/parameter names
- some error checks should be in merlin, checking for morgana prefix, so 
  inital fit doesn't complete and then error checking
- which bayesmh options to sync/allow?


*/

program morgana, eclass
	version 18
	
	gettoken colon stmerlin : 0 , parse(":")

	if "`colon'"!=":" {
		gettoken comma bayesopts : colon , parse(",")	
		gettoken colon stmerlin : stmerlin, parse(":")
		
		if "`colon'"!=":" {
			di as error "{p}morgana is a prefix command " ///
				"and requires a {bf::}{p_end}"
			exit 198
		}
	}

	set prefix morgana
	
	if "`: word 1 of `stmerlin''"!="stmerlin" {
		di as error "{p}{bf:morgana} currently only supports " ///
			"use with {bf:stmerlin}{p_end}"
		exit 198
	}
	
	//fill up struct and bail out before estimation
	`stmerlin'

	//global opts
	global object `e(object)'
	
	// extract any prior() statements from bayesopts
	local 0 , `bayesopts'
	syntax , [PRIOR(string) *]
	if "`prior'"!="" {
		local 0 `prior'
		syntax anything [, *] 
		if `: list sizeof anything'>1 {
			di as error "{p}prior(`prior') not supported; " ///
				"you can only specify one variable name" ///
				"at a time{p_end}"
			exit 198
		}
		local priorpriors `anything'
	}
	while "`prior'"!="" {
		local 0 , `options'
		syntax , [PRIOR(string) *]
		if "`prior'"!="" {
			local 0 `prior'
			syntax anything [, *] 
			if `: list sizeof anything'>1 {
				di as error "{p}prior(`prior') not supported; " ///
					"you can only specify one variable name" ///
					"at a time{p_end}"
				exit 198
			}
			local priorpriors `priorpriors' `anything'
		}			
	}
	

	//hard coded for 1 model 

	local i = 1
	local responses `responses' (`: word 1 of `e(response`i')'')
	
	local labels `e(cmplabels`i')'
	
	local cmp = 1
	foreach var in `labels' {
		local cmpj : word `cmp' of `e(Nvars_`i')'
		if `cmpj'==1 {			
			local eqns `eqns' `var'
			local params `params' {`var'}
			if !strpos("`priorpriors'","{`var'}") {
				local priors `priors' ///
					prior({`var'}, normal(0,10000))
			}
			local block`i' `block`i'' {`var'}
		}			
		else {
			local var = subinstr("`var'","()","",.) //!!
			forvalues j=1/`cmpj' {
				local eqns `eqns' `var'`j'
				local params `params' {`var'`j'}
				if !strpos("`priorpriors'","{`var'}") {
					local priors `priors' ///
						prior({`var'`j'}, ///
						normal(0,10000))
				}
				local block`i' `block`i'' {`var'`j'}
			}
		}
		local cmp = `cmp' + 1
	}
	
	if `e(constant`i')'==1 {
		local eqns `eqns' _cons`i'
		local params `params' {_cons`i'}
		if !strpos("`priorpriors'","{`var'}") {
			local priors `priors' ///
				prior({_cons`i'}, normal(0,10000))
		}
		local block`i' `block`i'' {_cons`i'}
	}
	local blocks `blocks' block(`block`i'')
	
	local block`i'
	if `e(ndistap`i')'>0 {
		
		if "`e(family`i')'"=="rp" {
			forvalues dap = 1/`e(ndistap`i')' {
				local eqns `eqns' _rcs`dap'
				if `dap'==1 {
					local params `params' ///
						{_rcs_`i'_`dap'=1}
				}
				else {
					local params `params' ///
						{_rcs_`i'_`dap'}
				}
				if !strpos("`priorpriors'","{`var'}") {
					local priors `priors' ///
						prior({_rcs_`i'_`dap'}, ///
						normal(0,10000))
				}
				local block`i' `block`i'' ///
					{_rcs_`i'_`dap'}
			}	
		}
		
		
	}
	local blocks `blocks' block(`block`i'')
	
	if `e(nap`i')'>0 {
		forvalues ap = 1/`e(nap`i')' {
			local eqns `eqns' mod`i'_ap`ap'
			local params `params' {mod`i'_ap`ap'}
			if !strpos("`priorpriors'","{`var'}") {
				local priors `priors' ///
					prior({mod`i'_ap`ap'}, normal(0,10000))
			}
		}
	}

	global eqns `eqns'
	cap pr drop morgana_ll
	cap n bayesmh `responses', 				///
		noconstant					///
		llevaluator(morgana_ll, parameters(`params'))	///
		`priors'					///
		`blocks'					///
		title(Bayesian survival regression)		///
		`bayesopts'

	capture n mata: merlin_cleanup(st_global("object"))
	capture drop {$object}*
	capture mata: mata drop chazf hazf loglf
	
	if _rc>0 {
		exit `rc'
	}
	
end

