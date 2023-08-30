module recurse_parse_call_util;

class PlainCallUtil
{
    static auto call(alias func, Args...)(auto ref Args args)
    {
        return func(args);
    }

    static auto run(alias func, Args...)(auto ref Args args)
    {
        return func(args);
    }
}

alias CallUtil = PlainCallUtil;

auto parseExp(ref string exp) {
    import std.range: front;
    import std.ascii: isDigit;
    
    auto ch = exp.front;
    if (ch == '(') {
    	return CallUtil.call!parseGroup(exp);
    }
    if (ch.isDigit) {
    	return CallUtil.call!parseNumber(exp);
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
    
    auto res = CallUtil.call!parseExp(input);
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
    writeln(CallUtil.run!parse("(5)"));
    writeln(CallUtil.run!parse("(((4)))"));
    writeln(CallUtil.run!parse("10".nestedValue(10)));
    writeln(CallUtil.run!parse("200".nestedValue(10^^6)));
    return 0;
}