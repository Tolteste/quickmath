package dk.sdu.mdsd.generator;

import java.util.List;

import dk.sdu.mdsd.quickMath.Expression;

public class FunctionScope {
	private List<String> parameters;
	private Expression exp;
	
	public FunctionScope(List<String> par, Expression exp) {
		this.parameters = par;
		this.exp = exp;
	}
	
	public List<String> getParameters() {
		return parameters;
	}
	public void setParameters(List<String> parameters) {
		this.parameters = parameters;
	}
	public Expression getExp() {
		return exp;
	}
	public void setExp(Expression exp) {
		this.exp = exp;
	}
}
