
@IsTest
private class HelloWorldTest {
    @IsTest
    static void testGreet() {
        Test.startTest();
        String result = HelloWorld.greet();
        Test.stopTest();

        System.assertEquals(
            'Hello Everyone and bye',
            result
        );
    }
}
