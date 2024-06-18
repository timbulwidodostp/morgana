*! MJC

program morgana_ll
	version 18
	args lden ${eqns}
	mata: morgana_ll()
end


version 18
mata:
	
void morgana_ll()
{
	struct merlin_struct scalar gml
	
	gml 	= *findexternal(st_global("object"))
	eqns 	= tokens(st_global("eqns"))
	Neqns 	= cols(eqns)
	newb 	= J(1,Neqns,.)
	for (i=1;i<=Neqns;i++) newb[1,i] = st_numscalar(st_local(eqns[1,i]))

	gml.myb = newb
	merlin_xb(gml,gml.myb)

	gml.survind = gml.todo = 0
	if 	(gml.familys=="rp") {
		lnl = quadcolsum(merlin_logl_rp(gml,G,H),1)
	}
	else if	(gml.familys=="loghazard") {
		lnl = quadcolsum(merlin_logl_loghazard(gml,G,H),1)
	}
	else if	(gml.familys=="addhazard") {
		lnl = quadcolsum(merlin_logl_addhazard(gml,G,H),1)
	}
	else if (gml.familys=="exponential") {
		lnl = quadcolsum(merlin_logl_exp(gml,G,H),1)
	}
	else if (gml.familys=="weibull") {
		lnl = quadcolsum(merlin_logl_weibull(gml,G,H))
	}
	else if (gml.familys=="gompertz") {
		lnl = quadcolsum(merlin_logl_gompertz(gml,G,H))
	}
	else if	(gml.familys=="lognormal") {
		lnl = quadcolsum(merlin_logl_survival_ob(gml,G,H),1)
	}
	else if	(gml.familys=="loglogistic") {
		lnl = quadcolsum(merlin_logl_survival_ob(gml,G,H),1)
	}
	else if	(gml.familys=="ggamma") {
		lnl = quadcolsum(merlin_logl_survival_ob(gml,G,H),1)
	}
	else if (gml.familys=="logchazard") {
		lnl = quadcolsum(merlin_logl_logchazard(gml,G,H),1)
	}
	else if	(gml.familys=="cox") {
		lnl = quadcolsum(merlin_logl_cox(gml,G,H),1)
	}
	
	st_numscalar(st_local("lden"),lnl)
}
	
end
