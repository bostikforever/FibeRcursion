module recurse_parse_fiber_call_util;
import core.thread: Fiber;
import std.traits: ReturnType;

struct FiberCallUtil
{

    static ref auto getReturn(alias RType)()
    {
        static RType arr;
        return arr;
    }

    static auto readReturn(alias func)()
    {
        import std.range : back, popBack;

        alias RType = ReturnType!func;
        static if (is(RType == void))
        {
            return;
        }
        else
        {
            return cast(RType)(getReturn!RType);
        }
    }

    static void writeReturn(alias func)(ReturnType!func ret)
    {
        alias RType = ReturnType!func;
        getReturn!RType = ret;
    }

    static auto wrappedFuncCall(alias func, Arg...)(auto ref Arg args)
    {
        // sorry Robert
        auto wrapFunc = () {
            static if (is(ReturnType!func == void))
            {
                func(args);
            }
            else
            {
                auto ret = func(args);
                writeReturn!func(ret);
            }
        };
        return wrapFunc;
    }

    static Fiber toFibre(alias func, Arg...)(auto ref Arg args)
    {
        return new Fiber(wrappedFuncCall!func(args));
    }

    public static auto call(alias func, Arg...)(auto ref Arg args)
    {
        d_callStack.assumeSafeAppend ~= toFibre!func(args);
        Fiber.yield();
        return readReturn!func;
    }

    public static auto run(alias func, Arg...)(auto ref Arg args)
    {
        import std.range : back, empty, popBack;

        d_callStack.assumeSafeAppend ~= toFibre!func(args);
        while (!d_callStack.empty)
        {
            auto fib = d_callStack.back;
            if (fib.state == Fiber.State.TERM)
            {
                d_callStack.popBack;
                continue;
            }
            fib.call(); // <- this should have error handling
        }
        return readReturn!func;
    }

    static Fiber[] d_callStack;
}

alias CallUtil = FiberCallUtil;

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