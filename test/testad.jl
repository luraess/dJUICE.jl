#!/Applications/Julia-1.8.app/Contents/Resources/julia/bin/julia --project
using dJUICE
using MAT
using Test

#Load model from MATLAB file
#file = matopen(joinpath(@__DIR__, "..", "data","temp12k.mat")) #BIG model
file = matopen(joinpath(@__DIR__, "..", "data","temp.mat")) #SMALL model (35 elements)
mat  = read(file, "md")
close(file)
md = model(mat)

#make model run faster 
md.stressbalance.maxiter = 20

#Now call AD!
md.inversion.iscontrol = 1
md.inversion.independent = "FrictionC"

md = solve(md, :sb)

@testset "AD gradient calculation for FrictionC" begin
	addJ = md.results["StressbalanceSolution"]["Gradient"] 
	for i in 1:md.mesh.numberofvertices
		delta = 1e-8
		femmodel=dJUICE.ModelProcessor(md, :StressbalanceSolution)
		J1 = dJUICE.costfunction(femmodel, md.friction.coefficient)
		dα = zero(md.friction.coefficient)
		dα[i] = delta
		femmodel=dJUICE.ModelProcessor(md, :StressbalanceSolution)
		J2 = dJUICE.costfunction(femmodel, md.friction.coefficient+dα)
		dJ = (J2-J1)/delta

		@test abs(dJ - addJ[i])< 1e-6
	end
end
