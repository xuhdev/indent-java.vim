@Annotation
@ComplexAnnotation(something, somethingElse)
class MyClass
    implements interfaceX,
               interfaceY,
               interfaceZ
    extends Y,
            Z {

    /* Block comment start
     * Some content
     */
    @ComplexAnnotation(something, somethingElse)
    @AnotherAnnotation
    public int test(
            int a,
            int b
    )
        throws AnException,
               AnotherException,
               YetAnother
    {
        // Single line comment
        doSomething();
    }

    public void someOtherMethod()
        throws X
    {
    }
}
