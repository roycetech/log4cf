<cfapplication>

<cfscript>
    logger = new log4cf.Logger();
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

    new log4cf.example.logging_on.sub1.Example4();
    new log4cf.example.logging_on.sub2.Example5();

    try {
        x = 1 / 0;
    } catch (any e) {
        logger.error('oh no!', e, 'potato');
    }

    // writeDump(cgi);
</cfscript>
