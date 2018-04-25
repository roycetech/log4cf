/**
 * @hint Tests for TODO
 * @CFLintIgnore ARGUMENT_TOO_LONG,EXCESSIVE_FUNCTIONS,COMPONENT_TOO_LONG,COMPONENT_INVALID_NAME,AVOID_USING_CREATEOBJECT,VAR_INVALID_NAME,METHOD_INVALID_NAME,METHOD_TOO_LONG,METHOD_TOO_WORDY,VAR_TOO_WORDY,VAR_TOO_LONG,VAR_TOO_SHORT,VAR_IS_TEMPORARY,METHOD_IS_TEMPORARY,ARGUMENT_TOO_WORDY
 */
component LoggerTest extends=mxunit.framework.TestCase {

    /**
     * @hint Runs once before executing the tests.
     */
    Void function beforeTests()
    {
        variables.subject = new log4cf.Logger();
    }

    /**
     * @hint Executes once before each test case is run.
     */
    Void function setUp()
    {
    }

    /**
     * @hint
     */
    void function nvl_given_empty_should_return_default()
    {
        makePublic(variables.subject, "nvl");
        var actual = variables.subject.nvl("", "default");
        debug(actual);
        assertEquals(
            expected = "default",
            actual   = actual
        );
    }

    /**
     * @hint
     */
    void function nvl_given_value_should_return_the_value()
    {
        makePublic(variables.subject, "nvl");
        var actual = variables.subject.nvl("value", "default");
        debug(actual);
        assertEquals(
            expected = "value",
            actual   = actual
        );
    }
}