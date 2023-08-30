auto parseExp(ref string exp) {
    import std.range: front;
    import std.ascii: isDigit;
    
    auto ch = exp.front;
    if (ch == '(') {
    	return parseGroup(exp);
    }
    if (ch.isDigit) {
    	return parseNumber(exp);
    }
    assert(0);
}

auto parseNumber(ref string exp) {
	import conv = std.conv;
    
    return conv.parse!int(exp);
}

int parseGroup(ref string exp) {
    import std.range: front, popFront;
    
	assert(exp.front == '(');
    exp.popFront;
    auto res = exp.parseExp;
    assert(exp.front == ')');
    exp.popFront;
    return res;
}

auto parse(string input) {
	import std.range : empty;
    
    auto res = parseExp(input);
    assert(input.empty);
    return res;
}


    
string nestedValue(string value, int nestingLevel) {
    import std.range: array, repeat;
    string res;
    res ~= '('.repeat(nestingLevel).array; 
    res ~= value; 
    res ~= ')'.repeat(nestingLevel).array;
    return res;
}

int main() {

	import std.stdio: writeln;
    
    writeln(parse("(5)"));
    writeln(parse("(((4)))"));
    writeln(parse("10".nestedValue(10)));
    return 0;
}