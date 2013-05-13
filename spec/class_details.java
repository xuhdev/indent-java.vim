class Test1
    extends Parent {
}

class Test2
    implements Interface {
}

class Test3
    extends Parent
    implements Interface {
}

class Test4
    extends Parent1,
            Parent2
    implements Interface1,
               Interface2,
               Interface3 {
    private int member1;
}
