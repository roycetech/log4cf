<cfscript>
    logger = new log4cf.Log4Cf();
    logger.debug("Debugging text");
    logger.info("Information text");
    logger.warn("Warning text");
    logger.error("Error text");

    function test() {
        logger.debug("Debugging text");
        logger.info("Information text");
        logger.warn("Warning text");
        logger.error("Error text");
    }

    test();

    new log4cf.example.logging_off.Example1();
    new log4cf.example.logging_on.Example1();
    new log4cf.example.logging_on.Example2();
    new log4cf.example.logging_on.Example3();
</cfscript>
