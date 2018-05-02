package dk.sdu.mdsd.generator

import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import dk.sdu.mdsd.quickMath.QuickMath
import dk.sdu.mdsd.quickMath.Compute
import dk.sdu.mdsd.quickMath.Plot
import dk.sdu.mdsd.quickMath.Assignment

class QuickMathGenerator extends AbstractGenerator {
	
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
		
	}	
	
	def process(Plot plot){
		
	}
	
	def process(Assignment assign){
		
	}
}