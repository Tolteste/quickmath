package dk.sdu.mdsd.generator

import dk.sdu.mdsd.quickMath.Assignment
import dk.sdu.mdsd.quickMath.Compute
import dk.sdu.mdsd.quickMath.Div
import dk.sdu.mdsd.quickMath.Expression
import dk.sdu.mdsd.quickMath.Fun
import dk.sdu.mdsd.quickMath.Interval
import dk.sdu.mdsd.quickMath.Minus
import dk.sdu.mdsd.quickMath.Mult
import dk.sdu.mdsd.quickMath.Name
import dk.sdu.mdsd.quickMath.Num
import dk.sdu.mdsd.quickMath.Plot
import dk.sdu.mdsd.quickMath.Plus
import dk.sdu.mdsd.quickMath.QuickMath
import dk.sdu.mdsd.quickMath.Range
import dk.sdu.mdsd.quickMath.Sin
import dk.sdu.mdsd.quickMath.Var
import java.util.ArrayList
import java.util.HashMap
import java.util.Map
import org.eclipse.emf.common.util.EList
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.knowm.xchart.BitmapEncoder
import org.knowm.xchart.BitmapEncoder.BitmapFormat
import org.knowm.xchart.QuickChart
import org.knowm.xchart.SwingWrapper
import javax.swing.WindowConstants
import dk.sdu.mdsd.quickMath.Cos

class QuickMathGenerator extends AbstractGenerator {
	
	// Global environment for specific sheet
	private Map<String,FunctionScope> variables = new HashMap<String,FunctionScope> 
	private String name
	
	override doGenerate(Resource input, IFileSystemAccess2 fsa, IGeneratorContext context) {
		val result = input.allContents.filter(QuickMath).next
		name = result.name
		for (command : result.quickMath) {
			switch command {
				Compute: command.process
				Plot: command.process
				Assignment: command.process
			}
			
		}
	}
	
	def process(Compute cmpt) {
		val values = computeFunction(cmpt.fun.name,cmpt.varRange)
		printValues(cmpt.fun.variables,values)
	}
	
	def process(Plot plot) {
		val values = computeFunction(plot.fun.name,plot.varRange)
		if(plot.varRange.size == 1){
			val double[] xData = newDoubleArrayOfSize(values.size)
			val double[] yData = newDoubleArrayOfSize(values.size)
			var i = 0
			for (v : values) {
				xData.set(i,v.get(0).doubleValue)
				yData.set(i,v.get(1).doubleValue)
				i++
			}
			val xname = plot.varRange.get(0).^var
			val funName = plot.fun.name + "(" + xname + ")"
			
			val chart = QuickChart.getChart(name, xname , "Y", funName , xData, yData)
			// Show it
			new SwingWrapper(chart).displayChart().setDefaultCloseOperation(WindowConstants.HIDE_ON_CLOSE)
			// Save it
			BitmapEncoder.saveBitmap(chart, "./" + name, BitmapFormat.PNG)
		}
	}
	
	def process(Assignment assign){
		val parameters = new ArrayList<String>()
		for(parameter : assign.name.variables){
			parameters.add(parameter.name)
		}
		val scope = new FunctionScope(parameters,assign.exp)
		variables.put(assign.name.name,scope)
		
	}
	
	def Double[][] computeFunction(String funName, EList<Range> varRange ){
		val funScope = variables.get(funName)
		val par = new HashMap<String, Double>()
		val parNames = funScope.parameters
		// compute number of steps in supplied intervals 
		// /!!! NOT CHECKING IF INTERVALS HAS SAME AMMOUNT OF STEPS
		val steps = computeLocalSteps(varRange)
		var i = 0
		val result = newArrayList

		for (i = 0; i < steps; i++) {
			// iterating through all supplied parameters
			val stepResult = newArrayList
			var k = 0
			for (rng : varRange) {
				// getting to actual range values encapsulated in Range object
				val range = rng.range
				switch range {
					Expression:
						if(!par.containsKey(parNames.get(k))){
							par.put(parNames.get(k), range.computeExp(null))
						}	
					Interval: {
						par.put(parNames.get(k), range.lowerBound.computeExp(null) + i * rng.step.computeExp(null))
					}
				}
				stepResult.add(par.get(parNames.get(k)))
				k++
			}
			stepResult.add(funScope.exp.computeExp(par))
			result.add(stepResult)
		}
		return result
	}
	
	def int computeLocalSteps(EList<Range> list) {
		for (rng : list) {
			val range = rng.range
			switch range {
				Interval: {
					val lower = range.lowerBound.computeExp(null)
					val upper = range.upperBound.computeExp(null)
					val stepSize = rng.step.computeExp(null)

					return ((upper - lower) / stepSize).intValue
				}
			}
		}
		return 1
	}	
	
	def double computeExp(Expression exp,HashMap<String,Double> par) {
		switch exp {
			Plus: exp.left.computeExp(par)+exp.right.computeExp(par)
			Minus: exp.left.computeExp(par)-exp.right.computeExp(par)
			Mult: exp.left.computeExp(par)*exp.right.computeExp(par)
			Div: exp.left.computeExp(par)/exp.right.computeExp(par)
			Sin: Math.sin(exp.exp.computeExp(par))
			Cos: Math.cos(exp.exp.computeExp(par))
			Num: exp.convertToDouble()
			Var: {
				// if we have variable in supplied parameters get the value
				// otherwise try to extract variable from global environment
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
	
	def printValues(EList<Name> names,Double[][] values){
		for(name : names){
			print(name.name + ":		")
		}		
		print("result:\n")
		for(var i=0;i<values.length;i++){
			for(var k=0;k<values.get(i).length;k++){
				print(values.get(i).get(k) + "		")
			}
			print("\n")
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