package dk.sdu.mdsd.generator

import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import dk.sdu.mdsd.quickMath.QuickMath
import dk.sdu.mdsd.quickMath.Compute
import dk.sdu.mdsd.quickMath.Plot
import dk.sdu.mdsd.quickMath.Assignment
import java.util.HashMap
import dk.sdu.mdsd.quickMath.Expression
import dk.sdu.mdsd.quickMath.Num
import dk.sdu.mdsd.quickMath.Div
import dk.sdu.mdsd.quickMath.Mult
import dk.sdu.mdsd.quickMath.Plus
import dk.sdu.mdsd.quickMath.Minus
import dk.sdu.mdsd.quickMath.Sin
import dk.sdu.mdsd.quickMath.Var
import dk.sdu.mdsd.quickMath.Fun
import java.util.Map
import java.util.List
import java.util.ArrayList
import dk.sdu.mdsd.quickMath.Interval

class QuickMathGenerator extends AbstractGenerator {
	
	private Map<String,FunctionScope> variables = new HashMap<String,FunctionScope> 
	
	override doGenerate(Resource input, IFileSystemAccess2 fsa, IGeneratorContext context) {
		val result = input.allContents.filter(QuickMath).next
		for (command : result.quickMath) {
			switch command {
				Compute: command.process
				Plot: command.process
				Assignment: command.process
			}
			
		}
	}
	
	def process(Compute cmpt){
		val funScope = variables.get(cmpt.fun.name)
		val par = new HashMap<String,Double>()
		val parNames = funScope.parameters
		// iterating through all supplied parameters
		for(range : cmpt.varRange){
			switch range {
				Expression: 
				for(parName : parNames) {
					par.put(parName, range.computeExp(null))
					}
				Interval: 
				//TODO: implement intervals
				return
			}
		}
		println(funScope.exp.computeExp(par))
	}	
	
	def process(Plot plot){
		
	}
	
	def process(Assignment assign){
		val parameters = new ArrayList<String>()
		for(parameter : assign.name.variables){
			parameters.add(parameter.name)
		}
		val scope = new FunctionScope(parameters,assign.exp)
		variables.put(assign.name.name,scope)
		
	}
	
	def double computeExp(Expression exp,HashMap<String,Double> par) {
		switch exp {
			Plus: exp.left.computeExp(par)+exp.right.computeExp(par)
			Minus: exp.left.computeExp(par)-exp.right.computeExp(par)
			Mult: exp.left.computeExp(par)*exp.right.computeExp(par)
			Div: exp.left.computeExp(par)/exp.right.computeExp(par)
			Sin: Math.sin(exp.exp.computeExp(par))
			Num: exp.convertToDouble()
			Var: {
				// extracting value for local parameter
				val local = par.get(exp.id)
				if( local !== null){
					return local
				}else{
					//extracting value from global environment
					//TODO: check if not null
					return variables.get(exp.id).exp.computeExp(null)
				}
			}
			Fun: {
				val fun = variables.get(exp.name)
				if (fun !== null){
					//compute parameters
					val passParameters = new HashMap<String,Double>
					var i=0
					//TODO: Check if number of parameters in global scope == to number of passed arguments
					for(parameter : exp.parameters){
						passParameters.put(fun.parameters.get(i),parameter.computeExp(par))
						i++
					}
					fun.exp.computeExp(passParameters)
				}
			}
			
		}
	}
	
	def double convertToDouble(Num num){
		var str = ""
		if(num.minus !== null){
			str+="-"
		}
		str+=num.left+"."+num?.right
		Double.parseDouble(str)
	}
}