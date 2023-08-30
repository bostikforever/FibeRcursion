import std;
import core.thread : Fiber;

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

    static auto wrappedFuncCall(alias func, Arg...)(Arg args)
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

    static Fiber toFibre(alias func, Arg...)(Arg args)
    {
        return new Fiber(wrappedFuncCall!func(args));
    }

    public static auto call(alias func, Arg...)(Arg args)
    {
        d_callStack.assumeSafeAppend ~= toFibre!func(args);
        Fiber.yield();
        return readReturn!func;
    }

    public static auto run(alias func, Arg...)(auto ref Arg args)
    {
        import std.range : empty, popBack;

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

class PlainCallUtil
{
    static auto call(alias func, Args...)(auto ref Args args)
    {
        writeln("plain call");
        return func(args);
    }

    static auto run(alias func, Args...)(auto ref Args args)
    {
        writeln("plain run");
        return func(args);
    }
}

// alias CallUtil = PlainCallUtil;
alias CallUtil = FiberCallUtil;

void recurForEach(int i)
{
    writeln(i);
    if (i <= 1)
    {
        return;
    }
    return CallUtil.call!recurForEach(i - 1);
}

auto returnConst(Arg)(Arg arg)
{
    return arg;
}

void doSomething()
{
    foreach (j; 1 .. 10)
    {
        writeln("Hello World: ", j);
        auto ret = CallUtil.call!(returnConst!int)(42);
        writeln("Hello ret: ", ret);
        auto ret2 = CallUtil.call!(returnConst!string)("Hello");
        writeln("Hello ret2: ", ret2);
    }
    recurForEach(10);
}

void main()
{
    CallUtil.run!doSomething();
}
